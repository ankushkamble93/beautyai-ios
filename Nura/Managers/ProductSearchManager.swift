import Foundation
import UIKit

final class ProductSearchManager {
    static let shared = ProductSearchManager()
    private init() {}
    
    // Simple in-memory cache for search results to reduce API calls
    private var recentQueryToResults: [String: [ProductSearchResult]] = [:]
    private var googleBlocked: Bool = false
    // Enhanced SkincareAPI caching: separate cache with longer TTL since it's free
    private var skincareAPICache: [String: (results: [ProductSearchResult], timestamp: Date)] = [:]
    private let skincareAPICacheTTL: TimeInterval = 24 * 60 * 60 // 24 hours
    
    // MARK: - Public API
    
    struct ProductQuery {
        let rawText: String
        let normalizedQuery: String
        let categoryHint: String?
    }
    
    func detectProductQuery(_ text: String) -> ProductQuery? {
        let lower = text.lowercased()
        let intentKeywords = ["recommend", "suggest", "best", "good", "options", "product", "buy", "brand"]
        let hasIntent = intentKeywords.contains { lower.contains($0) }
        let categories = [
            "cleanser", "toner", "serum", "retinol", "retinoid", "vitamin c", "vitamin-c", "moisturizer", "moisturiser", "sunscreen", "spf", "mask", "exfoliant", "salicylic", "niacinamide", "hyaluronic"
        ]
        let category = categories.first { lower.contains($0) }
        guard hasIntent || category != nil else { return nil }
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return ProductQuery(rawText: text, normalizedQuery: normalized, categoryHint: category)
    }
    
    func searchProducts(query: ProductQuery) async -> [ProductSearchResult] {
        if let cached = recentQueryToResults[query.normalizedQuery] {
            print("🗂️ ProductSearch: cache hit for=\(query.normalizedQuery) results=\(cached.count)")
            return cached
        }
        // Check SkincareAPI cache first (longer TTL, free API)
        if let cached = getSkincareAPICache(for: query.normalizedQuery) {
            print("🗂️ ProductSearch: SkincareAPI cache hit for query=\(query.normalizedQuery) results=\(cached.count)")
            return cached
        }
        // First try SkincareAPI (public dataset) for a quick, cheap hit
        if let fromSkincareAPI = try? await skincareAPISearch(query: query.normalizedQuery), !fromSkincareAPI.isEmpty {
            let deduped = Self.deduplicate(fromSkincareAPI)
            // Cache SkincareAPI results separately with longer TTL
            setSkincareAPICache(for: query.normalizedQuery, results: deduped)
            recentQueryToResults[query.normalizedQuery] = deduped
            return deduped
        }
        if googleBlocked {
            print("🛑 ProductSearch: Google CSE blocked this session; using local fallback for=\(query.normalizedQuery)")
            let local = localResults(for: query)
            recentQueryToResults[query.normalizedQuery] = local
            return local
        }
        // Primary: Google Custom Search API
        if let results = try? await googleCustomSearch(query: query.normalizedQuery, category: query.categoryHint) {
            print("✅ ProductSearch: Google CSE returned \(results.count) results for=\(query.normalizedQuery)")
            let deduped = Self.deduplicate(results)
            recentQueryToResults[query.normalizedQuery] = deduped
            return deduped
        }
        // Fallback: Local DB
        let local = localResults(for: query)
        print("🟡 ProductSearch: using local fallback results=\(local.count) for=\(query.normalizedQuery)")
        recentQueryToResults[query.normalizedQuery] = local
        return local
    }
    
    // Extract explicit product names from AI text (simple heuristic over common brand list and bolded items)
    func extractProductNames(from text: String) -> [String] {
        let brands = ["cerave", "la roche-posay", "supergoop", "the ordinary", "paula's choice", "neutrogena", "eucerin", "tatcha", "drunk elephant", "cosrx", "bioderma", "vichy", "olay", "avene", "laroche", "laroche-posay"]
        let lower = text.lowercased()
        var names: [String] = []
        for b in brands {
            if let range = lower.range(of: b) {
                // take up to ~6 words after brand
                let tail = lower[range.lowerBound...]
                let words = tail.split(separator: " ")
                let slice = words.prefix(6).joined(separator: " ")
                // clean punctuation and newlines
                let cleaned = slice.replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: ":", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.count > b.count + 2 { names.append(cleaned) }
            }
        }
        // Also capture any **bold** fragments as potential product mentions
        let pattern = #"\*\*([^*]{3,60})\*\*"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let ns = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
            let ignore = Set(["morning routine", "evening routine", "weekly treatments", "analysis notes", "lifestyle tips", "concerns", "routine"])
            for m in matches {
                if m.numberOfRanges > 1 {
                    let raw = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                    let lc = raw.lowercased()
                    if raw.count >= 3 && !ignore.contains(lc) { names.append(raw) }
                }
            }
        }
        // Deduplicate and cap
        var seen: Set<String> = []
        return names.filter { seen.insert($0.lowercased()).inserted }.prefix(5).map { String($0) }
    }
    
    // Fetch best image/title for each explicit product name
    func searchProducts(forNames names: [String]) async -> [ProductSearchResult] {
        func sanitize(_ s: String) -> [String] {
            let base = s
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "—", with: " ")
                .replacingOccurrences(of: "-", with: " ")
                .replacingOccurrences(of: ":", with: " ")
                .replacingOccurrences(of: "  ", with: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            // Split on natural language connectors like " or ", " and "
            let lowered = base.lowercased()
            let parts = lowered
                .replacingOccurrences(of: " and ", with: "|")
                .replacingOccurrences(of: " or ", with: "|")
                .components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return parts.isEmpty ? [base] : parts
        }
        var results: [ProductSearchResult] = []
        for raw in names {
            for name in sanitize(raw) {
                print("🔎 ProductSearch: exact lookup for name=\(name)")
            let canonical = await resolveCanonicalFromSkincareAPI(name) ?? name
            if googleBlocked {
                // Produce placeholder card aligned with AI text
                results.append(ProductSearchResult(name: canonical, brand: nil, priceText: nil, benefits: [], imageURL: nil, destinationURL: nil))
                continue
            }
            if let single = try? await googleCustomSearchExact(name: canonical) {
                results.append(single)
                continue
            }
            // Fallback to broader image search and take the first
            if !googleBlocked, let broader = try? await googleCustomSearch(query: canonical, category: nil), let first = broader.first {
                print("🟡 ProductSearch: using fallback result for name=\(canonical)")
                results.append(first)
                continue
            }
            print("⚠️ ProductSearch: no result for explicit name=\(name)")
            // As last resort, attach a placeholder so UI still aligns with AI mention
            results.append(ProductSearchResult(name: canonical, brand: nil, priceText: nil, benefits: [], imageURL: nil, destinationURL: nil))
            }
        }
        return Self.deduplicate(results)
    }
    
    // MARK: - Google Custom Search (Primary)
    
    private func googleCustomSearch(query: String, category: String?) async throws -> [ProductSearchResult] {
        guard let apiKey = GoogleAPIConfig.apiKey, let cx = GoogleAPIConfig.searchEngineId else {
            print("❌ ProductSearch: Missing GoogleAPIConfig.apiKey or searchEngineId")
            throw NSError(domain: "ProductSearch", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google API not configured"])
        }
        let q = (category != nil) ? "\(query) \(category!) skincare" : query
        // Use image search to retrieve high quality thumbnails; we still read title/snippet
        var components = URLComponents(string: "https://www.googleapis.com/customsearch/v1")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "cx", value: cx),
            URLQueryItem(name: "q", value: q),
            URLQueryItem(name: "searchType", value: "image"),
            URLQueryItem(name: "num", value: "6"),
            URLQueryItem(name: "imgSize", value: "large"),
            // Note: imgType=product is not supported in current API; removing to avoid 400
            URLQueryItem(name: "safe", value: "active")
        ]
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            print("❌ ProductSearch: Non-HTTP response")
            throw NSError(domain: "ProductSearch", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("❌ ProductSearch: HTTP \(http.statusCode) body=\(body.prefix(200))")
            if http.statusCode == 403 { googleBlocked = true }
            throw NSError(domain: "ProductSearch", code: -2, userInfo: [NSLocalizedDescriptionKey: "Google API error"])
        }
        let decoded = try JSONDecoder().decode(GCSearchResponse.self, from: data)
        var aggregated: [ProductSearchResult] = []
        if let items = decoded.items {
            for item in items.prefix(12) {
                let cleaned = cleanProductTitle(item.title)
                let title = (try? await resolveCanonicalFromSkincareAPI(cleaned)) ?? cleaned
                let brand = inferBrand(from: title)
                let benefits = inferBenefits(from: title)
                let dest = item.image?.contextLink
                let aff = Self.buildAffiliateLink(from: dest)
                let thumbCandidate = item.image?.thumbnailLink ?? item.link
                if thumbCandidate.isEmpty { continue }
                let thumb = thumbCandidate
                let derivedIngs = Self.deriveIngredients(fromTitle: title)
                let derivedType = Self.classifyType(from: title)
                let product = ProductSearchResult(
                    name: title,
                    brand: brand,
                    priceText: nil,
                    benefits: benefits,
                    imageURL: thumb,
                    destinationURL: aff?.absoluteString ?? dest,
                    ingredients: derivedIngs,
                    productType: derivedType
                )
                aggregated.append(product)
            }
        }
        return Self.deduplicate(aggregated)
    }

    // MARK: - SkincareAPI (Secondary, Free Dataset)
    private func skincareAPISearch(query: String) async throws -> [ProductSearchResult] {
        guard let encoded = ("https://skincare-api.herokuapp.com/product?q=" + query).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: encoded) else { 
            print("⚠️ ProductSearch: Failed to encode SkincareAPI query=\(query)")
            return [] 
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { 
            print("⚠️ ProductSearch: SkincareAPI HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)) for query=\(query)")
            return [] 
        }
        
        // Enhanced response parsing with ingredients
        struct APIItem: Decodable { 
            let brand: String?; 
            let name: String?; 
            let ingredient_list: [String]? 
        }
        
        let decoded = try? JSONDecoder().decode([APIItem].self, from: data)
        var mapped: [ProductSearchResult] = []
        
        for item in (decoded ?? []) {
            guard let name = item.name, !name.isEmpty else { continue }
            let initial = cleanProductTitle([item.brand, name].compactMap { $0 }.joined(separator: " "))
            let title = await resolveCanonicalFromSkincareAPI(initial) ?? initial
            
            // Parse ingredients for benefits (UX: users see relevant benefits immediately)
            let ingredientList = (item.ingredient_list ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let benefits = parseBenefitsFromIngredients(ingredientList)
            
            // Try to get an image for this product (UX: visual appeal)
            let imageURL = await getProductImage(for: title)
            
            let product = ProductSearchResult(
                name: title, 
                brand: item.brand, 
                priceText: nil, 
                benefits: benefits, 
                imageURL: imageURL, 
                destinationURL: nil,
                ingredients: ingredientList,
                productType: Self.classifyType(from: title)
            )
            mapped.append(product)
        }
        
        print("✅ ProductSearch: SkincareAPI returned \(mapped.count) results for query=\(query)")
        return mapped
    }

    // Query for a single product name, prefer thumbnail link for reliability
    private func googleCustomSearchExact(name: String) async throws -> ProductSearchResult? {
        guard let apiKey = GoogleAPIConfig.apiKey, let cx = GoogleAPIConfig.searchEngineId else { 
            print("❌ ProductSearch: Missing API key or cx for exact name search")
            return nil 
        }
        var components = URLComponents(string: "https://www.googleapis.com/customsearch/v1")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "cx", value: cx),
            URLQueryItem(name: "q", value: name + " product"),
            URLQueryItem(name: "searchType", value: "image"),
            URLQueryItem(name: "num", value: "1"),
            URLQueryItem(name: "imgSize", value: "medium"),
            // Note: imgType=product is not supported in current API; removing to avoid 400
            URLQueryItem(name: "safe", value: "active")
        ]
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { 
            print("❌ ProductSearch: exact search non-HTTP response for name=\(name)")
            return nil 
        }
        guard http.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            print("❌ ProductSearch: exact search HTTP \(http.statusCode) for name=\(name) body=\(body.prefix(160))")
            if http.statusCode == 403 { googleBlocked = true }
            return nil
        }
        let decoded = try JSONDecoder().decode(GCSearchResponse.self, from: data)
        guard let item = decoded.items?.first else { return nil }
        let cleaned = cleanProductTitle(item.title)
        let displayTitle = (try? await resolveCanonicalFromSkincareAPI(cleaned)) ?? cleaned
        let brand = inferBrand(from: displayTitle)
        let benefits = inferBenefits(from: displayTitle)
        let dest = item.image?.contextLink
        let aff = Self.buildAffiliateLink(from: dest)
        let thumb = item.image?.thumbnailLink ?? item.link
        return ProductSearchResult(name: displayTitle, brand: brand, priceText: nil, benefits: benefits, imageURL: thumb, destinationURL: aff?.absoluteString ?? dest)
    }
    
    // MARK: - Helpers
    
    private func localResults(for query: ProductQuery) -> [ProductSearchResult] {
        // Minimal curated fallback set
        let db: [ProductSearchResult] = [
            ProductSearchResult(name: "CeraVe Hydrating Cleanser", brand: "CeraVe", priceText: "$10-$15", benefits: ["gentle", "non-stripping"], imageURL: nil, destinationURL: nil),
            ProductSearchResult(name: "La Roche-Posay Toleriane Moisturizer", brand: "La Roche-Posay", priceText: "$20-$30", benefits: ["ceramides", "soothing"], imageURL: nil, destinationURL: nil),
            ProductSearchResult(name: "Supergoop! Unseen Sunscreen SPF 40", brand: "Supergoop!", priceText: "$30-$40", benefits: ["invisible", "broad-spectrum"], imageURL: nil, destinationURL: nil)
        ]
        if let hint = query.categoryHint {
            return db.filter { $0.name.lowercased().contains(hint) }
        }
        return db
    }
    
    private func inferBrand(from title: String) -> String? {
        let parts = title.split(separator: " ")
        return parts.first.map { String($0) }
    }
    
    private func inferBenefits(from title: String) -> [String] {
        let lower = title.lowercased()
        var benefits: [String] = []
        if lower.contains("spf") { benefits.append("SPF") }
        if lower.contains("retinol") || lower.contains("retinoid") { benefits.append("retinoid") }
        if lower.contains("vitamin c") || lower.contains(" vit c") || lower.contains("vit-c") || lower.contains("ascorb") || lower.contains(" c+") { benefits.append("vitamin c") }
        if lower.contains("hyaluronic") { benefits.append("hydrating") }
        return benefits
    }
    
    // Normalize/noise-trim product titles coming from search results or AI context
    private func cleanProductTitle(_ raw: String) -> String {
        var s = raw
        // Cut off common separators with site or extra descriptors
        let seps = [" | ", " - ", " — ", " – "]
        for sep in seps { if let r = s.range(of: sep) { s = String(s[..<r.lowerBound]) } }
        // Remove filler phrases
        let fillers = [
            "are good options", "are great options", "are great choices", "good options",
            "great choice", "great choices", "recommended", "recommendation"
        ]
        for f in fillers { s = s.replacingOccurrences(of: f, with: "", options: [.caseInsensitive]) }
        // Strip common domains/labels and stray punctuation
        s = s.replacingOccurrences(of: "Amazon.com", with: "", options: [.caseInsensitive])
        s = s.replacingOccurrences(of: "Amazon", with: "", options: [.caseInsensitive])
        s = s.replacingOccurrences(of: ",", with: " ")
        while s.contains("  ") { s = s.replacingOccurrences(of: "  ", with: " ") }
        s = s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
        return s.isEmpty ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : s
    }
    
    // Try canonicalizing a noisy title using SkincareAPI; returns combined brand+name if available
    private func resolveCanonicalFromSkincareAPI(_ noisyTitle: String) async -> String? {
        let q = noisyTitle
        guard let encoded = ("https://skincare-api.herokuapp.com/product?q=" + q).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encoded) else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let decoded = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              let first = decoded.first else { return nil }
        let brand = (first["brand"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = (first["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let name = name, !name.isEmpty {
            return [brand, name].compactMap { $0 }.joined(separator: " ")
        }
        return nil
    }
    
    // Deduplicate by normalized name and destination URL
    private static func deduplicate(_ items: [ProductSearchResult]) -> [ProductSearchResult] {
        var seen: Set<String> = []
        func key(_ r: ProductSearchResult) -> String {
            let normalizedName = r.name
                .lowercased()
                .replacingOccurrences(of: "  ", with: " ")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let d = (r.destinationURL ?? "").lowercased()
            return normalizedName + "|" + d
        }
        var out: [ProductSearchResult] = []
        for i in items {
            let k = key(i)
            if seen.insert(k).inserted {
                out.append(i)
            }
        }
        return out
    }

    // Derive ingredient keywords from noisy titles when the dataset didn't include ingredients
    private static func deriveIngredients(fromTitle title: String) -> [String] {
        let t = title.lowercased()
        let mapping: [(key: String, display: String)] = [
            ("hyaluronic", "Hyaluronic Acid"),
            ("niacinamide", "Niacinamide"),
            ("retinol", "Retinol"),
            ("retinoid", "Retinoid"),
            ("ascorb", "Vitamin C"),
            ("vitamin c", "Vitamin C"),
            (" c+", "Vitamin C"),
            ("salicylic", "Salicylic Acid"),
            ("glycolic", "Glycolic Acid"),
            ("lactic", "Lactic Acid"),
            ("ceramide", "Ceramides"),
            ("zinc", "Zinc"),
            ("azelaic", "Azelaic Acid"),
            ("spf", "SPF")
        ]
        var seen: Set<String> = []
        var out: [String] = []
        for m in mapping where t.contains(m.key) {
            if seen.insert(m.display).inserted { out.append(m.display) }
        }
        return out
    }

    // Lightweight product type classifier using keywords
    private static func classifyType(from title: String) -> String? {
        let t = title.lowercased()
        let mapping: [(String, String)] = [
            ("cleanser", "cleanser"), ("wash", "cleanser"), ("gel", "cleanser"), ("foam", "cleanser"), ("balm", "cleanser"),
            ("toner", "toner"), ("essence", "toner"),
            ("serum", "serum"), ("vitamin c", "serum"), ("ascorb", "serum"),
            ("moistur", "moisturizer"), ("cream", "moisturizer"), ("lotion", "moisturizer"),
            ("spf", "sunscreen"), ("sunscreen", "sunscreen"), ("sun screen", "sunscreen"), ("uv", "sunscreen"),
            ("mask", "mask"), ("peel", "treatment"), ("retinol", "treatment"), ("retinoid", "treatment"), ("exfol", "exfoliant")
        ]
        for (k, v) in mapping { if t.contains(k) { return v } }
        return nil
    }
    
    // Affiliate: append basic tracking; direct brand mappings can be added here
    static func buildAffiliateLink(from urlString: String?) -> URL? {
        guard let urlString, var components = URLComponents(string: urlString) else { return nil }
        var items = components.queryItems ?? []
        items.append(URLQueryItem(name: "utm_source", value: "nura"))
        items.append(URLQueryItem(name: "utm_medium", value: "affiliate"))
        components.queryItems = items
        return components.url
    }
    
    // UX: Parse ingredients to show relevant benefits immediately
    private func parseBenefitsFromIngredients(_ ingredients: [String]) -> [String] {
        let lowerIngredients = ingredients.map { $0.lowercased() }
        var benefits: [String] = []
        
        // Common skincare benefits from ingredients
        if lowerIngredients.contains(where: { $0.contains("hyaluronic") || $0.contains("hyaluronate") }) {
            benefits.append("Hydrating")
        }
        if lowerIngredients.contains(where: { $0.contains("retinol") || $0.contains("retinoid") || $0.contains("tretinoin") }) {
            benefits.append("Anti-aging")
        }
        if lowerIngredients.contains(where: { $0.contains("vitamin c") || $0.contains("ascorbic") || $0.contains("l-ascorbic") }) {
            benefits.append("Brightening")
        }
        if lowerIngredients.contains(where: { $0.contains("niacinamide") || $0.contains("vitamin b3") }) {
            benefits.append("Pore refining")
        }
        if lowerIngredients.contains(where: { $0.contains("salicylic") || $0.contains("bha") }) {
            benefits.append("Exfoliating")
        }
        if lowerIngredients.contains(where: { $0.contains("glycolic") || $0.contains("aha") || $0.contains("lactic") }) {
            benefits.append("Gentle exfoliation")
        }
        if lowerIngredients.contains(where: { $0.contains("ceramide") || $0.contains("ceramides") }) {
            benefits.append("Barrier repair")
        }
        if lowerIngredients.contains(where: { $0.contains("peptide") || $0.contains("peptides") }) {
            benefits.append("Firming")
        }
        if lowerIngredients.contains(where: { $0.contains("spf") || $0.contains("zinc oxide") || $0.contains("titanium dioxide") }) {
            benefits.append("Sun protection")
        }
        
        return benefits.isEmpty ? ["Skincare"] : benefits
    }
    
    // UX: Get product images to make results more appealing
    private func getProductImage(for productName: String) async -> String? {
        // Prefer Google CSE image search for consistency
        if let google = try? await googleCustomSearch(query: productName, category: nil), 
           let first = google.first?.imageURL, 
           !first.isEmpty {
            return first
        }
        // Fallback: Unsplash featured search (requires key; optional)
        let searchQuery = productName.replacingOccurrences(of: " ", with: "+")
        if let url = URL(string: "https://api.unsplash.com/search/photos?query=\(searchQuery)+skincare&per_page=1") {
            var request = URLRequest(url: url)
            request.setValue("Client-ID YOUR_UNSPLASH_KEY", forHTTPHeaderField: "Authorization")
            if let (data, response) = try? await URLSession.shared.data(for: request), 
               let http = response as? HTTPURLResponse, 
               http.statusCode == 200 {
                struct UnsplashResponse: Decodable { let results: [UnsplashResult]? }
                struct UnsplashResult: Decodable { let urls: UnsplashURLs? }
                struct UnsplashURLs: Decodable { let small: String? }
                if let decoded = try? JSONDecoder().decode(UnsplashResponse.self, from: data),
                   let imageURL = decoded.results?.first?.urls?.small,
                   !imageURL.isEmpty {
                    return imageURL
                }
            }
        }
        return nil
    }
    
    // Enhanced caching for SkincareAPI (longer TTL since it's free)
    private func getSkincareAPICache(for query: String) -> [ProductSearchResult]? {
        guard let cached = skincareAPICache[query] else { return nil }
        let age = Date().timeIntervalSince(cached.timestamp)
        guard age < skincareAPICacheTTL else {
            // Expired, remove from cache
            skincareAPICache.removeValue(forKey: query)
            return nil
        }
        return cached.results
    }
    
    private func setSkincareAPICache(for query: String, results: [ProductSearchResult]) {
        skincareAPICache[query] = (results: results, timestamp: Date())
        print("💾 ProductSearch: Cached \(results.count) SkincareAPI results for query=\(query)")
    }
    
    // Prefer Amazon search for product view links
    static func amazonSearchURL(for title: String) -> URL? {
        var components = URLComponents(string: "https://www.amazon.com/s")
        var items: [URLQueryItem] = [URLQueryItem(name: "k", value: title)]
        components?.queryItems = items
        return components?.url
    }
}

// MARK: - Google CSE Response Models

private struct GCSearchResponse: Codable {
    let items: [GCItem]?
}

private struct GCItem: Codable {
    let title: String
    let link: String
    let image: GCImageInfo?
}

private struct GCImageInfo: Codable {
    let contextLink: String?
    let thumbnailLink: String?
}


