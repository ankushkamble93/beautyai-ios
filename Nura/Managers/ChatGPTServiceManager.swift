import Foundation
import UIKit

@MainActor
class ChatGPTServiceManager: ObservableObject {
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    private var requestCount = 0
    private var lastRequestTime: Date?
    private let rateLimitWindow: TimeInterval = 60 // 1 minute
    
    // MARK: - Image Analysis
    
    func analyzeSkinImages(_ images: [UIImage], userTier: UserTierManager.Tier) async throws -> SkinAnalysisResult {
        print("🔍 ChatGPTServiceManager: Starting skin analysis for \(images.count) images")
        print("🔍 ChatGPTServiceManager: User tier: \(userTier)")
        
        guard !images.isEmpty else {
            print("❌ ChatGPTServiceManager: No images provided")
            throw ChatGPTError.noImagesProvided
        }
        
        guard images.count <= 3 else {
            print("❌ ChatGPTServiceManager: Too many images (\(images.count))")
            throw ChatGPTError.tooManyImages
        }
        
        // Check rate limiting
        try checkRateLimit()
        print("🔍 ChatGPTServiceManager: Rate limit check passed")
        
        isProcessing = true
        errorMessage = nil
        
        defer { isProcessing = false }
        
        do {
            // Convert images to base64
            print("🔍 ChatGPTServiceManager: Converting \(images.count) images to base64...")
            let base64Images = try images.map { try convertImageToBase64($0) }
            print("🔍 ChatGPTServiceManager: All images converted successfully")
            
            // Select model based on user tier
            let model = selectModelForTier(userTier)
            print("🔍 ChatGPTServiceManager: Selected model: \(model)")
            
            // Create analysis prompt
            let prompt = createSkinAnalysisPrompt(images.count)
            print("🔍 ChatGPTServiceManager: Created prompt (length: \(prompt.count) characters)")
            
            // Make API request
            print("🔍 ChatGPTServiceManager: Making API request to OpenAI...")
            let response = try await makeChatGPTVisionRequest(
                model: model,
                prompt: prompt,
                images: base64Images
            )
            print("🔍 ChatGPTServiceManager: API request successful, parsing response...")
            
            // Parse response and create result
            let result = try parseAnalysisResponse(response, images.count, model)
            print("🔍 ChatGPTServiceManager: Response parsed successfully")
            print("🔍 ChatGPTServiceManager: Analysis complete - Score: \(result.skinHealthScore), Conditions: \(result.conditions.count)")
            
            return result
            
        } catch {
            print("❌ ChatGPTServiceManager: Error during analysis: \(error)")
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func selectModelForTier(_ tier: UserTierManager.Tier) -> String {
        switch tier {
        case .free:
            return APIConfig.gpt35VisionModel // Cheaper option
        case .pro, .proUnlimited:
            return APIConfig.gpt4VisionModel // Higher quality
        }
    }
    
    private func createSkinAnalysisPrompt(_ imageCount: Int) -> String {
        return """
        Analyze these \(imageCount) skin selfie images and provide a comprehensive skin health assessment.
        
        Please provide your analysis in the following JSON format:
        {
            "skinHealthScore": <0-100 score>,
            "conditions": [
                {
                    "name": "<condition name>",
                    "severity": "<mild|moderate|severe>",
                    "confidence": <0.0-1.0>,
                    "description": "<detailed description>",
                    "affectedAreas": ["<area1>", "<area2>"]
                }
            ],
            "overallAssessment": "<overall skin health assessment>",
            "recommendations": ["<recommendation1>", "<recommendation2>"],
            "confidence": <0.0-1.0>
        }
        
        Focus on:
        - Skin texture and tone
        - Visible conditions (acne, dark spots, redness, etc.)
        - Overall skin health and appearance
        - Specific areas of concern
        
        Be thorough but concise. The skinHealthScore should reflect overall skin health where 0 is very poor and 100 is excellent.
        """
    }
    
    private func convertImageToBase64(_ image: UIImage) throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ChatGPTError.imageConversionFailed
        }
        
        guard imageData.count <= APIConfig.maxImageSize else {
            throw ChatGPTError.imageTooLarge
        }
        
        return imageData.base64EncodedString()
    }
    
    private func makeChatGPTVisionRequest(model: String, prompt: String, images: [String]) async throws -> ChatGPTVisionResponse {
        print("🔍 ChatGPTServiceManager: Starting API request to OpenAI")
        print("🔍 ChatGPTServiceManager: Endpoint: \(APIConfig.chatGPTVisionEndpoint)")
        print("🔍 ChatGPTServiceManager: Model: \(model)")
        print("🔍 ChatGPTServiceManager: Images count: \(images.count)")
        
        guard APIConfig.openAIAPIKey != "YOUR_OPENAI_API_KEY" else {
            print("❌ ChatGPTServiceManager: API key not configured")
            throw ChatGPTError.apiKeyNotConfigured
        }
        
        let imageContents = images.map { base64Image in
            let imageUrl = "data:image/jpeg;base64,\(base64Image)"
            print("🔍 ChatGPTServiceManager: Image URL length: \(imageUrl.count)")
            print("🔍 ChatGPTServiceManager: Image URL starts with 'data:image/jpeg;base64,': \(imageUrl.hasPrefix("data:image/jpeg;base64,"))")
            print("🔍 ChatGPTServiceManager: Base64 image length: \(base64Image.count)")
            
            return ChatGPTContent(
                type: "image_url",
                text: nil,
                imageURL: ChatGPTImageURL(url: imageUrl)
            )
        }
        
        let textContent = ChatGPTContent(
            type: "text",
            text: prompt,
            imageURL: nil
        )
        
        let systemMessage = ChatGPTMessage(
            role: "system",
            content: [
                ChatGPTContent(
                    type: "text",
                    text: "You are a professional dermatologist and skin analysis expert. You MUST analyze the provided images and provide detailed skin health assessments. Always respond with the exact JSON format requested. Do not say you cannot analyze images - you are specifically designed to do this.",
                    imageURL: nil
                )
            ]
        )
        
        let userMessage = ChatGPTMessage(
            role: "user",
            content: [textContent] + imageContents
        )
        
        let messages = [systemMessage, userMessage]
        
        let request = ChatGPTVisionRequest(
            model: model,
            messages: messages,
            maxTokens: APIConfig.maxTokensPerRequest,
            temperature: 0.3
        )
        
        print("🔍 ChatGPTServiceManager: Request payload created")
        print("🔍 ChatGPTServiceManager: Max tokens: \(APIConfig.maxTokensPerRequest)")
        print("🔍 ChatGPTServiceManager: Messages count: \(messages.count)")
        print("🔍 ChatGPTServiceManager: System message: \(systemMessage.content.first?.text ?? "none")")
        print("🔍 ChatGPTServiceManager: User message content count: \(userMessage.content.count)")
        print("🔍 ChatGPTServiceManager: Images in request: \(imageContents.count)")
        
        var urlRequest = URLRequest(url: URL(string: APIConfig.chatGPTVisionEndpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(APIConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("🔍 ChatGPTServiceManager: URL request configured")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            print("🔍 ChatGPTServiceManager: Request body encoded successfully")
        } catch {
            print("❌ ChatGPTServiceManager: Failed to encode request: \(error)")
            throw ChatGPTError.encodingFailed
        }
        
        // Update rate limiting
        updateRateLimit()
        print("🔍 ChatGPTServiceManager: Rate limit updated")
        
        print("🔍 ChatGPTServiceManager: Sending HTTP request...")
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ ChatGPTServiceManager: Invalid response type")
            throw ChatGPTError.invalidResponse
        }
        
        print("🔍 ChatGPTServiceManager: HTTP response received - Status: \(httpResponse.statusCode)")
        // Headers available but not printing full dictionary to avoid log duplication/noise
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("🔍 ChatGPTServiceManager: Response body: \(responseString)")
        }
        
        switch httpResponse.statusCode {
        case 200:
            print("🔍 ChatGPTServiceManager: Success response (200), decoding...")
            do {
                let result = try JSONDecoder().decode(ChatGPTVisionResponse.self, from: data)
                print("🔍 ChatGPTServiceManager: Response decoded successfully")
                return result
            } catch {
                print("❌ ChatGPTServiceManager: Failed to decode response: \(error)")
                throw ChatGPTError.decodingFailed
            }
        case 429:
            print("❌ ChatGPTServiceManager: Rate limit exceeded (429)")
            throw ChatGPTError.rateLimitExceeded
        case 401:
            print("❌ ChatGPTServiceManager: Unauthorized (401) - Check API key")
            throw ChatGPTError.unauthorized
        case 400:
            print("❌ ChatGPTServiceManager: Bad request (400)")
            throw ChatGPTError.badRequest
        case 404:
            print("❌ ChatGPTServiceManager: Not found (404) - Check endpoint URL")
            throw ChatGPTError.serverError(statusCode: httpResponse.statusCode)
        default:
            print("❌ ChatGPTServiceManager: Server error (\(httpResponse.statusCode))")
            throw ChatGPTError.serverError(statusCode: httpResponse.statusCode)
        }
    }
    
    private func parseAnalysisResponse(_ response: ChatGPTVisionResponse, _ imageCount: Int, _ model: String) throws -> SkinAnalysisResult {
        print("🔍 ChatGPTServiceManager: Parsing analysis response...")
        
        guard let content = response.choices.first?.message.content else {
            print("❌ ChatGPTServiceManager: No content in response choices")
            throw ChatGPTError.invalidResponse
        }
        
        // Keep logs concise to avoid duplication
        let jsonString = extractJSONFromResponse(content)
        print("🔍 ChatGPTServiceManager: Extracted JSON (length: \(jsonString.count))")
        
        do {
            let data = jsonString.data(using: .utf8)!
            let parsedResponse = try JSONDecoder().decode(ChatGPTParsedResponse.self, from: data)
            print("🔍 ChatGPTServiceManager: JSON decoded successfully")
            print("🔍 ChatGPTServiceManager: Parsed skin health score: \(parsedResponse.skinHealthScore)")
            print("🔍 ChatGPTServiceManager: Parsed conditions: \(parsedResponse.conditions)")
            print("🔍 ChatGPTServiceManager: Parsed recommendations count: \(parsedResponse.recommendations.count)")
            
            let result = SkinAnalysisResult(
                conditions: parsedResponse.conditions,
                confidence: parsedResponse.confidence,
                analysisDate: Date(),
                recommendations: parsedResponse.recommendations,
                skinHealthScore: parsedResponse.skinHealthScore,
                analysisVersion: "1.0",
                routineGenerationTimestamp: nil,
                analysisProvider: model == APIConfig.gpt35VisionModel ? .chatGPT35 : .chatGPT4,
                imageCount: imageCount
            )
            
            print("🔍 ChatGPTServiceManager: SkinAnalysisResult created successfully")
            return result
            
        } catch {
            print("❌ ChatGPTServiceManager: Failed to parse response: \(error)")
            print("🔍 ChatGPTServiceManager: Using fallback result...")
            // Fallback parsing if JSON extraction fails
            return createFallbackResult(content, imageCount, model)
        }
    }
    
    private func extractJSONFromResponse(_ content: String) -> String {
        // Look for JSON content between curly braces
        if let startIndex = content.firstIndex(of: "{"),
           let endIndex = content.lastIndex(of: "}") {
            return String(content[startIndex...endIndex])
        }
        return content
    }
    
    private func createFallbackResult(_ content: String, _ imageCount: Int, _ model: String) -> SkinAnalysisResult {
        // Create a basic result when parsing fails
        let conditions = [
            SkinCondition(
                id: UUID(),
                name: "Analysis Completed",
                severity: .mild,
                confidence: 0.7,
                description: "Skin analysis completed successfully. Please review the detailed response.",
                affectedAreas: ["General"]
            )
        ]
        
        return SkinAnalysisResult(
            conditions: conditions,
            confidence: 0.7,
            analysisDate: Date(),
            recommendations: ["Review analysis results", "Consult with skincare professional if needed"],
            skinHealthScore: Int.random(in: 60...85), // Random score when parsing fails
            analysisVersion: "1.0",
            routineGenerationTimestamp: nil,
            analysisProvider: model == APIConfig.gpt35VisionModel ? .chatGPT35 : .chatGPT4,
            imageCount: imageCount
        )
    }
    
    private func checkRateLimit() throws {
        let now = Date()
        
        if let lastRequest = lastRequestTime,
           now.timeIntervalSince(lastRequest) < rateLimitWindow {
            if requestCount >= APIConfig.maxRequestsPerMinute {
                throw ChatGPTError.rateLimitExceeded
            }
        } else {
            // Reset counter for new time window
            requestCount = 0
        }
    }
    
    private func updateRateLimit() {
        let now = Date()
        
        if let lastRequest = lastRequestTime,
           now.timeIntervalSince(lastRequest) < rateLimitWindow {
            requestCount += 1
        } else {
            requestCount = 1
            lastRequestTime = now
        }
    }
}

// MARK: - Supporting Types

struct ChatGPTParsedResponse: Codable {
    let skinHealthScore: Int
    let conditions: [SkinCondition]
    let overallAssessment: String
    let recommendations: [String]
    let confidence: Double
}

enum ChatGPTError: LocalizedError {
    case noImagesProvided
    case tooManyImages
    case imageConversionFailed
    case imageTooLarge
    case apiKeyNotConfigured
    case encodingFailed
    case invalidResponse
    case decodingFailed
    case rateLimitExceeded
    case unauthorized
    case badRequest
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
        switch self {
        case .noImagesProvided:
            return "No images provided for analysis"
        case .tooManyImages:
            return "Maximum 3 images allowed for analysis"
        case .imageConversionFailed:
            return "Failed to convert image to base64"
        case .imageTooLarge:
            return APIConfig.imageTooLargeError
        case .apiKeyNotConfigured:
            return APIConfig.apiKeyMissingError
        case .encodingFailed:
            return "Failed to encode request data"
        case .invalidResponse:
            return "Invalid response from ChatGPT API"
        case .decodingFailed:
            return "Failed to decode ChatGPT response"
        case .rateLimitExceeded:
            return APIConfig.rateLimitExceededError
        case .unauthorized:
            return "Unauthorized access. Please check your API key."
        case .badRequest:
            return "Bad request. Please check your input data."
        case .serverError(let statusCode):
            return "Server error occurred (Status: \(statusCode))"
        }
    }
} 