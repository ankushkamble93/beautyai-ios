import SwiftUI
import PhotosUI

// MARK: - Contact Support View

struct ContactSupportView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var message: String = ""
    @State private var isSending: Bool = false
    @State private var sent: Bool = false
    @State private var showFAQ: Bool = false
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var attachedImage: UIImage? = nil
    @FocusState private var messageFocused: Bool
    @State private var showSuccessAnimation: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var showReplyInfo: Bool = false
    @State private var hasSentToday: Bool = false
    @State private var lastSendDate: String = ""
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
    private var accent: Color { Color(red: 0.93, green: 0.80, blue: 0.80) } // blush
    private var peach: Color { Color(red: 1.0, green: 0.92, blue: 0.88) } // soft peach
    private var offWhite: Color { Color(red: 0.98, green: 0.97, blue: 0.95) }
    private var charcoal: Color { Color(red: 0.13, green: 0.12, blue: 0.11) }
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? [charcoal, Color.black] : [offWhite, peach]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: 12)
                        // Header
                        VStack(spacing: 8) {
                            Text("Need a hand?")
                                .font(.largeTitle).fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? offWhite : charcoal)
                                .padding(.top, 8)
                            Text("We're here for anything—product advice, account issues, or life crises.")
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? accent.opacity(0.85) : .secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 18)
                    // Quick Actions
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            PillButton(
                                title: "Chat with us (Coming Soon)",
                                color: colorScheme == .dark ? Color(red: 0.95, green: 0.72, blue: 0.80).opacity(0.18) : accent,
                                icon: "bubble.left.and.bubble.right.fill",
                                minWidth: 170,
                                fullWidth: false
                            ) {
                                showChatComingSoon()
                            }
                            PillButton(
                                title: "Email support",
                                color: colorScheme == .dark ? Color(red: 1.0, green: 0.85, blue: 0.75).opacity(0.18) : peach,
                                icon: "envelope.fill",
                                minWidth: 170,
                                fullWidth: false
                            ) {
                                openEmailSupport()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        HStack {
                            PillButton(
                                title: "Troubleshoot yourself",
                                color: colorScheme == .dark ? Color(red: 0.60, green: 0.68, blue: 0.95).opacity(0.18) : Color(red: 0.93, green: 0.90, blue: 0.98),
                                icon: "questionmark.circle",
                                minWidth: 350,
                                fullWidth: false
                            ) {
                                showFAQ = true
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 18)
                    // Subtle form
                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Name", text: $name)
                                .padding(12)
                                .background(cardBackground)
                                .cornerRadius(10)
                                .foregroundColor(.primary)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Email", text: .constant(email))
                                .padding(12)
                                .background(cardBackground)
                                .cornerRadius(10)
                                .foregroundColor(.secondary)
                                .disabled(true)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Message")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ZStack(alignment: .topLeading) {
                                if message.isEmpty {
                                    Text("How can we help?")
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 18)
                                }
                                TextEditor(text: $message)
                                    .frame(minHeight: 80, maxHeight: 180)
                                    .padding(10)
                                    .background(cardBackground)
                                    .cornerRadius(10)
                                    .foregroundColor(.primary)
                                    .focused($messageFocused)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(messageFocused ? accent : Color.clear, lineWidth: 1.5)
                                            .animation(.easeInOut(duration: 0.3), value: messageFocused)
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: messageFocused)
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Attach screenshot (optional)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 10) {
                                PhotosPicker(selection: $selectedImage, matching: .images) {
                                    HStack {
                                        Image(systemName: "paperclip")
                                        Text(attachedImage == nil ? "Upload file" : "Change file")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(colorScheme == .dark ? Color(red: 0.98, green: 0.85, blue: 0.90) : accent)
                                    .frame(minWidth: 180, maxWidth: .infinity, minHeight: 36, maxHeight: 36)
                                    .background(
                                        colorScheme == .dark
                                            ? Color(red: 0.98, green: 0.85, blue: 0.90).opacity(0.22)
                                            : accent.opacity(0.22)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(colorScheme == .dark ? Color(red: 0.98, green: 0.85, blue: 0.90).opacity(0.45) : accent.opacity(0.45), lineWidth: 1.2)
                                    )
                                    .cornerRadius(18)
                                }
                                if let img = attachedImage {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 38, height: 38)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent, lineWidth: 1))
                                        .shadow(radius: 2)
                                }
                            }
                        }
                        if sent {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill").foregroundColor(.green)
                                Text("Message sent! We'll get back to you soon.")
                                    .font(.footnote)
                                    .foregroundColor(.green)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(18)
                    .background(cardBackground)
                    .cornerRadius(18)
                    .shadow(color: colorScheme == .dark ? .black.opacity(0.12) : .gray.opacity(0.08), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 10)
                    // Microcopy - only show after email submission
                    if showReplyInfo {
                        VStack(spacing: 4) {
                            Text("We usually reply within a few hours.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            Text("Live chat and phone support coming soon!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Send button with card stack appearance and slide-up functionality
                    if hasSentToday {
                        // Daily limit reached - show message instead of send button
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Message sent today!")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("You can submit another request tomorrow")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(cardBackground)
                            .cornerRadius(18)
                            .shadow(color: colorScheme == .dark ? .black.opacity(0.12) : .gray.opacity(0.08), radius: 10, x: 0, y: 4)
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 20) // Extra bottom padding to ensure visibility
                    } else {
                        SlideUpSendButton(
                            isEnabled: !message.isEmpty && !isSending,
                            isSending: isSending,
                            sent: sent,
                            dragOffset: $dragOffset,
                            isDragging: $isDragging,
                            onSend: sendMessage,
                            colorScheme: colorScheme,
                            accent: accent
                        )
                        .padding(.horizontal, 8)
                        .padding(.bottom, 0)
                    }
                    }
                    .padding(.bottom, 20) // Ensure bottom content is fully visible
                }
                .sheet(isPresented: $showFAQ) {
                    HelpAndFAQView()
                }
                // Success animation overlay
                if showSuccessAnimation {
                    SuccessAnimationOverlay()
                        .transition(.opacity.combined(with: .scale))
                        .zIndex(1000)
                        .animation(.easeInOut(duration: 0.3), value: showSuccessAnimation)
                }
            }
            .onChange(of: selectedImage, initial: false) { oldItem, newItem in
                    if let newItem {
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                                attachedImage = uiImage
                            }
                        }
                    }
                }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Done") { dismiss() })
            .onAppear {
                loadUserInformation()
                checkDailySendLimit()
            }
        }
        }
    
    func sendMessage() {
        guard !message.isEmpty && !hasSentToday else { return }
        isSending = true
        sent = false
        
        // Use native email approach for better reliability and simpler UX
        openNativeEmailSupport()
        
        // Simulate success for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSending = false
            sent = true
            message = ""
            attachedImage = nil
            selectedImage = nil
            
            // Mark as sent today
            markAsSentToday()
            
            // Show reply info with animation
            withAnimation(.easeInOut(duration: 0.5)) {
                showReplyInfo = true
            }
            
            // Show success animation
            showSuccessAnimation = true
            
            // Hide success animation after 2.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                showSuccessAnimation = false
                sent = false
            }
        }
    }
    
    // MARK: - Native Email Support (Simplified Approach)
    
    // MARK: - Daily Send Limit Management
    
    private func checkDailySendLimit() {
        let today = getCurrentDateString()
        let lastSend = UserDefaults.standard.string(forKey: "lastSendDate") ?? ""
        
        if lastSend == today {
            hasSentToday = true
        } else {
            hasSentToday = false
            // Clear old data if it's a new day
            if !lastSend.isEmpty {
                UserDefaults.standard.removeObject(forKey: "lastSendDate")
            }
        }
    }
    
    private func markAsSentToday() {
        let today = getCurrentDateString()
        UserDefaults.standard.set(today, forKey: "lastSendDate")
        hasSentToday = true
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // MARK: - User Information Loading
    
    private func loadUserInformation() {
        // Load user information from AuthenticationManager
        if let session = AuthenticationManager.shared.session {
            let user = session.user
            
            // Set email from session
            email = user.email ?? ""
            
            // Try to get name from user metadata
            let userMetadata = user.userMetadata
            if let userName = userMetadata["name"]?.stringValue {
                name = userName
            } else if let fullName = userMetadata["full_name"]?.stringValue {
                name = fullName
            } else if let givenName = userMetadata["given_name"]?.stringValue,
                      let familyName = userMetadata["family_name"]?.stringValue {
                name = "\(givenName) \(familyName)"
            } else {
                // Fallback to email prefix if no name found
                name = email.components(separatedBy: "@").first ?? "User"
            }
        } else {
            // Fallback values for unauthenticated users
            name = "Guest User"
            email = "guest@nura.app"
        }
    }
    
    // MARK: - Support Actions
    
    func openEmailSupport() {
        openNativeEmailSupport()
    }
    
    func openNativeEmailSupport() {
        let email = "nura.assistance@gmail.com"
        let subject = "Nura Support Request - \(name)"
        
        // Get device info for better support
        let deviceInfo = getDeviceInfo()
        
        let body = """
        Hello Nura Support Team,
        
        \(message.isEmpty ? "I need help with the following:\n\n[Please describe your issue here]" : message)
        
        ---
        User Information:
        Name: \(name)
        Email: \(email)
        
        Device Information:
        \(deviceInfo)
        
        ---
        This message was sent from the Nura iOS app.
        """
        
        if let url = createEmailURL(to: email, subject: subject, body: body) {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback: Copy email to clipboard and show alert
                    DispatchQueue.main.async {
                        UIPasteboard.general.string = email
                        showEmailCopiedAlert()
                    }
                }
            }
        } else {
            // Fallback: Copy email to clipboard
            UIPasteboard.general.string = email
            showEmailCopiedAlert()
        }
    }
    
    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        let systemVersion = device.systemVersion
        let model = device.model
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        return """
        Device: \(model)
        iOS Version: \(systemVersion)
        App Version: \(appVersion) (\(buildNumber))
        """
    }
    
    func showChatComingSoon() {
        // Show coming soon alert with alternative options
        let alert = UIAlertController(
            title: "Chat Coming Soon! 💬",
            message: "We're working on live chat support. For now, please use email support or check our FAQ section for quick answers.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Email Support", style: .default) { _ in
            openEmailSupport()
        })
        
        alert.addAction(UIAlertAction(title: "Browse FAQ", style: .default) { _ in
            showFAQ = true
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        presentAlert(alert)
    }
    
    func openChatSupport() {
        // This will be used when chat is implemented
        let chatURL = "https://nura.app/chat" // Replace with actual chat URL
        if let url = URL(string: chatURL) {
            UIApplication.shared.open(url)
        } else {
            // Fallback: Show chat info
            showChatInfoAlert()
        }
    }
    
    private func createEmailURL(to: String, subject: String, body: String) -> URL? {
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "mailto:\(to)?subject=\(encodedSubject)&body=\(encodedBody)"
        return URL(string: urlString)
    }
    
    private func showEmailCopiedAlert() {
        let alert = UIAlertController(
            title: "Email Copied! 📧",
            message: "The support email address has been copied to your clipboard. You can paste it in your email app.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Mail App", style: .default) { _ in
            if let mailURL = URL(string: "mailto:nura.assistance@gmail.com") {
                UIApplication.shared.open(mailURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        presentAlert(alert)
    }
    
    private func showChatInfoAlert() {
        // Show chat availability and contact info
        print("💬 Chat support info displayed")
    }
    
    private func showEmailFallbackAlert(error: Error) {
        let alert = UIAlertController(
            title: "Email Service Unavailable 📧",
            message: "We couldn't send your message directly. Would you like to open your email app instead?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Email App", style: .default) { _ in
            openEmailSupport()
        })
        
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
            // User can try sending again
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        presentAlert(alert)
    }

    // MARK: - Alert Presentation Helper
    private func presentAlert(_ alert: UIAlertController) {
        DispatchQueue.main.async {
            guard let rootViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow })?.rootViewController else { return }
            let top = topViewController(from: rootViewController)
            // Avoid stacking multiple alerts
            if top is UIAlertController {
                print("⚠️ Skipping alert presentation: another alert is already visible")
                return
            }
            top.present(alert, animated: true)
        }
    }

    private func topViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigation = root as? UINavigationController, let visible = navigation.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return root
    }

}

struct PillButton: View {
    let title: String
    let color: Color
    let icon: String?
    var minWidth: CGFloat = 0
    var fullWidth: Bool = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.subheadline).fontWeight(.semibold)
            }
            .padding(.vertical, 12)
            .frame(minWidth: minWidth, maxWidth: fullWidth ? .infinity : nil)
            .background(color)
            .foregroundColor(.primary)
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.primary.opacity(0.13), lineWidth: 1.2)
            )
            .shadow(color: color.opacity(0.10), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.18), value: UUID())
    }
}

// MARK: - Slide Up Send Button Component
struct SlideUpSendButton: View {
    let isEnabled: Bool
    let isSending: Bool
    let sent: Bool
    @Binding var dragOffset: CGFloat
    @Binding var isDragging: Bool
    let onSend: () -> Void
    let colorScheme: ColorScheme
    let accent: Color
    
    private let slideThreshold: CGFloat = 37 // About 1 inch
    
    var body: some View {
        ZStack {
            // Single cohesive button with stretching background
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    isEnabled
                        ? LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color(red: 0.55, green: 0.63, blue: 0.90) : Color(red: 0.90, green: 0.75, blue: 0.75),
                                colorScheme == .dark ? Color(red: 0.45, green: 0.53, blue: 0.80) : Color(red: 0.80, green: 0.65, blue: 0.65)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? Color.gray.opacity(0.25) : accent.opacity(0.25),
                                colorScheme == .dark ? Color.gray.opacity(0.15) : accent.opacity(0.15)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
                .frame(height: max(52 + 34, 52 + 34 + abs(dragOffset)))
                .ignoresSafeArea(.container, edges: .bottom)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            isEnabled
                                ? (colorScheme == .dark ? Color.white.opacity(0.15) : Color.white.opacity(0.2))
                                : Color.clear,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: (colorScheme == .dark ? Color(red: 0.50, green: 0.58, blue: 0.85) : Color(red: 0.85, green: 0.70, blue: 0.70)).opacity(0.4),
                    radius: isDragging ? 12 : 8,
                    x: 0,
                    y: isDragging ? 8 : 4
                )
                .scaleEffect(isDragging ? 1.02 : 1.0)
            
            // Content with dynamic positioning - sticks to top of stretching background
            VStack(spacing: 0) {
                // Dynamic content that moves with the stretching background
                HStack {
                    if isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else if sent {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(sent ? 1.2 : 1.0)
                    } else {
                        Text("Send")
                            .font(.title3).fontWeight(.semibold)
                            .foregroundColor(isEnabled ? .white : .secondary)
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(isEnabled ? .white.opacity(0.8) : .secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12) // Match horizontal padding for better visual balance
                
                // Spacer to fill remaining space
                Spacer()
            }
        }
        .scaleEffect(isSending ? 0.97 : 1.0)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if isEnabled && !isSending && !sent {
                        isDragging = true
                        // Simple upward movement - no complex animations
                        dragOffset = min(0, value.translation.height)
                        
                        // Single haptic feedback at threshold
                        if dragOffset < -slideThreshold && dragOffset > -slideThreshold - 5 {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
                    }
                }
                .onEnded { value in
                    if isEnabled && !isSending && !sent {
                        isDragging = false
                        
                        // Check if slide threshold was reached
                        if value.translation.height < -slideThreshold {
                            // Trigger send
                            onSend()
                            
                            // Success haptic feedback
                            let successFeedback = UINotificationFeedbackGenerator()
                            successFeedback.notificationOccurred(.success)
                        }
                        
                        // Simple reset - no animation to avoid system overload
                        dragOffset = 0
                    }
                }
        )
        .onTapGesture {
            if isEnabled && !isSending && !sent {
                onSend()
            }
        }
    }
}

// MARK: - Success Animation Overlay
struct SuccessAnimationOverlay: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.green, lineWidth: 4)
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.green)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .rotationEffect(.degrees(rotation))
                }
                
                Text("Email Sent!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    ContactSupportView()
} 