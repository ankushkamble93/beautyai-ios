import Foundation

struct APIConfig {
    // MARK: - ChatGPT Configuration
    static let openAIBaseURL = "https://api.openai.com/v1"
    
    // MARK: - API Key Management
    // For development: Set your API key here temporarily
    // For production: Use a secure key management service or backend
    private static let developmentAPIKey = "YOUR_OPENAI_API_KEY_HERE" // placeholder for local dev only
    
    static let openAIAPIKey: String = {
        print("🔍 APIConfig: openAIAPIKey getter called!")
        print("🔍 APIConfig: developmentAPIKey = \(developmentAPIKey)")
        
        // First try to get from UserDefaults (if user has set it in app)
        if let userKey = UserDefaults.standard.string(forKey: "OPENAI_API_KEY"), !userKey.isEmpty {
            print("🔍 APIConfig: Using UserDefaults API key: \(userKey.prefix(10))...")
            return userKey
        }
        
        // Fallback to development key (remove this in production)
        #if DEBUG
        print("🔍 APIConfig: Using development API key: \(developmentAPIKey.prefix(10))...")
        return developmentAPIKey
        #else
        // In production, you might want to fetch from a secure backend
        fatalError("OpenAI API key not configured. Please set it in UserDefaults or use a secure key management service.")
        #endif
    }()
    
    // MARK: - Runtime API Key Configuration
    static func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "OPENAI_API_KEY")
    }
    
    static func clearAPIKey() {
        UserDefaults.standard.removeObject(forKey: "OPENAI_API_KEY")
        print("🔍 APIConfig: Cleared UserDefaults API key")
    }
    
    // MARK: - API Endpoints
    static let chatGPTVisionEndpoint = "\(openAIBaseURL)/chat/completions" // legacy path for vision usage
    static let chatCompletionsEndpoint = "\(openAIBaseURL)/chat/completions" // text-only chat completion
    
    // MARK: - Model Configuration
    static let gpt35VisionModel = "gpt-4o-mini" // Vision-capable model
    static let gpt4VisionModel = "gpt-4o" // Vision-capable model
    static let fastTextModel = "gpt-4o-mini" // smaller & faster for JSON text
    
    // MARK: - Rate Limiting
    static let maxRequestsPerMinute = 60
    static let maxTokensPerRequest = 1600 // headroom to avoid truncation while still bounded
    static let requestTimeout: TimeInterval = 20
    static let resourceTimeout: TimeInterval = 30
    
    // MARK: - Image Processing
    static let maxImageSize = 20 * 1024 * 1024 // 20MB
    static let supportedImageFormats = ["jpeg", "jpg", "png"]
    
    // MARK: - Caching
    static let analysisCacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    
    // MARK: - Error Messages
    static let apiKeyMissingError = "OpenAI API key not configured. Use APIConfig.setAPIKey() or set in UserDefaults."
    static let rateLimitExceededError = "Rate limit exceeded. Please try again later."
    static let invalidImageFormatError = "Unsupported image format. Please use JPEG or PNG."
    static let imageTooLargeError = "Image too large. Please use an image smaller than 20MB."
    
    // MARK: - Debug & JSON mode
    static let enableVerboseAIDebugLogging: Bool = true // set false for prod
    static let preferJSONMode: Bool = true
    static let jsonSeed: Int = 7
    
    // MARK: - Debug Logging
    static func logConfiguration() {
        print("🔍 APIConfig: OpenAI Base URL: \(openAIBaseURL)")
        print("🔍 APIConfig: ChatGPT Vision Endpoint: \(chatGPTVisionEndpoint)")
        print("🔍 APIConfig: Chat Completions Endpoint: \(chatCompletionsEndpoint)")
        print("🔍 APIConfig: GPT-3.5 Vision Model: \(gpt35VisionModel)")
        print("🔍 APIConfig: GPT-4 Vision Model: \(gpt4VisionModel)")
        print("🔍 APIConfig: Fast Text Model: \(fastTextModel)")
        print("🔍 APIConfig: Max Tokens: \(maxTokensPerRequest)")
        print("🔍 APIConfig: Request Timeout: \(requestTimeout)s, Resource Timeout: \(resourceTimeout)s")
        print("🔍 APIConfig: Max Requests/Min: \(maxRequestsPerMinute)")
        print("🔍 APIConfig: Max Image Size: \(maxImageSize / (1024 * 1024))MB")
        print("🔍 APIConfig: Cache Duration: \(analysisCacheDuration / 3600) hours")
    }
} 