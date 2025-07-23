import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Custom large, centered title
                    HStack {
                        Spacer()
                        Text("Profile")
                            .font(.largeTitle).fontWeight(.bold)
                            .padding(.top, 8)
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                        Spacer()
                    }
                    // Profile header
                    ProfileHeaderView(isDark: isDark)
                    
                    // Quick actions
                    QuickActionsView(isDark: isDark)
                    
                    // Settings sections
                    SettingsSectionView(isDark: isDark)
                    
                    // Subscription section
                    SubscriptionSectionView(isDark: isDark)
                        .environmentObject(appearanceManager)
                        .environmentObject(authManager)
                    
                    // Support section
                    SupportSectionView(isDark: isDark)
                    
                    // Sign out button
                    SignOutButton(isDark: isDark)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
        }
        .id(appearanceManager.colorSchemePreference)
    }
    
    private var isDark: Bool { appearanceManager.colorSchemePreference == "dark" || (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark) }
}

struct ProfileHeaderView: View {
    var isDark: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingImagePicker = false
    @State private var profileImage: Image? = nil
    @State private var inputImage: UIImage? = nil
    
    var body: some View {
        VStack(spacing: 15) {
            ZStack(alignment: .topTrailing) {
                // Profile image
                if let profileImage = profileImage {
                    profileImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 4)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.pink]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                }
                // Edit icon overlay
                Button(action: { showingImagePicker = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 28, height: 28)
                            .shadow(radius: 2)
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color.purple)
                    }
                }
                .offset(x: 8, y: -8)
            }
            // User info
            VStack(spacing: 5) {
                Text(authManager.currentUser?.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                Text(authManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
            }
            // Member since
            Text("Member since \(formatDate(Date()))")
                .font(.caption)
                .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            isDark
                ? AnyView(NuraColors.cardDark)
                : AnyView(LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.blue.opacity(0.10)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal, 8)
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: $inputImage)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
    }
}

struct QuickActionsView: View {
    var isDark: Bool
    @State private var showRoutine = false
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "View Progress",
                    subtitle: "Track results",
                    icon: "chart.line.uptrend.xyaxis",
                    color: NuraColors.success
                ) {
                    // Navigation for progress will be implemented later
                }
                QuickActionCard(
                    title: "Routine",
                    subtitle: "Daily steps",
                    icon: "list.bullet",
                    color: NuraColors.secondary
                ) {
                    showRoutine = true
                }
            }
        }
        .padding()
        .background(
            isDark
                ? AnyView(NuraColors.cardDark)
                : AnyView(LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.blue.opacity(0.10)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .sheet(isPresented: $showRoutine) {
            RoutineView()
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(NuraColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsSectionView: View {
    var isDark: Bool
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSettings = false
    @State private var showingPersonalInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Personal Information",
                    subtitle: "Update your profile",
                    icon: "person.circle.fill",
                    color: NuraColors.secondary
                ) {
                    showingPersonalInfo = true
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Notifications",
                    subtitle: "Manage alerts",
                    icon: "bell.fill",
                    color: NuraColors.secondary
                ) {
                    showingSettings = false
                    showingPersonalInfo = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(
                                UIHostingController(rootView: NotificationsView()), animated: true, completion: nil)
                        }
                    }
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Privacy & Security",
                    subtitle: "Data and privacy settings",
                    icon: "lock.fill",
                    color: NuraColors.success
                ) {
                    showingSettings = false
                    showingPersonalInfo = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(
                                UIHostingController(rootView: PrivacyAndSecurityView()), animated: true, completion: nil)
                        }
                    }
                }
                
                Divider()
                    .padding(.leading, 50)
                
            }
            .background(
                isDark
                    ? AnyView(NuraColors.cardDark)
                    : AnyView(LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.blue.opacity(0.10)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingPersonalInfo) {
            PersonalInformationView()
        }
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(NuraColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(NuraColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

struct SubscriptionSectionView: View {
    var isDark: Bool
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSubscription = false
    @State private var showingAppPreferences = false
    @State private var showingPaymentMethods = false
    @State private var showingBillingHistory = false
    @State private var showingNuraPro = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Subscription")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Nura Pro",
                    subtitle: "Unlock advanced features",
                    icon: "crown.fill",
                    color: NuraColors.secondary
                ) {
                    showingNuraPro = true
                }
                .sheet(isPresented: $showingNuraPro) {
                    NuraProView()
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "App Preferences",
                    subtitle: "Customize your experience",
                    icon: "gearshape.fill",
                    color: NuraColors.textSecondary
                ) {
                    showingAppPreferences = true
                }
                .sheet(isPresented: $showingAppPreferences) {
                    AppPreferencesPageView(isPresented: $showingAppPreferences)
                        .environmentObject(appearanceManager)
                        .environmentObject(authManager)
                }
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Payment Methods",
                    subtitle: "Manage billing",
                    icon: "creditcard.fill",
                    color: NuraColors.primary
                ) {
                    showingPaymentMethods = true
                }
                .sheet(isPresented: $showingPaymentMethods) {
                    PaymentMethodsView()
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Billing History",
                    subtitle: "View past invoices",
                    icon: "doc.text.fill",
                    color: NuraColors.secondary
                ) {
                    showingBillingHistory = true
                }
                .sheet(isPresented: $showingBillingHistory) {
                    BillingHistoryView()
                }
                
                Divider()
                    .padding(.leading, 50)
                
            }
            .background(
                isDark
                    ? AnyView(NuraColors.cardDark)
                    : AnyView(LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.blue.opacity(0.10)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
    }
}

struct SupportSectionView: View {
    var isDark: Bool
    @State private var showingHelp = false
    @State private var showingHelpAndFAQ = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Support")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Help & FAQ",
                    subtitle: "Find answers",
                    icon: "questionmark.circle.fill",
                    color: NuraColors.secondary
                ) {
                    showingHelpAndFAQ = true
                }
                .sheet(isPresented: $showingHelpAndFAQ) {
                    HelpAndFAQView()
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Contact Support",
                    subtitle: "Get in touch",
                    icon: "envelope.fill",
                    color: NuraColors.success
                ) {
                    // Open email or contact form
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Rate App",
                    subtitle: "Share your feedback",
                    icon: "star.fill",
                    color: NuraColors.secondary
                ) {
                    // Open App Store rating
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "About",
                    subtitle: "Version 1.0.0",
                    icon: "info.circle.fill",
                    color: NuraColors.textSecondary
                ) {
                    // Show about page
                }
            }
            .background(
                isDark
                    ? AnyView(NuraColors.cardDark)
                    : AnyView(LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.blue.opacity(0.10)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            )
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        // .sheet(isPresented: $showingHelp) {
        //     HelpView()
        // }
    }
}

struct SignOutButton: View {
    var isDark: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Button(action: {
            authManager.signOut()
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDark ? NuraColors.errorDark.opacity(0.15) : Color.red.opacity(0.1))
            .foregroundColor(isDark ? NuraColors.errorDark : NuraColors.error)
            .cornerRadius(12)
        }
    }
}

// Placeholder views for sheets
struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Nura Premium")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Unlock advanced features and personalized recommendations")
                    .multilineTextAlignment(.center)
                    .foregroundColor(NuraColors.textSecondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Customize your Nura experience")
                    .multilineTextAlignment(.center)
                    .foregroundColor(NuraColors.textSecondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Help & FAQ")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Find answers to common questions")
                    .multilineTextAlignment(.center)
                    .foregroundColor(NuraColors.textSecondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

// Elegant, aesthetic personal info view for future user auth integration
struct PersonalInformationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var profileImage: Image? = nil
    @State private var inputImage: UIImage? = nil
    @State private var showingImagePicker = false
    @State private var isSaving = false
    @State private var saveSuccess: Bool? = nil // nil: idle, true: success, false: error
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Improved, more distinct background
                LinearGradient(
                    gradient: Gradient(colors: [NuraColors.sand, NuraColors.primary.opacity(0.25), NuraColors.secondary.opacity(0.18), NuraColors.sage.opacity(0.18)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack(spacing: 24) {
                    // Profile image edit
                    ZStack(alignment: .bottomTrailing) {
                        if let profileImage = profileImage {
                            profileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(NuraColors.primary, lineWidth: 2))
                                .shadow(radius: 4)
                                .accessibilityLabel("Profile photo")
                        } else {
                            Circle()
                                .fill(LinearGradient(gradient: Gradient(colors: [NuraColors.primary, NuraColors.secondary]), startPoint: .top, endPoint: .bottom))
                                .frame(width: 90, height: 90)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.white)
                                )
                                .accessibilityLabel("Default profile photo")
                        }
                        Button(action: { showingImagePicker = true }) {
                            ZStack {
                                Circle()
                                    .fill(NuraColors.background)
                                    .frame(width: 28, height: 28)
                                    .shadow(radius: 2)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(NuraColors.primary)
                            }
                        }
                        .accessibilityLabel("Edit profile photo")
                        .offset(x: 4, y: 4)
                    }
                    .padding(.top, 16)
                    .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                        ImagePicker(image: $inputImage)
                    }
                    
                    Text("Personal Information")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                        .accessibilityAddTraits(.isHeader)
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(NuraColors.secondary)
                            TextField("Name *", text: $name)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(10)
                                .background(NuraColors.background.opacity(0.7))
                                .cornerRadius(10)
                                .accessibilityLabel("Name")
                        }
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(NuraColors.secondary)
                            TextField("Email *", text: $email)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(10)
                                .background(NuraColors.background.opacity(0.7))
                                .cornerRadius(10)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .accessibilityLabel("Email")
                        }
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(NuraColors.secondary)
                            TextField("Phone (optional)", text: $phone)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding(10)
                                .background(NuraColors.background.opacity(0.7))
                                .cornerRadius(10)
                                .keyboardType(.phonePad)
                                .accessibilityLabel("Phone number")
                        }
                    }
                    .padding(.horizontal, 12)
                    // Save button and feedback
                    VStack(spacing: 8) {
                        Button(action: saveInfo) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: NuraColors.primary))
                                }
                                Text(isSaving ? "Saving..." : "Save")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(NuraColors.primary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isSaving)
                        .accessibilityLabel("Save personal information")
                        if let saveSuccess = saveSuccess {
                            if saveSuccess {
                                Label("Saved!", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(NuraColors.success)
                                    .accessibilityLabel("Information saved successfully")
                            } else {
                                Label(errorMessage ?? "Error saving", systemImage: "xmark.octagon.fill")
                                    .foregroundColor(NuraColors.error)
                                    .accessibilityLabel("Error saving information")
                            }
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
    }
    
    private func saveInfo() {
        // Reset feedback
        saveSuccess = nil
        errorMessage = nil
        // Validate
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            saveSuccess = false
            errorMessage = "Name required"
            return
        }
        guard isValidEmail(email) else {
            saveSuccess = false
            errorMessage = "Invalid email"
            return
        }
        // Phone is now optional, but if provided, validate
        if !phone.trimmingCharacters(in: .whitespaces).isEmpty && !isValidPhone(phone) {
            saveSuccess = false
            errorMessage = "Invalid phone"
            return
        }
        isSaving = true
        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isSaving = false
            saveSuccess = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegEx = "^\\d{7,15}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegEx)
        return phonePred.evaluate(with: phone.filter { $0.isNumber })
    }
}

// Add ImagePicker for profile photo selection
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}

struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var pushEnabled: Bool = true
    @State private var emailEnabled: Bool = false
    @State private var smsEnabled: Bool = false
    @State private var showPersonalInfoSheet: Bool = false
    // Placeholder values for now
    @State private var storedEmail: String = "user@email.com"
    @State private var storedPhone: String = "+1 555-123-4567"
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [NuraColors.sand, NuraColors.primary.opacity(0.18), NuraColors.secondary.opacity(0.12)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack(alignment: .center, spacing: 28) {
                    Text("Notifications")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                        .accessibilityAddTraits(.isHeader)
                    VStack(spacing: 18) {
                        NotificationToggleRow(
                            title: "Push Notifications",
                            subtitle: "Get alerts on your device",
                            isOn: $pushEnabled,
                            systemImage: "bell.fill"
                        )
                        VStack(spacing: 0) {
                            NotificationToggleRow(
                                title: "Email Notifications",
                                subtitle: "Receive updates via email",
                                isOn: $emailEnabled,
                                systemImage: "envelope.fill"
                            )
                            if emailEnabled {
                                AnimatedDropdown {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "envelope")
                                                .foregroundColor(NuraColors.secondary)
                                            Text(storedEmail)
                                                .font(.subheadline)
                                                .foregroundColor(NuraColors.textPrimary)
                                        }
                                        Button(action: { showPersonalInfoSheet = true }) {
                                            Text("Edit")
                                                .font(.caption)
                                                .foregroundColor(NuraColors.primary)
                                                .underline()
                                        }
                                        .padding(.leading, 28)
                                        .accessibilityLabel("Edit email")
                                    }
                                    .padding(10)
                                    .background(NuraColors.background.opacity(0.95))
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                        VStack(spacing: 0) {
                            NotificationToggleRow(
                                title: "SMS Notifications",
                                subtitle: "Text message alerts",
                                isOn: $smsEnabled,
                                systemImage: "message.fill"
                            )
                            if smsEnabled {
                                AnimatedDropdown {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "phone")
                                                .foregroundColor(NuraColors.secondary)
                                            Text(storedPhone)
                                                .font(.subheadline)
                                                .foregroundColor(NuraColors.textPrimary)
                                        }
                                        Button(action: { showPersonalInfoSheet = true }) {
                                            Text("Edit")
                                                .font(.caption)
                                                .foregroundColor(NuraColors.primary)
                                                .underline()
                                        }
                                        .padding(.leading, 28)
                                        .accessibilityLabel("Edit phone number")
                                    }
                                    .padding(10)
                                    .background(NuraColors.background.opacity(0.95))
                                    .cornerRadius(10)
                                    .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(NuraColors.card)
                    .cornerRadius(14)
                    .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $showPersonalInfoSheet) {
                PersonalInformationView()
            }
        }
    }
}

// Animated dropdown for notification details
struct AnimatedDropdown<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @State private var show: Bool = false
    var body: some View {
        VStack {
            content()
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: show)
        }
        .onAppear { show = true }
        .onDisappear { show = false }
    }
}

struct NotificationToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let systemImage: String
    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .foregroundColor(NuraColors.secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(NuraColors.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: NuraColors.primary))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint(subtitle)
        .accessibilityAddTraits(.isButton)
    }
}

struct PrivacyAndSecurityView: View {
    @Environment(\.dismiss) var dismiss
    @State private var trackingEnabled: Bool = false
    @State private var showDeleteAlert: Bool = false
    var onDeleteAccount: (() -> Void)? = nil // for easy backend connection
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [NuraColors.sand, NuraColors.sage.opacity(0.18), NuraColors.primary.opacity(0.12)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                VStack(alignment: .center, spacing: 28) {
                    Text("Privacy & Security")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                        .accessibilityAddTraits(.isHeader)
                    // App Tracking
                    VStack(alignment: .center, spacing: 8) {
                        Text("Allow App Tracking")
                            .font(.headline)
                        Toggle(isOn: $trackingEnabled) {
                            EmptyView()
                        }
                        .toggleStyle(SwitchToggleStyle(tint: NuraColors.primary))
                        .accessibilityLabel("Allow App Tracking")
                        .frame(maxWidth: 80)
                        .padding(.bottom, 2)
                        Text("Let Nura use Apple's App Tracking Transparency to personalize your experience. You can change this anytime in your device settings.")
                            .font(.caption)
                            .foregroundColor(NuraColors.textSecondary)
                            .multilineTextAlignment(.center)
                        Text("Legal: We respect your privacy. Your data is never sold. See our Privacy Policy for details.")
                            .font(.caption2)
                            .foregroundColor(NuraColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(NuraColors.card)
                    .cornerRadius(12)
                    // Data Download/Export
                    VStack(alignment: .center, spacing: 8) {
                        Text("Download Your Data")
                            .font(.headline)
                        Text("Request a copy of your personal data stored with Nura. We'll email you a download link.")
                            .font(.caption)
                            .foregroundColor(NuraColors.textSecondary)
                            .multilineTextAlignment(.center)
                        Button(action: {/* TODO: Implement data export */}) {
                            Text("Request Data Export")
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(NuraColors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Request Data Export")
                    }
                    .padding()
                    .background(NuraColors.card)
                    .cornerRadius(12)
                    // Delete Account
                    VStack(alignment: .center, spacing: 8) {
                        Text("Delete My Account")
                            .font(.headline)
                            .foregroundColor(NuraColors.errorStrong)
                        Text("Permanently delete your account and all associated data. This action cannot be undone.")
                            .font(.caption)
                            .foregroundColor(NuraColors.errorStrong.opacity(0.8))
                            .multilineTextAlignment(.center)
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Text("Delete Account")
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(NuraColors.errorStrong)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .accessibilityLabel("Delete Account")
                        .alert(isPresented: $showDeleteAlert) {
                            Alert(
                                title: Text("Delete Account?"),
                                message: Text("Are you sure you want to permanently delete your account? This cannot be undone."),
                                primaryButton: .destructive(Text("Delete"), action: {
                                    onDeleteAccount?()
                                }),
                                secondaryButton: .cancel()
                            )
                        }
                    }
                    .padding()
                    .background(NuraColors.card)
                    .cornerRadius(12)
                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// 1. Create AppPreferencesPageView as a NavigationLink destination
struct AppPreferencesPageView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isPresented: Bool
    @State private var tempColorSchemePreference: String = "system"
    @State private var showSaved: Bool = false
    let colorOptions = ["light": "Light", "dark": "Dark", "system": "System Default"]
    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        _tempColorSchemePreference = State(initialValue: UserDefaults.standard.string(forKey: "colorSchemePreference") ?? "system")
    }
    var body: some View {
        VStack(alignment: .center, spacing: 28) {
            Text("App Preferences")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 16)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
                .animation(.easeInOut, value: tempColorSchemePreference)
            Text("Dark mode reduces eye strain and saves battery in low-light environments. Choose your preferred appearance below.")
                .font(.subheadline)
                .foregroundColor(tempColorSchemePreference == "dark" ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .animation(.easeInOut, value: tempColorSchemePreference)
            VStack(spacing: 18) {
                VStack(spacing: 16) {
                    AppearanceSwitchRow(
                        title: "Light",
                        icon: "sun.max.fill",
                        isOn: tempColorSchemePreference == "light",
                        color: NuraColors.primary,
                        onTap: { tempColorSchemePreference = "light" }
                    )
                    AppearanceSwitchRow(
                        title: "Dark",
                        icon: "moon.fill",
                        isOn: tempColorSchemePreference == "dark",
                        color: NuraColors.accentDark,
                        onTap: { tempColorSchemePreference = "dark" }
                    )
                    AppearanceSwitchRow(
                        title: "System Default",
                        icon: "circle.lefthalf.filled",
                        isOn: tempColorSchemePreference == "system",
                        color: NuraColors.secondary,
                        onTap: { tempColorSchemePreference = "system" }
                    )
                }
                .padding(.vertical, 8)
                .background(tempColorSchemePreference == "dark" ? NuraColors.cardDark : NuraColors.card)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                .accessibilityElement(children: .combine)
                .accessibilityHint("Choose between light, dark, or system default appearance.")
                .animation(.easeInOut, value: tempColorSchemePreference)
                // Info/warning message for logout
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                        .font(.title3)
                    Text("For your changes to take effect, you will be signed out and must log in again after saving your appearance settings.")
                        .font(.footnote)
                        .foregroundColor(NuraColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                .padding(10)
                .background(NuraColors.card.opacity(0.7))
                .cornerRadius(8)
                .padding(.bottom, 4)
                Button(action: {
                    if appearanceManager.colorSchemePreference != tempColorSchemePreference {
                        appearanceManager.colorSchemePreference = tempColorSchemePreference
                        showSaved = true
                        // Haptic feedback
                        #if canImport(UIKit)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        #endif
                        // Show 'Saved!' animation, then log out after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            showSaved = false
                            authManager.signOut() // Log out the user after showing 'Saved!'
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(tempColorSchemePreference == "dark" ? NuraColors.primaryDark : NuraColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 8)
                .accessibilityLabel("Save app preferences")
                .disabled(appearanceManager.colorSchemePreference == tempColorSchemePreference)
                if showSaved {
                    Label("Saved!", systemImage: "checkmark.circle.fill")
                        .foregroundColor(tempColorSchemePreference == "dark" ? NuraColors.successDark : NuraColors.success)
                }
            }
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Custom row for appearance switches
struct AppearanceSwitchRow: View {
    let title: String
    let icon: String
    let isOn: Bool
    let color: Color
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                    .frame(width: 32)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isOn ? color : Color.gray.opacity(0.2))
                        .frame(width: 44, height: 28)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .offset(x: isOn ? 8 : -8)
                        .shadow(radius: 1)
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isOn)
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(isOn ? color.opacity(0.08) : Color.clear)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "Selected" : "Not selected")
    }
}

// UX/PM suggestions:
// - Consider adding a "System Default" option for color scheme
// - Add a short description about dark mode benefits
// - Optionally, allow previewing dark mode before saving
// - Add haptic feedback on save for delight
// - Make sure all text/buttons have sufficient contrast in both modes
// - Consider accessibility: larger text, VoiceOver labels, etc.

#Preview {
    AppPreferencesPageView(isPresented: .constant(true))
        .environmentObject(AppearanceManager())
        .environmentObject(AuthenticationManager())
} 