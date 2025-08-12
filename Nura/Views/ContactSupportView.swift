import SwiftUI
import PhotosUI

struct ContactSupportView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = "Jane Doe" // Replace with user info if available
    @State private var email: String = "jane@nura.app" // Replace with user info if available
    @State private var message: String = ""
    @State private var isSending: Bool = false
    @State private var sent: Bool = false
    @State private var showFAQ: Bool = false
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var attachedImage: UIImage? = nil
    @FocusState private var messageFocused: Bool
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
                VStack(spacing: 0) {
                    Spacer(minLength: 12)
                    // Header
                    VStack(spacing: 8) {
                        Text("Need a hand?")
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? offWhite : charcoal)
                            .padding(.top, 8)
                        Text("We’re here for anything—product advice, account issues, or life crises.")
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
                    // Microcopy
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
                    // Send button
                    Button(action: sendMessage) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    message.isEmpty
                                        ? (colorScheme == .dark ? Color.gray.opacity(0.18) : accent.opacity(0.18))
                                        : (colorScheme == .dark ? Color(red: 0.60, green: 0.68, blue: 0.95) : accent)
                                )
                                .frame(height: 52)
                                .shadow(color: (colorScheme == .dark ? Color(red: 0.60, green: 0.68, blue: 0.95) : accent).opacity(0.18), radius: 6, x: 0, y: 2)
                            if isSending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else if sent {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .scaleEffect(sent ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: sent)
                            } else {
                                Text("Send")
                                    .font(.title3).fontWeight(.semibold)
                                    .foregroundColor(message.isEmpty ? .secondary : .white)
                            }
                        }
                    }
                    .disabled(message.isEmpty || isSending)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 18)
                    .scaleEffect(isSending ? 0.97 : 1.0)
                    .animation(.easeInOut(duration: 0.18), value: isSending)
                    Spacer()
                }
                .sheet(isPresented: $showFAQ) {
                    HelpAndFAQView()
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Done") { dismiss() })
        }
    }
    func sendMessage() {
        guard !message.isEmpty else { return }
        isSending = true
        sent = false
        // Simulate send delay and animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isSending = false
            sent = true
            message = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                sent = false
            }
        }
    }
    
    // MARK: - Support Actions
    
    func openEmailSupport() {
        let email = "nura.help@gmail.com"
        let subject = "Nura Support Request"
        
        // Get device info for better support
        let deviceInfo = getDeviceInfo()
        
        let body = """
        Hello Nura Support Team,
        
        I need help with the following:
        
        [Please describe your issue here]
        
        ---
        User Information:
        Name: \(name)
        Email: \(email)
        
        Device Information:
        \(deviceInfo)
        
        ---
        Please provide as much detail as possible about your issue.
        """
        
        if let url = createEmailURL(to: email, subject: subject, body: body) {
            UIApplication.shared.open(url)
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
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
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
            if let mailURL = URL(string: "mailto:nura.help@gmail.com") {
                UIApplication.shared.open(mailURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alert, animated: true)
        }
    }
    
    private func showChatInfoAlert() {
        // Show chat availability and contact info
        print("💬 Chat support info displayed")
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

#Preview {
    ContactSupportView()
} 