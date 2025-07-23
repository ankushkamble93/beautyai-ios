import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatManager: ChatManager
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var hasPremium = false // Toggle for testing
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content (chat UI and sample conversation)
                VStack {
                    // Custom large, centered title
                    HStack {
                        Spacer()
                        Text("Skin Concierge")
                            .font(.largeTitle).fontWeight(.bold)
                            .padding(.top, 8)
                        Spacer()
                    }
                    Spacer().frame(height: 12)
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                if chatManager.messages.isEmpty {
                                    Group {
                                        MessageBubble(message: ChatMessage(id: UUID(), content: "Hi, I’m Nura. Your personal skin concierge. I’m here to help you with all things skin—routine, products, and confidence. What’s on your mind today?", isUser: false, timestamp: Date()))
                                            .padding(.top, 36)
                                        MessageBubble(message: ChatMessage(id: UUID(), content: "Hi Nura! What’s the best way to keep my skin hydrated during winter?", isUser: true, timestamp: Date()))
                                        MessageBubble(message: ChatMessage(id: UUID(), content: "Great question! In winter, use a gentle cleanser, layer a hydrating serum with hyaluronic acid, and seal it in with a rich moisturizer. Want product suggestions?", isUser: false, timestamp: Date()))
                                        MessageBubble(message: ChatMessage(id: UUID(), content: "Yes, please! My skin gets dry and flaky.", isUser: true, timestamp: Date()))
                                        MessageBubble(message: ChatMessage(id: UUID(), content: "Try a fragrance-free moisturizer with ceramides, like CeraVe or Vanicream. And don’t forget SPF, even on cloudy days!", isUser: false, timestamp: Date()))
                                    }
                                } else {
                                    ForEach(chatManager.messages) { message in
                                        MessageBubble(message: message)
                                            .id(message.id)
                                    }
                                }
                                if chatManager.isLoading {
                                    HStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: NuraColors.primary))
                                            .scaleEffect(0.8)
                                        Text("AI is thinking...")
                                            .font(.caption)
                                            .foregroundColor(NuraColors.textSecondary)
                                    }
                                    .padding()
                                    .background(NuraColors.card.opacity(0.1))
                                    .cornerRadius(20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 10)
                        }
                        .onChange(of: chatManager.messages.count) { oldValue, newValue in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(chatManager.messages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                    // Error message
                    if let errorMessage = chatManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(NuraColors.error)
                            .font(.caption)
                            .padding(.horizontal)
                    }
                    // Message input
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 12) {
                            TextField("Type your skin wish... 🪄", text: $messageText, axis: .vertical)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(Color(red: 0.976, green: 0.965, blue: 0.949)) // #F9F6F2
                                .cornerRadius(24)
                                .focused($isTextFieldFocused)
                                .lineLimit(1...4)
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? NuraColors.textSecondary : NuraColors.primary)
                                    .cornerRadius(20)
                            }
                            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatManager.isLoading)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(NuraColors.card)
                    // Full-screen paywall overlay (covers everything, including nav bar)
                    if !hasPremium {
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark) {
                            VStack(spacing: 24) {
                                Spacer()
                                Image(systemName: "sparkles")
                                    .font(.system(size: 48))
                                    .foregroundColor(NuraColors.primary)
                                    .padding(.bottom, 8)
                                Text("Unlock Nura AI Chat ✨")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                VStack(alignment: .center, spacing: 12) {
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("📸")
                                        Text("Personalized advice from your selfies")
                                            .foregroundColor(.white)
                                            .font(.body)
                                    }
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("🌦️")
                                        Text("Tips tailored to your local weather & skin type")
                                            .foregroundColor(.white)
                                            .font(.body)
                                    }
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("🤖")
                                        Text("24/7 expert answers, curated for you")
                                            .foregroundColor(.white)
                                            .font(.body)
                                    }
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("💎")
                                        Text("Feel confident in your skin, every day")
                                            .foregroundColor(.white)
                                            .font(.body)
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.horizontal, 12)
                                Text("Upgrade to Nura Premium to unlock your personal AI skin coach. Your best skin is just a tap away.")
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.976, green: 0.965, blue: 0.949))
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                                Spacer()
                                HStack(spacing: 16) {
                                    Button(action: { /* Attach payment flow later */ }) {
                                        Text("Unlock Premium")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.vertical, 12)
                                            .padding(.horizontal, 40)
                                            .background(NuraColors.primary)
                                            .cornerRadius(24)
                                            .shadow(color: NuraColors.primary.opacity(0.18), radius: 8, x: 0, y: 2)
                                    }
                                }
                                .padding(.bottom, 100)
                            }
                            .frame(maxWidth: 420)
                            .padding(.horizontal, 24)
                        }
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    }
                    // Floating premium toggle in the bottom right corner, always visible
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Toggle(isOn: $hasPremium) {
                                Text("")
                            }
                            .labelsHidden()
                            .toggleStyle(SwitchToggleStyle(tint: NuraColors.primary))
                            .padding(.trailing, 24)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            // Show the navigation title only when premium chat is active
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
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
                        .background(Color(red: 0.976, green: 0.965, blue: 0.949)) // #F9F6F2
                        .foregroundColor(.black)
                        .cornerRadius(20)
                        .cornerRadius(4, corners: [.topLeft, .topRight, .bottomLeft])
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(NuraColors.textSecondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(NuraColors.primary)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        // 5. Make the AI response bubble use a blue iMessage color
                        Text(message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(red: 0.29, green: 0.56, blue: 0.89))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .cornerRadius(4, corners: [.topLeft, .topRight, .bottomRight])
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(NuraColors.textSecondary)
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

// Add VisualEffectBlur for blur overlay
import UIKit
struct VisualEffectBlur<Content: View>: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var content: () -> Content
    class Coordinator {
        var hostingController: UIHostingController<Content>?
        init(hostingController: UIHostingController<Content>? = nil) {
            self.hostingController = hostingController
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        let hosting = UIHostingController(rootView: content())
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.contentView.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.contentView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.contentView.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.contentView.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.contentView.bottomAnchor)
        ])
        context.coordinator.hostingController = hosting
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        context.coordinator.hostingController?.rootView = content()
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatManager())
} 