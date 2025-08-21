import Foundation
import Supabase

@MainActor
class SupabaseProxyManager: ObservableObject {
    static let shared = SupabaseProxyManager()
    
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private let supabaseClient: SupabaseClient
    
    private init() {
        self.supabaseClient = AuthenticationManager.shared.client
    }
    
    // MARK: - OpenAI Proxy Methods
    
    func makeOpenAIRequest(
        model: String,
        messages: [[String: Any]],
        maxTokens: Int? = nil,
        temperature: Double? = nil
    ) async throws -> [String: Any] {
        
        guard let session = AuthenticationManager.shared.session else {
            throw SupabaseProxyError.notAuthenticated
        }
        
        isProcessing = true
        errorMessage = nil
        
        defer { isProcessing = false }
        
        do {
            // Prepare request payload
            var payload: [String: Any] = [
                "model": model,
                "messages": messages
            ]
            
            if let maxTokens = maxTokens {
                payload["max_tokens"] = maxTokens
            }
            
            if let temperature = temperature {
                payload["temperature"] = temperature
            }
            
            // Get access token for authentication
            let accessToken = session.accessToken
            
            // Make request to Supabase Edge Function
            let url = URL(string: APIConfig.supabaseEdgeFunctionURL)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Convert payload to JSON data
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsonData
            
            print("🔍 SupabaseProxyManager: Making request to Supabase proxy")
            print("🔍 SupabaseProxyManager: Model: \(model)")
            print("🔍 SupabaseProxyManager: Messages count: \(messages.count)")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SupabaseProxyError.invalidResponse
            }
            
            print("🔍 SupabaseProxyManager: HTTP Status: \(httpResponse.statusCode)")
            
            // Handle different HTTP status codes
            switch httpResponse.statusCode {
            case 200:
                // Success - parse OpenAI response
                let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let responseDict = responseDict else {
                    throw SupabaseProxyError.invalidResponseData
                }
                
                print("✅ SupabaseProxyManager: Request successful")
                return responseDict
                
            case 401:
                throw SupabaseProxyError.notAuthenticated
                
            case 429:
                // Rate limit exceeded
                let errorData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let retryAfter = errorData?["retryAfter"] as? Int ?? 60
                throw SupabaseProxyError.rateLimitExceeded(retryAfter: retryAfter)
                
            case 400...499:
                // Client error
                let errorData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorData?["error"] as? String ?? "Client error"
                throw SupabaseProxyError.clientError(message: errorMessage)
                
            case 500...599:
                // Server error
                let errorData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorMessage = errorData?["error"] as? String ?? "Server error"
                throw SupabaseProxyError.serverError(message: errorMessage)
                
            default:
                throw SupabaseProxyError.unknownError
            }
            
        } catch {
            if error is SupabaseProxyError {
                throw error
            } else {
                print("❌ SupabaseProxyManager: Unexpected error: \(error)")
                throw SupabaseProxyError.networkError(error)
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    func makeChatCompletion(
        model: String,
        messages: [[String: Any]],
        maxTokens: Int? = nil,
        temperature: Double? = nil
    ) async throws -> [String: Any] {
        return try await makeOpenAIRequest(
            model: model,
            messages: messages,
            maxTokens: maxTokens,
            temperature: temperature
        )
    }
    
    func makeVisionRequest(
        model: String,
        messages: [[String: Any]],
        maxTokens: Int? = nil
    ) async throws -> [String: Any] {
        return try await makeOpenAIRequest(
            model: model,
            messages: messages,
            maxTokens: maxTokens
        )
    }
}

// MARK: - Error Types

enum SupabaseProxyError: LocalizedError {
    case notAuthenticated
    case rateLimitExceeded(retryAfter: Int)
    case clientError(message: String)
    case serverError(message: String)
    case networkError(Error)
    case invalidResponse
    case invalidResponseData
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated. Please sign in again."
        case .rateLimitExceeded(let retryAfter):
            return "Rate limit exceeded. Please try again in \(retryAfter) seconds."
        case .clientError(let message):
            return "Request error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidResponseData:
            return "Invalid response data format"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to your account and try again."
        case .rateLimitExceeded:
            return "Wait a moment before making another request."
        case .clientError, .serverError:
            return "Please check your request and try again."
        case .networkError:
            return "Please check your internet connection and try again."
        case .invalidResponse, .invalidResponseData:
            return "Please try again later."
        case .unknownError:
            return "Please try again or contact support if the problem persists."
        }
    }
}
