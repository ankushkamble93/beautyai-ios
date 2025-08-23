import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showNuraProSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main content (chat UI and sample conversation)
                VStack {
                    let isDark = appearanceManager.colorSchemePreference == "dark" || (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark)
                    // Custom large, centered title with trailing menu
                    ZStack(alignment: .topTrailing) {
                        HStack {
                            Spacer()
                            Text("Skin Concierge")
                                .font(.largeTitle).fontWeight(.bold)
                                .padding(.top, 8)
                            Spacer()
                        }
                        Menu {
                            Button(role: .destructive) {
                                chatManager.resetChatAndMemory()
                            } label: {
                                Label("Reset Chat & Memory", systemImage: "arrow.counterclockwise")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .padding(.top, 8)
                                .padding(.trailing, 16)
                        }
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
                                        if let results = message.productResults, !results.isEmpty {
                                            ProductCardList(products: results)
                                                .padding(.horizontal)
                                        }
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
                    // Last analyzed chip
                    if let last = chatManager.memory.lastAnalysisDate {
                        HStack {
                            Text("Last analyzed on \(formatDateTime(last))")
                                .font(.caption)
                                .foregroundColor(NuraColors.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    (appearanceManager.colorSchemePreference == "dark" || (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark)) ? NuraColors.cardDark : NuraColors.card
                                )
                                .cornerRadius(14)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                    }
                    VStack(spacing: 0) {
                        Divider()
                        HStack(spacing: 12) {
                            TextField("Type your skin wish... 🪄", text: $messageText, axis: .vertical)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 20)
                                .background(isDark ? NuraColors.cardDark : Color(red: 0.976, green: 0.965, blue: 0.949)) // #F9F6F2
                                .cornerRadius(24)
                                .focused($isTextFieldFocused)
                                .lineLimit(1...4)
                                .submitLabel(.send)
                                .onSubmit { sendMessage() }
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary) : (isDark ? NuraColors.primaryDark : NuraColors.primary))
                                    .cornerRadius(20)
                            }
                            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatManager.isLoading)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                    .background(isDark ? NuraColors.cardDark : NuraColors.card)
                }
                // Full-screen paywall overlay (always topmost, covers everything, content perfectly centered)
                if userTierManager.tier == .free {
                    VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark) {
                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                VStack(spacing: 24) {
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
                                    HStack(spacing: 16) {
                                        Button(action: { showNuraProSheet = true }) {
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
                                    .padding(.top, 24)
                                }
                                .frame(maxWidth: 420)
                                .padding(.horizontal, 24)
                                Spacer()
                            }
                            .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
                    .sheet(isPresented: $showNuraProSheet) {
                        NuraProView()
                    }
                }
            }
            // Show the navigation title only when premium chat is active
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
        }
        .id(appearanceManager.colorSchemePreference)
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        chatManager.sendMessage(trimmedMessage)
        messageText = ""
        isTextFieldFocused = false
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        let isDark = appearanceManager.colorSchemePreference == "dark" || (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark)
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isDark ? NuraColors.cardDark : Color(red: 0.976, green: 0.965, blue: 0.949)) // #F9F6F2
                        .foregroundColor(isDark ? NuraColors.textPrimaryDark : .black)
                        .font(.callout)
                        .cornerRadius(20)
                        .cornerRadius(4, corners: [.topLeft, .topRight, .bottomLeft])
                        .contextMenu {
                            Button("Copy") { UIPasteboard.general.string = message.content }
                        }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(isDark ? NuraColors.primaryDark : NuraColors.primary)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        // 5. Make the AI response bubble use a blue iMessage color with light markdown rendering
                        MarkdownText(text: message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isDark ? NuraColors.primaryDark : Color(red: 0.29, green: 0.56, blue: 0.89))
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .white)
                            .font(.callout)
                            .cornerRadius(20)
                            .cornerRadius(4, corners: [.topLeft, .topRight, .bottomRight])
                            .contextMenu {
                                Button("Copy") { UIPasteboard.general.string = message.content }
                            }
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
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

// Lightweight Markdown renderer: supports **bold** and bullet points only
struct MarkdownText: View {
    let text: String
    
    var body: some View {
        let attributed = MarkdownText.parse(text)
        Text(attributed)
    }
    
    static func parse(_ input: String) -> AttributedString {
        var working = input
        // Replace markdown bullets "- " with a dot prefix
        working = working.replacingOccurrences(of: "\n- ", with: "\n• ")
        
        var attributed = AttributedString(working)
        
        // Parse **bold** - find and replace all instances
        while let startRange = attributed.range(of: "**") {
            if let endRange = attributed[startRange.upperBound...].range(of: "**") {
                let boldRange = startRange.upperBound..<endRange.lowerBound
                attributed[boldRange].inlinePresentationIntent = .stronglyEmphasized
                
                // Remove the ** markers
                attributed.removeSubrange(endRange)
                attributed.removeSubrange(startRange)
            } else {
                break
            }
        }
        
        return attributed
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