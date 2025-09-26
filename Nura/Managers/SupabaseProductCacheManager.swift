import Foundation

enum ProductSource: String {
    case obf, opf, google, manual, other
}

final class SupabaseProductCacheManager {
    nonisolated(unsafe) static let shared = SupabaseProductCacheManager()
    private init() {}

    func fetch(barcodeNorm: String) async -> ResolvedProduct? {
        let baseURL = await MainActor.run { AuthenticationManager.shared.supabaseURL }
        let apiKey = await MainActor.run { AuthenticationManager.shared.supabaseKey }
        let url = baseURL.appendingPathComponent("/rest/v1/product_barcodes")
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "barcode_norm", value: "eq.\(barcodeNorm)"),
            URLQueryItem(name: "select", value: "barcode_norm,barcode_raw,name,brand,image_url,ingredients,retailer_url")
        ]
        var req = URLRequest(url: comps.url!)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            if let arr = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]], let row = arr.first {
                let name = (row["name"] as? String) ?? "Unknown product"
                let brand = row["brand"] as? String
                let image = row["image_url"] as? String
                let ingredients = row["ingredients"] as? [String]
                let retailer = row["retailer_url"] as? String
                let raw = (row["barcode_raw"] as? String) ?? barcodeNorm
                return ResolvedProduct(barcode: raw, name: name, brand: brand, imageURL: image, ingredients: ingredients, retailerURL: retailer)
            }
        } catch {
            print("❌ [SupabaseCache] fetch error: \(error)")
        }
        return nil
    }

    func upsert(resolved: ResolvedProduct, source: ProductSource, manual: Bool = false) async {
        let baseURL = await MainActor.run { AuthenticationManager.shared.supabaseURL }
        let apiKey = await MainActor.run { AuthenticationManager.shared.supabaseKey }
        let url = baseURL.appendingPathComponent("/rest/v1/rpc/upsert_product_barcode")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        let payload: [String: Any] = [
            "p_barcode_raw": resolved.barcode,
            "p_name": resolved.name,
            "p_brand": resolved.brand as Any,
            "p_image_url": resolved.imageURL as Any,
            "p_ingredients": resolved.ingredients as Any,
            "p_retailer_url": resolved.retailerURL as Any,
            "p_source": source.rawValue,
            "p_manual": manual
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        do {
            let (_, resp) = try await URLSession.shared.data(for: req)
            if let http = resp as? HTTPURLResponse { print("💾 [SupabaseCache] upsert status=\(http.statusCode)") }
        } catch { print("❌ [SupabaseCache] upsert error: \(error)") }
    }
}


