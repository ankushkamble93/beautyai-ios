import Foundation

class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiBaseURL = "https://your-fastapi-backend.com"
    
    init() {
        messages.append(ChatMessage(
            id: UUID(),
            content: "Hi! I am your AI skin assistant. I can help you with skincare questions, analyze your skin concerns, and provide personalized advice. What would you like to know?",
            isUser: false,
            timestamp: Date()
        ))
    }
    
    func sendMessage(_ content: String) {
        let userMessage = ChatMessage(
            id: UUID(),
            content: content,
            isUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        isLoading = true
        errorMessage = nil
        
        sendToGPT4o(content: content) { [weak self] response in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let response = response {
                    let aiMessage = ChatMessage(
                        id: UUID(),
                        content: response,
                        isUser: false,
                        timestamp: Date()
                    )
                    self?.messages.append(aiMessage)
                } else {
                    self?.errorMessage = "Failed to get response from AI assistant"
                }
            }
        }
    }
    
    private func sendToGPT4o(content: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(apiBaseURL)/chat") else {
            completion(nil)
            return
        }
        
        let requestData = ChatRequest(
            message: content,
            conversationHistory: messages.map { $0.content },
            userContext: getUserContext()
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestData)
        } catch {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Chat error: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                let response = try JSONDecoder().decode(ChatResponse.self, from: data)
                completion(response.message)
            } catch {
                print("Decode error: \(error)")
                completion(nil)
            }
        }.resume()
    }
    
    private func getUserContext() -> UserContext {
        return UserContext(
            skinType: "combination",
            recentConditions: ["acne", "dryness"],
            preferences: ["natural products", "budget-friendly"],
            lastAnalysis: Date().addingTimeInterval(-86400)
        )
    }
    
    func clearChat() {
        messages.removeAll()
        messages.append(ChatMessage(
            id: UUID(),
            content: "Hi! I am your AI skin assistant. I can help you with skincare questions, analyze your skin concerns, and provide personalized advice. What would you like to know?",
            isUser: false,
            timestamp: Date()
        ))
    }
}
