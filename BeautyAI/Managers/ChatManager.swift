import Foundation

class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        messages.append(ChatMessage(
            id: UUID(),
            content: "Hi! I am your AI skin assistant. How can I help you today?",
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
        // AI response logic will be implemented here
    }
}
