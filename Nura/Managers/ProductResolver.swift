import Foundation

struct ResolvedProduct: Codable {
    let barcode: String
    let name: String
    let brand: String?
    let imageURL: String?
    let ingredients: [String]?
    let retailerURL: String?
}

final class BarcodeCacheManager {
    static let shared = BarcodeCacheManager()
    private let key = "nura.barcode.cache.v1"
    private struct CacheEntry: Codable { let product: ResolvedProduct; let date: Date }
    private var cache: [String: CacheEntry] = [:]
    private let ttl: TimeInterval = 30 * 24 * 3600

    private init() { load() }

    func get(_ barcode: String) -> ResolvedProduct? {
        if let entry = cache[barcode], Date().timeIntervalSince(entry.date) < ttl { return entry.product }
        return nil
    }
    func set(_ product: ResolvedProduct) {
        cache[product.barcode] = CacheEntry(product: product, date: Date())
        persist()
    }
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        if let decoded = try? JSONDecoder().decode([String: CacheEntry].self, from: data) {
            cache = decoded
        }
    }
    private func persist() {
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

final class ProductResolver {
    static let shared = ProductResolver()

    func resolve(barcode: String) async -> ResolvedProduct? {
        let normalized = Self.normalize(barcode: barcode)
        print("🔍 [ProductResolver] resolve called with=\(barcode) normalized=\(normalized)")
        if let cached = BarcodeCacheManager.shared.get(normalized) {
            print("📦 [ProductResolver] Cache hit for \(barcode)")
            return cached
        }
        if let sb = await SupabaseProductCacheManager.shared.fetch(barcodeNorm: normalized) {
            print("📦 [ProductResolver] Supabase cache hit for \(normalized)")
            BarcodeCacheManager.shared.set(sb)
            return sb
        }

        if let hit = await fetchAnyParallel(barcode: normalized) {
            BarcodeCacheManager.shared.set(hit)
            await SupabaseProductCacheManager.shared.upsert(resolved: hit, source: .other)
            return hit
        }

        print("⚠️ [ProductResolver] Not found remotely; returning minimal stub")
        return ResolvedProduct(barcode: normalized, name: "Unknown product", brand: nil, imageURL: nil, ingredients: nil, retailerURL: nil)
    }

    private func fetchOpenBeautyFacts(barcode: String) async -> ResolvedProduct? {
        guard let url = URL(string: "https://world.openbeautyfacts.org/api/v2/product/\(barcode).json") else { return nil }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard (json?["status"] as? Int) != 0, let product = json?["product"] as? [String: Any] else {
                print("ℹ️ [ProductResolver] OB Facts: status=0 or no product for barcode=\(barcode)")
                return nil
            }
            let nameFields = ["product_name", "product_name_en", "generic_name", "generic_name_en"]
            let name = nameFields.compactMap { (product[$0] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty }
            let brandStr = (product["brands"] as? String)?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines)
            let brandTags = (product["brands_tags"] as? [String])?.first?.trimmingCharacters(in: .whitespacesAndNewlines)
            let brand = [brandStr, brandTags].compactMap { $0 }.first { !$0.isEmpty }
            let imageURL = (product["image_url"] as? String) ?? (product["image_small_url"] as? String) ?? (product["image_front_small_url"] as? String)
            let ingredientsTags = (product["ingredients_text_en"] as? String) ?? (product["ingredients_text"] as? String)
            let ingredients = ingredientsTags?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            let retailer = product["stores_tags"] as? [String]
            let finalName = (name ?? "").isEmpty ? "Unknown product" : (name ?? "")
            return ResolvedProduct(barcode: barcode, name: finalName, brand: brand, imageURL: imageURL, ingredients: ingredients, retailerURL: retailer?.first)
        } catch {
            print("❌ [ProductResolver] OB Facts fetch failed: \(error)")
            return nil
        }
    }

    private func fetchOpenProductFacts(barcode: String) async -> ResolvedProduct? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json") else { return nil }
        do {
            let (data, resp) = try await URLSession.shared.data(from: url)
            guard (resp as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard (json?["status"] as? Int) != 0, let product = json?["product"] as? [String: Any] else { return nil }
            let nameFields = ["product_name", "product_name_en", "generic_name", "generic_name_en"]
            let name = nameFields.compactMap { (product[$0] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }.first { !$0.isEmpty }
            let brandStr = (product["brands"] as? String)?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines)
            let brandTags = (product["brands_tags"] as? [String])?.first?.trimmingCharacters(in: .whitespacesAndNewlines)
            let brand = [brandStr, brandTags].compactMap { $0 }.first { !$0.isEmpty }
            let imageURL = (product["image_url"] as? String) ?? (product["image_small_url"] as? String)
            let finalName = (name ?? "").isEmpty ? "Unknown product" : (name ?? "")
            return ResolvedProduct(barcode: barcode, name: finalName, brand: brand, imageURL: imageURL, ingredients: nil, retailerURL: nil)
        } catch { return nil }
    }

    private func fetchViaGoogleCSE(barcode: String) async -> ResolvedProduct? {
        guard let apiKey = GoogleAPIConfig.apiKey, let cx = GoogleAPIConfig.searchEngineId else { return nil }
        var components = URLComponents(string: "https://www.googleapis.com/customsearch/v1")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "cx", value: cx),
            URLQueryItem(name: "q", value: barcode),
            URLQueryItem(name: "num", value: "3"),
            URLQueryItem(name: "safe", value: "active")
        ]
        var req = URLRequest(url: components.url!)
        req.timeoutInterval = 4
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            struct R: Decodable { struct Item: Decodable { let title: String; let link: String? } ; let items: [Item]? }
            let decoded = try? JSONDecoder().decode(R.self, from: data)
            guard let item = decoded?.items?.first else { return nil }
            let cleaned = item.title
                .replacingOccurrences(of: "|", with: " ")
                .replacingOccurrences(of: "-", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return ResolvedProduct(barcode: barcode, name: cleaned, brand: nil, imageURL: nil, ingredients: nil, retailerURL: item.link)
        } catch { return nil }
    }

    // Retailer-focused Google query for higher precision
    private func fetchViaRetailerGoogleSearch(barcode: String) async -> ResolvedProduct? {
        guard let apiKey = GoogleAPIConfig.apiKey, let cx = GoogleAPIConfig.searchEngineId else { return nil }
        let retailers = [
            // US
            "amazon.com","target.com","walmart.com","cvs.com","walgreens.com",
            "sephora.com","ulta.com","dermstore.com","skinstore.com",
            // CA
            "amazon.ca","walmart.ca","shoppersdrugmart.ca","well.ca","londondrugs.com",
            // UK
            "amazon.co.uk","boots.com","superdrug.com","lookfantastic.com","cultbeauty.co.uk","spacenk.com"
        ]
        for domain in retailers {
            var components = URLComponents(string: "https://www.googleapis.com/customsearch/v1")!
            let q = "\(barcode) site:\(domain)"
            components.queryItems = [
                URLQueryItem(name: "key", value: apiKey),
                URLQueryItem(name: "cx", value: cx),
                URLQueryItem(name: "q", value: q),
                URLQueryItem(name: "num", value: "2"),
                URLQueryItem(name: "safe", value: "active")
            ]
            var req = URLRequest(url: components.url!)
            req.timeoutInterval = 4
            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { continue }
                struct R: Decodable { struct Item: Decodable { let title: String; let link: String? } ; let items: [Item]? }
                let decoded = try? JSONDecoder().decode(R.self, from: data)
                if let item = decoded?.items?.first {
                    let cleaned = item.title
                        .replacingOccurrences(of: "|", with: " ")
                        .replacingOccurrences(of: "-", with: " ")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    let brand = inferBrand(fromTitle: cleaned)
                    return ResolvedProduct(barcode: barcode, name: cleaned, brand: brand, imageURL: nil, ingredients: nil, retailerURL: item.link)
                }
            } catch { continue }
        }
        return nil
    }

    private func inferBrand(fromTitle title: String) -> String? {
        let words = title.split(separator: " ")
        // Heuristic: brand is the first capitalized token that is not size/shade
        for w in words.prefix(3) {
            let s = String(w)
            if s.count >= 2 && s.first!.isUppercase && !s.lowercased().contains("oz") && !s.lowercased().contains("fl") {
                return s
            }
        }
        return nil
    }

    private func fetchDatakick(barcode: String) async -> ResolvedProduct? {
        // Datakick uses UPC without leading 0 for UPC-A; try both forms
        let variants = Set([barcode, String(barcode.drop(while: { $0 == "0" }))])
        for code in variants {
            guard let url = URL(string: "https://www.datakick.org/api/items/\(code)") else { continue }
            var req = URLRequest(url: url); req.timeoutInterval = 3
            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { continue }
                if let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let name = (obj["name"] as? String) ?? ""
                    let brand = obj["brand_name"] as? String
                    let image = obj["image_url"] as? String
                    if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        return ResolvedProduct(barcode: barcode, name: name, brand: brand, imageURL: image, ingredients: nil, retailerURL: nil)
                    }
                }
            } catch { continue }
        }
        return nil
    }

    private func fetchOpenGTINDB(barcode: String) async -> ResolvedProduct? {
        // Public demo queryid; replace with your own if needed
        guard let url = URL(string: "https://opengtindb.org/?ean=\(barcode)&cmd=query&queryid=400000000") else { return nil }
        var req = URLRequest(url: url); req.timeoutInterval = 3
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            if let text = String(data: data, encoding: .utf8) {
                // Response is key=value lines; product name often in "name" or "descr"
                var fields: [String: String] = [:]
                for line in text.split(separator: "\n") {
                    let parts = line.split(separator: "=", maxSplits: 1).map(String.init)
                    if parts.count == 2 { fields[parts[0].lowercased()] = parts[1].trimmingCharacters(in: .whitespacesAndNewlines) }
                }
                let name = fields["name"] ?? fields["descr"] ?? fields["description"] ?? ""
                let brand = fields["brand"] ?? fields["company"]
                if !name.isEmpty {
                    return ResolvedProduct(barcode: barcode, name: name, brand: brand, imageURL: nil, ingredients: nil, retailerURL: nil)
                }
            }
        } catch { return nil }
        return nil
    }

    private func fetchAnyParallel(barcode: String) async -> ResolvedProduct? {
        return await withTaskGroup(of: ResolvedProduct?.self) { group in
            group.addTask { await self.fetchOpenBeautyFacts(barcode: barcode) }
            group.addTask { await self.fetchOpenProductFacts(barcode: barcode) }
            group.addTask { await self.fetchDatakick(barcode: barcode) }
            group.addTask { await self.fetchOpenGTINDB(barcode: barcode) }
            group.addTask { await self.fetchViaRetailerGoogleSearch(barcode: barcode) }
            group.addTask { await self.fetchViaGoogleCSE(barcode: barcode) }
            var first: ResolvedProduct? = nil
            while let res = await group.next() {
                if let r = res, !r.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, r.name.lowercased() != "unknown product" {
                    first = r
                    group.cancelAll()
                    break
                }
            }
            return first
        }
    }

    // Normalize to EAN-13 when possible (prefix 0 for UPC-A), strip non-digits, trim GTIN-14 leading 0
    private static func normalize(barcode: String) -> String {
        let digits = barcode.filter { $0.isNumber }
        if digits.count == 12 { return "0" + digits } // UPC-A -> EAN-13
        if digits.count == 14, digits.first == "0" { return String(digits.dropFirst()) }
        return digits
    }
}


