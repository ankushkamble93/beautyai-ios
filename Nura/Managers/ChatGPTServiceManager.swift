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
        
        do {
            // Make API request
            print("🔍 ChatGPTServiceManager: Making API request to OpenAI...")
            let response = try await makeChatGPTVisionRequest(
                model: model,
                prompt: prompt,
                images: base64Images
            )
            print("🔍 ChatGPTServiceManager: API request successful, extracting JSON...")

            // Extract JSON content from response (handles markdown formatting)
            guard let content = response.choices.first?.message.content else {
                print("❌ ChatGPTServiceManager: No content in response")
                throw ChatGPTError.invalidResponse
            }

            if isModelRefusalResponse(content) {
                print("⚠️ ChatGPTServiceManager: Model returned refusal/non-compliant response; using graceful fallback result")
                return createFallbackResult(content, images.count, model)
            }

            let extractedJSON = extractJSONFromResponse(content)
            let responseLength = content.count
            print("🔍 ChatGPTServiceManager: Raw response content length: \(responseLength)")
            print("🔍 ChatGPTServiceManager: JSON extracted, validating...")
            
            // Check for response truncation
            if responseLength < 200 {
                print("⚠️ ChatGPTServiceManager: Response too short (\(responseLength) chars), likely truncated")
                throw ChatGPTError.invalidResponse
            }

            // Validate extracted JSON format
            guard validateExtractedJSON(extractedJSON) else {
                print("❌ ChatGPTServiceManager: Extracted JSON validation failed")
                throw ChatGPTError.invalidResponse
            }

            print("🔍 ChatGPTServiceManager: JSON validation passed, parsing...")

            // Parse response and create result with extracted JSON
            let result = try parseAnalysisResponse(extractedJSON, images.count, model)
            print("🔍 ChatGPTServiceManager: Response parsed successfully")
            print("🔍 ChatGPTServiceManager: Analysis complete - Score: \(result.skinHealthScore), Conditions: \(result.conditions.count)")
            
            // Log skin age information
            if let skinAge = result.skinAgeYears {
                print("✅ ChatGPTServiceManager: Skin age detected: \(skinAge) years")
            } else {
                print("⚠️ ChatGPTServiceManager: No skin age detected in response")
            }
            
            // Check if this is a fallback result
            if result.conditions.contains(where: { $0.name.lowercased().contains("analysis failed") }) {
                print("⚠️ ChatGPTServiceManager: Analysis completed with fallback result - parsing may have failed")
            }
            
            return result
            
        } catch {
            print("❌ ChatGPTServiceManager: Error during analysis: \(error)")
            errorMessage = error.localizedDescription
            
            // If it's a parsing error or invalid response, try once more with a shorter prompt
            if let chatGPTError = error as? ChatGPTError, chatGPTError == .invalidResponse {
                print("🔄 ChatGPTServiceManager: Attempting retry with shorter prompt...")
                do {
                    let shorterPrompt = createShortSkinAnalysisPrompt(images.count)
                    let retryResponse = try await makeChatGPTVisionRequest(model: model, prompt: shorterPrompt, images: base64Images)
                    
                    guard let retryContent = retryResponse.choices.first?.message.content else {
                        print("❌ ChatGPTServiceManager: Retry failed - no content")
                        throw error
                    }
                    
                    if isModelRefusalResponse(retryContent) {
                        print("⚠️ ChatGPTServiceManager: Retry also returned refusal; using graceful fallback result")
                        return createFallbackResult(retryContent, images.count, model)
                    }

                    let retryJSON = extractJSONFromResponse(retryContent)
                    print("🔍 ChatGPTServiceManager: Retry JSON extracted, length: \(retryJSON.count)")
                    
                    if validateExtractedJSON(retryJSON) {
                        let result = try parseAnalysisResponse(retryJSON, images.count, model)
                        print("✅ ChatGPTServiceManager: Retry successful with shorter prompt")
                        return result
                    }
                } catch {
                    print("❌ ChatGPTServiceManager: Retry also failed: \(error)")
                }
            }
            
            // If it's a parsing error, we can't make another API call, so just throw the error
            // The fallback will be handled at a higher level if needed
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
        Analyze \(imageCount) skin images. Return ONLY valid JSON.
        
        CRITICAL: Keep response under 1000 characters to avoid truncation.
        
        JSON format:
        {
            "skinHealthScore": <0-100>,
            "conditions": [
                {
                    "name": "<condition>",
                    "severity": "<mild|moderate|severe>",
                    "confidence": <0.0-1.0>,
                    "description": "<brief description>",
                    "affectedAreas": ["<area1>", "<area2>"]
                }
            ],
            "overallAssessment": "<brief assessment>",
            "recommendations": ["<rec1>", "<rec2>"],
            "confidence": <0.0-1.0>
        }
        
        CRITICAL RULES:
        - Use SHORT descriptions (2-3 words max)
        - MAX 2 conditions to stay under character limit
        - MAX 2 recommendations
        - Keep overallAssessment under 20 words
        - Use simple string IDs like "step-1", "step-2" (NOT UUIDs)
        - Use only these frequency values: "daily", "twice_daily", "nightly", "weekly", "as_needed"
        
        Remember: ONLY JSON, no other text.
        """
    }
    
    private func createShortSkinAnalysisPrompt(_ imageCount: Int) -> String {
        return """
        Analyze \(imageCount) skin images. Return ONLY JSON.
        
        CRITICAL: Keep response under 500 characters.
        
        {
            "skinHealthScore": <0-100>,
            "conditions": [
                {
                    "name": "<condition>",
                    "severity": "<mild|moderate|severe>",
                    "confidence": <0.0-1.0>,
                    "description": "<2 words>",
                    "affectedAreas": ["<area>"]
                }
            ],
            "overallAssessment": "<5 words>",
            "recommendations": ["<rec>"],
            "confidence": <0.0-1.0>
        }
        
        RULES:
        - MAX 1 condition
        - MAX 1 recommendation
        - SHORT descriptions only
        - Use simple string IDs like "step-1" (NOT UUIDs)
        - Use only these frequency values: "daily", "twice_daily", "nightly", "weekly", "as_needed"
        
        ONLY JSON, no other text.
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
                    text: "You are a skincare analysis assistant. Provide non-diagnostic cosmetic skin observations from the provided images. CRITICAL: respond with ONLY valid JSON in the exact format requested. No markdown, no explanations, no additional text. The response must be a single JSON object starting with { and ending with }. If you cannot analyze the images for any reason, still respond with valid JSON using placeholder values.",
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
        let messagesDict: [[String: Any]] = messages.map { message in
            let contentAny: Any
            if message.content.count == 1 && message.content.first?.type == "text" {
                contentAny = message.content.first?.text ?? ""
            } else {
                contentAny = message.content.map { contentItem -> [String: Any] in
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
                "role": message.role as Any,
                "content": contentAny
            ]
        }
        
        print("🔍 ChatGPTServiceManager: Request payload created for Supabase proxy")
        print("🔍 ChatGPTServiceManager: Max tokens: \(APIConfig.maxTokensPerRequest)")
        print("🔍 ChatGPTServiceManager: Messages count: \(messagesDict.count)")
        
        // Use Supabase proxy instead of direct OpenAI call
        let responseString: String = try await SupabaseProxyManager.shared.makeOpenAIRequest(
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
        guard let data = responseString.data(using: .utf8) else {
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
    
    private func parseAnalysisResponse(_ jsonString: String, _ imageCount: Int, _ model: String) throws -> SkinAnalysisResult {
        print("🔍 ChatGPTServiceManager: Parsing analysis response...")
        print("🔍 ChatGPTServiceManager: JSON content (length: \(jsonString.count))")
        print("🔍 ChatGPTServiceManager: JSON preview: \(String(jsonString.prefix(300)))")

        do {
            let data = jsonString.data(using: .utf8)!
            let parsedResponse = try JSONDecoder().decode(ChatGPTParsedResponse.self, from: data)
            print("🔍 ChatGPTServiceManager: JSON decoded successfully")
            print("🔍 ChatGPTServiceManager: Parsed skin health score: \(parsedResponse.skinHealthScore)")
            print("🔍 ChatGPTServiceManager: Parsed conditions count: \(parsedResponse.conditions.count)")
            print("🔍 ChatGPTServiceManager: Parsed recommendations count: \(parsedResponse.recommendations.count)")
            print("🔍 ChatGPTServiceManager: Parsed confidence: \(parsedResponse.confidence)")
            
            // Validate the parsed data
            guard parsedResponse.skinHealthScore >= 0 && parsedResponse.skinHealthScore <= 100 else {
                print("❌ ChatGPTServiceManager: Invalid skin health score: \(parsedResponse.skinHealthScore)")
                throw ChatGPTError.invalidResponse
            }
            
            guard !parsedResponse.conditions.isEmpty else {
                print("❌ ChatGPTServiceManager: No conditions found in response")
                throw ChatGPTError.invalidResponse
            }

            guard !isPlaceholderAnalysis(parsedResponse) else {
                print("❌ ChatGPTServiceManager: Placeholder/refusal analysis detected")
                throw ChatGPTError.invalidResponse
            }
            
            guard parsedResponse.confidence >= 0.0 && parsedResponse.confidence <= 1.0 else {
                print("❌ ChatGPTServiceManager: Invalid confidence value: \(parsedResponse.confidence)")
                throw ChatGPTError.invalidResponse
            }
            
            let result = SkinAnalysisResult(
                conditions: parsedResponse.conditions,
                confidence: parsedResponse.confidence,
                analysisDate: Date(),
                recommendations: parsedResponse.recommendations,
                skinHealthScore: parsedResponse.skinHealthScore,
                analysisVersion: "1.0",
                routineGenerationTimestamp: nil,
                analysisProvider: model == APIConfig.gpt35VisionModel ? .chatGPT35 : .chatGPT4,
                imageCount: imageCount,
                skinAgeYears: extractSkinAge(from: jsonString)
            )
            
            print("🔍 ChatGPTServiceManager: SkinAnalysisResult created successfully")
            return result
            
        } catch let decodingError as DecodingError {
            print("❌ ChatGPTServiceManager: JSON decoding failed with error: \(decodingError)")
            
            // Provide detailed error information
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("❌ ChatGPTServiceManager: Missing key '\(key)' at path: \(context.codingPath)")
            case .typeMismatch(let type, let context):
                print("❌ ChatGPTServiceManager: Type mismatch for '\(type)' at path: \(context.codingPath)")
            case .valueNotFound(let type, let context):
                print("❌ ChatGPTServiceManager: Value not found for '\(type)' at path: \(context.codingPath)")
            case .dataCorrupted(let context):
                print("❌ ChatGPTServiceManager: Data corrupted at path: \(context.codingPath)")
            @unknown default:
                print("❌ ChatGPTServiceManager: Unknown decoding error")
            }
            
            // Create fallback result instead of throwing error
            print("🔍 ChatGPTServiceManager: Creating fallback result due to parsing failure")
            return createFallbackResult(jsonString, imageCount, model)
        } catch {
            print("❌ ChatGPTServiceManager: Unexpected error during parsing: \(error)")
            // Create fallback result instead of throwing error
            print("🔍 ChatGPTServiceManager: Creating fallback result due to unexpected error")
            return createFallbackResult(jsonString, imageCount, model)
        }
    }

    private func extractSkinAge(from json: String) -> Int? {
        // naive scan for "skinAgeYears": number
        let pattern = #"\"skinAgeYears\"\s*:\s*(\d+)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: json, range: NSRange(location: 0, length: (json as NSString).length)),
           match.numberOfRanges > 1 {
            let ns = json as NSString
            let value = ns.substring(with: match.range(at: 1))
            return Int(value)
        }
        return nil
    }
    
    private func extractJSONFromResponse(_ content: String) -> String {
        print("🔍 ChatGPTServiceManager: Raw response content length: \(content.count)")
        print("🔍 ChatGPTServiceManager: Raw response preview: \(String(content.prefix(200)))")
        
        // First, try to find JSON between curly braces
        if let startIndex = content.firstIndex(of: "{"),
           let endIndex = content.lastIndex(of: "}") {
            let extracted = String(content[startIndex...endIndex])
            print("🔍 ChatGPTServiceManager: Found JSON between braces, length: \(extracted.count)")
            
            // Validate that it looks like JSON
            if extracted.contains("\"skinHealthScore\"") && extracted.contains("\"conditions\"") {
                print("🔍 ChatGPTServiceManager: JSON validation passed")
                return extracted
            } else {
                print("⚠️ ChatGPTServiceManager: Extracted content doesn't contain expected JSON keys")
            }
        }
        
        // Try to find JSON after common prefixes
        let commonPrefixes = [
            "```json",
            "```",
            "Here's the analysis:",
            "Analysis result:",
            "The analysis shows:"
        ]
        
        for prefix in commonPrefixes {
            if let range = content.range(of: prefix) {
                let afterPrefix = String(content[range.upperBound...])
                if let startIndex = afterPrefix.firstIndex(of: "{"),
                   let endIndex = afterPrefix.lastIndex(of: "}") {
                    let extracted = String(afterPrefix[startIndex...endIndex])
                    print("🔍 ChatGPTServiceManager: Found JSON after prefix '\(prefix)', length: \(extracted.count)")
                    
                    if extracted.contains("\"skinHealthScore\"") && extracted.contains("\"conditions\"") {
                        print("🔍 ChatGPTServiceManager: JSON validation passed after prefix")
                        return extracted
                    }
                }
            }
        }
        
        // Try to find any valid JSON structure
        let jsonPattern = #"\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}"#
        if let regex = try? NSRegularExpression(pattern: jsonPattern),
           let match = regex.firstMatch(in: content, range: NSRange(location: 0, length: content.count)) {
            let ns = content as NSString
            let extracted = ns.substring(with: match.range)
            print("🔍 ChatGPTServiceManager: Found JSON using regex pattern, length: \(extracted.count)")
            
            if extracted.contains("\"skinHealthScore\"") && extracted.contains("\"conditions\"") {
                print("🔍 ChatGPTServiceManager: JSON validation passed using regex")
                return extracted
            }
        }
        
        print("⚠️ ChatGPTServiceManager: Could not extract valid JSON, returning original content")
        return content
    }

    private func isModelRefusalResponse(_ content: String) -> Bool {
        let normalized = content.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let refusalPhrases = [
            "i'm sorry",
            "i cannot assist",
            "i can't assist",
            "i cannot help",
            "i can't help",
            "unable to assist",
            "cannot comply",
            "can't comply"
        ]
        let looksLikeRefusal = refusalPhrases.contains { normalized.contains($0) }
        let hasJSONEnvelope = normalized.contains("{") && normalized.contains("}")
        return looksLikeRefusal && !hasJSONEnvelope
    }
    
    private func createFallbackResult(_ content: String, _ imageCount: Int, _ model: String) -> SkinAnalysisResult {
        print("⚠️ ChatGPTServiceManager: Creating fallback result due to parsing failure")
        print("⚠️ ChatGPTServiceManager: Original content length: \(content.count)")
        print("⚠️ ChatGPTServiceManager: Content preview: \(String(content.prefix(200)))")
        
        // Create a more informative fallback result
        let conditions = [
            SkinCondition(
                id: UUID(),
                name: "Analysis Failed - Review Required",
                severity: .moderate,
                confidence: 0.3,
                description: "The AI analysis could not be parsed properly. Please review the raw response or try again. This may indicate an issue with the ChatGPT response format.",
                affectedAreas: ["Analysis System"]
            )
        ]
        
        return SkinAnalysisResult(
            conditions: conditions,
            confidence: 0.3,
            analysisDate: Date(),
            recommendations: [
                "Review the analysis response format",
                "Check ChatGPT API configuration",
                "Verify the prompt is generating valid JSON",
                "Consider adjusting the analysis prompt"
            ],
            skinHealthScore: 50, // Neutral score to indicate analysis failure
            analysisVersion: "1.0",
            routineGenerationTimestamp: nil,
            analysisProvider: model == APIConfig.gpt35VisionModel ? .chatGPT35 : .chatGPT4,
            imageCount: imageCount,
            skinAgeYears: 28 // Default fallback age when analysis fails
        )
    }
    
    // MARK: - Error Handling and Fallback
    
    private func handleParsingFailure(_ content: String, _ imageCount: Int, _ model: String, _ error: Error) -> SkinAnalysisResult {
        print("❌ ChatGPTServiceManager: Parsing failed, creating fallback result")
        print("❌ ChatGPTServiceManager: Error: \(error)")
        print("❌ ChatGPTServiceManager: Content length: \(content.count)")
        
        // Log the problematic content for debugging
        if content.count > 1000 {
            print("❌ ChatGPTServiceManager: Content (first 500 chars): \(String(content.prefix(500)))")
            print("❌ ChatGPTServiceManager: Content (last 500 chars): \(String(content.suffix(500)))")
        } else {
            print("❌ ChatGPTServiceManager: Full content: \(content)")
        }
        
        // Create fallback result
        let fallbackResult = createFallbackResult(content, imageCount, model)
        
        // Post notification for debugging
        NotificationCenter.default.post(
            name: .init("ChatGPTParsingFailed"),
            object: nil,
            userInfo: [
                "error": error,
                "content": content,
                "model": model
            ]
        )
        
        return fallbackResult
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
    
    // MARK: - Response Validation

    private func validateExtractedJSON(_ jsonString: String) -> Bool {
        let trimmedContent = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if response starts and ends with curly braces
        guard trimmedContent.hasPrefix("{") && trimmedContent.hasSuffix("}") else {
            print("❌ ChatGPTServiceManager: Extracted JSON doesn't start/end with curly braces")
            print("❌ ChatGPTServiceManager: Content preview: \(String(trimmedContent.prefix(100)))")
            return false
        }

        // Check if response contains required JSON keys
        let requiredKeys = ["skinHealthScore", "conditions", "overallAssessment", "recommendations", "confidence"]
        for key in requiredKeys {
            guard trimmedContent.contains("\"\(key)\"") else {
                print("❌ ChatGPTServiceManager: Missing required key in extracted JSON: \(key)")
                return false
            }
        }

        // Check if response looks like valid JSON
        guard trimmedContent.contains("[") && trimmedContent.contains("]") else {
            print("❌ ChatGPTServiceManager: Extracted JSON doesn't contain array brackets")
            return false
        }

        print("✅ ChatGPTServiceManager: Extracted JSON validation passed")
        return true
    }

    private func isPlaceholderAnalysis(_ response: ChatGPTParsedResponse) -> Bool {
        let names = response.conditions.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        let descriptions = response.conditions.map { $0.description.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        let areas = response.conditions.flatMap { $0.affectedAreas.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) } }
        let blockedTokens: Set<String> = ["unknown", "n/a", "na", "unable", "unavailable"]

        let allNamesPlaceholder = !names.isEmpty && names.allSatisfy { name in
            blockedTokens.contains(where: { name.contains($0) })
        }
        let allDescriptionsPlaceholder = !descriptions.isEmpty && descriptions.allSatisfy { desc in
            blockedTokens.contains(where: { desc.contains($0) })
        }
        let allAreasPlaceholder = !areas.isEmpty && areas.allSatisfy { area in
            blockedTokens.contains(where: { area.contains($0) })
        }

        return allNamesPlaceholder || (allDescriptionsPlaceholder && allAreasPlaceholder)
    }

    private func validateChatGPTResponse(_ response: ChatGPTVisionResponse) -> Bool {
        guard let content = response.choices.first?.message.content else {
            print("❌ ChatGPTServiceManager: No content in response")
            return false
        }
        
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if response starts and ends with curly braces
        guard trimmedContent.hasPrefix("{") && trimmedContent.hasSuffix("}") else {
            print("❌ ChatGPTServiceManager: Response doesn't start/end with curly braces")
            print("❌ ChatGPTServiceManager: Content preview: \(String(trimmedContent.prefix(100)))")
            return false
        }
        
        // Check if response contains required JSON keys
        let requiredKeys = ["skinHealthScore", "conditions", "overallAssessment", "recommendations", "confidence", "skinAgeYears"]
        for key in requiredKeys {
            guard trimmedContent.contains("\"\(key)\"") else {
                print("❌ ChatGPTServiceManager: Missing required key: \(key)")
                return false
            }
        }
        
        // Check if response looks like valid JSON
        guard trimmedContent.contains("[") && trimmedContent.contains("]") else {
            print("❌ ChatGPTServiceManager: Response doesn't contain array brackets")
            return false
        }
        
        print("✅ ChatGPTServiceManager: Response validation passed")
        return true
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

enum ChatGPTError: LocalizedError, Equatable {
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
    
    // Implement Equatable for cases with associated values
    static func == (lhs: ChatGPTError, rhs: ChatGPTError) -> Bool {
        switch (lhs, rhs) {
        case (.noImagesProvided, .noImagesProvided),
             (.tooManyImages, .tooManyImages),
             (.imageConversionFailed, .imageConversionFailed),
             (.imageTooLarge, .imageTooLarge),
             (.apiKeyNotConfigured, .apiKeyNotConfigured),
             (.encodingFailed, .encodingFailed),
             (.invalidResponse, .invalidResponse),
             (.decodingFailed, .decodingFailed),
             (.rateLimitExceeded, .rateLimitExceeded),
             (.unauthorized, .unauthorized),
             (.badRequest, .badRequest):
            return true
        case (.serverError(let lhsCode), .serverError(let rhsCode)):
            return lhsCode == rhsCode
        default:
            return false
        }
    }
} 