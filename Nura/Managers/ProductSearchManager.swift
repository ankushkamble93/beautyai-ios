import Foundation
import UIKit

final class ProductSearchManager {
    static let shared = ProductSearchManager()
    private init() {}
    
    // Simple in-memory cache for search results to reduce API calls
    private var recentQueryToResults: [String: [ProductSearchResult]] = [:]
    
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
        if let cached = recentQueryToResults[query.normalizedQuery] { return cached }
        // Primary: Google Custom Search API
        if let results = try? await googleCustomSearch(query: query.normalizedQuery, category: query.categoryHint) {
            recentQueryToResults[query.normalizedQuery] = results
            return results
        }
        // Fallback: Local DB
        let local = localResults(for: query)
        recentQueryToResults[query.normalizedQuery] = local
        return local
    }
    
    // MARK: - Google Custom Search (Primary)
    
    private func googleCustomSearch(query: String, category: String?) async throws -> [ProductSearchResult] {
        guard let apiKey = GoogleAPIConfig.apiKey, let cx = GoogleAPIConfig.searchEngineId else {
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
            URLQueryItem(name: "safe", value: "active")
        ]
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 12
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "ProductSearch", code: -2, userInfo: [NSLocalizedDescriptionKey: "Google API error"])
        }
        let decoded = try JSONDecoder().decode(GCSearchResponse.self, from: data)
        let results: [ProductSearchResult] = decoded.items?.prefix(6).map { item in
            let title = item.title
            let brand = inferBrand(from: title)
            let benefits = inferBenefits(from: title)
            let dest = item.image?.contextLink
            let aff = Self.buildAffiliateLink(from: dest)
            return ProductSearchResult(name: title, brand: brand, priceText: nil, benefits: benefits, imageURL: item.link, destinationURL: aff?.absoluteString ?? dest)
        } ?? []
        return results
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
        if lower.contains("vitamin c") { benefits.append("vitamin c") }
        if lower.contains("hyaluronic") { benefits.append("hydrating") }
        return benefits
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
}


