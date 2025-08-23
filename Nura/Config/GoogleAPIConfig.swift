import Foundation

struct GoogleAPIConfig {
    // Provide your Google Custom Search API key and Search Engine ID (cx)
    // For development, you can set them via UserDefaults to avoid committing secrets.
    // UserDefaults keys: GOOGLE_CSE_API_KEY, GOOGLE_CSE_ID
    static var apiKey: String? {
        if let key = UserDefaults.standard.string(forKey: "GOOGLE_CSE_API_KEY"), !key.isEmpty { return key }
        return nil
    }
    static var searchEngineId: String? {
        if let id = UserDefaults.standard.string(forKey: "GOOGLE_CSE_ID"), !id.isEmpty { return id }
        return nil
    }
    
    // Development helper - set these once to test
    static func setupDevelopmentCredentials() {
        UserDefaults.standard.set("AIzaSyDnXxfAbSWF1gxIQeBuQVF-gyKwM2jqS-E", forKey: "GOOGLE_CSE_API_KEY")
        UserDefaults.standard.set("621228c74e9f1492c", forKey: "GOOGLE_CSE_ID")
    }
}