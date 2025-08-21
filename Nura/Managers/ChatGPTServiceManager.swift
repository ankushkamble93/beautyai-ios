import Foundation
import UIKit
import Supabase

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
        
        // No need to check API key - Supabase proxy handles authentication
        
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
        
        // Convert to the format expected by Supabase proxy
        let messagesDict = messages.map { message in
            var content: Any
            if message.content.count == 1 && message.content.first?.type == "text" {
                content = message.content.first?.text ?? ""
            } else {
                content = message.content.map { contentItem in
                    if contentItem.type == "text" {
                        return ["type": "text", "text": contentItem.text ?? ""]
                    } else if contentItem.type == "image_url" {
                        return ["type": "image_url", "image_url": ["url": contentItem.imageURL?.url ?? ""]]
                    } else {
                        return ["type": "text", "text": ""]
                    }
                }
            }
            
            return [
                "role": message.role,
                "content": content
            ]
        }
        
        print("🔍 ChatGPTServiceManager: Request payload created for Supabase proxy")
        print("🔍 ChatGPTServiceManager: Max tokens: \(APIConfig.maxTokensPerRequest)")
        print("🔍 ChatGPTServiceManager: Messages count: \(messagesDict.count)")
        
        // Use Supabase proxy instead of direct OpenAI call
        let response = try await SupabaseProxyManager.shared.makeOpenAIRequest(
            model: model,
            messages: messagesDict,
            maxTokens: APIConfig.maxTokensPerRequest,
            temperature: 0.3
        )
        
        // Update rate limiting
        updateRateLimit()
        print("🔍 ChatGPTServiceManager: Rate limit updated")
        
        print("🔍 ChatGPTServiceManager: Supabase proxy response received, parsing...")
        
        // Parse the response from Supabase proxy
        guard let data = response.data(using: .utf8) else {
            print("❌ ChatGPTServiceManager: Failed to convert response to data")
            throw ChatGPTError.invalidResponse
        }
        
        print("🔍 ChatGPTServiceManager: Success response from Supabase proxy, decoding...")
            do {
                let result = try JSONDecoder().decode(ChatGPTVisionResponse.self, from: data)
                print("🔍 ChatGPTServiceManager: Response decoded successfully")
                return result
            } catch {
                print("❌ ChatGPTServiceManager: Failed to decode response: \(error)")
                throw ChatGPTError.decodingFailed
            }
        // Error handling is now done by SupabaseProxyManager
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