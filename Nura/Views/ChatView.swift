import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatManager: ChatManager
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack {
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatManager.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if chatManager.isLoading {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                        .scaleEffect(0.8)
                                    
                                    Text("AI is thinking...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .onChange(of: chatManager.messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(chatManager.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Error message
                if let errorMessage = chatManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.horizontal)
                }
                
                // Message input
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Ask about your skin...", text: $messageText, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($isTextFieldFocused)
                            .lineLimit(1...4)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.purple)
                                .cornerRadius(20)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatManager.isLoading)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("AI Skin Assistant")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Clear") {
                chatManager.clearChat()
            })
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        chatManager.sendMessage(trimmedMessage)
        messageText = ""
        isTextFieldFocused = false
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .cornerRadius(4, corners: [.topLeft, .topRight, .bottomLeft])
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.1))
                            .foregroundColor(.primary)
                            .cornerRadius(20)
                            .cornerRadius(4, corners: [.topLeft, .topRight, .bottomRight])
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.leading, 24)
                }
                
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatManager())
} 