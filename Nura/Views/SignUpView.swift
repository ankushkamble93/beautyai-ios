import SwiftUI
import Supabase

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var agreeToTerms = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showSuccess = false
    @State private var showPasswordRequirements = false
    @State private var countdownSeconds = 0
    @State private var isCountdownActive = false
    @State private var showEmailError = false
    @State private var showEmailErrorBubble = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    @State private var showEmailVerification = false
    @FocusState private var focusedField: Field?
    
    // Loading state for sign-up
    @State private var isSignUpLoading = false
    
    // Email availability check states
    @State private var isCheckingEmail = false
    @State private var emailExists = false
    @State private var emailCheckTimer: Timer?
    

    
    enum Field { case name, email, password, confirmPassword }
    
    // Password requirements
    var isLongEnough: Bool { password.count >= 8 }
    var hasUpper: Bool { password.rangeOfCharacter(from: .uppercaseLetters) != nil }
    var hasLower: Bool { password.rangeOfCharacter(from: .lowercaseLetters) != nil }
    var hasNumber: Bool { password.rangeOfCharacter(from: .decimalDigits) != nil }
    var hasSymbol: Bool { password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':,./<>?")) != nil }
    var passwordsMatch: Bool { password == confirmPassword && !password.isEmpty }
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    var canSignUp: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
        !email.isEmpty && 
        isEmailValid && 
        !emailExists && 
        isLongEnough && 
        hasUpper && 
        hasLower && 
        hasNumber && 
        hasSymbol && 
        passwordsMatch && 
        agreeToTerms
    }

    
    var buttonText: String {
        if isLoading {
            return "Creating Account..."
        } else if isCountdownActive {
            return "Sign Up"
        } else {
            return "Sign Up"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                                    ZStack {
                        AnimatedGradientBackground()
                        // Soft vignette for depth
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black.opacity(0.12), Color.clear, Color.black.opacity(0.12)]),
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
                    VStack(spacing: 0) {
                    HStack {
                        Button(action: { 
                            isPresented = false
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(NuraColors.primary)
                                .padding(8)
                                .background(Circle().fill(NuraColors.card))
                        }
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.horizontal)
                    
                    // Clean title design
                    VStack(spacing: 12) {
                        Text("Create your account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 8) {
                            Text("Join Nura to:")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            
                            HStack(spacing: 32) {
                                VStack(spacing: 6) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.system(size: 18))
                                        .foregroundColor(NuraColors.primary)
                                    Text("Track Your Skin")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                
                                VStack(spacing: 6) {
                                    Image(systemName: "lightbulb")
                                        .font(.system(size: 18))
                                        .foregroundColor(NuraColors.primary)
                                    Text("Get Insights")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                
                                VStack(spacing: 6) {
                                    Image(systemName: "heart")
                                        .font(.system(size: 18))
                                        .foregroundColor(NuraColors.primary)
                                    Text("Feel Great")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                    
                    // Original Sign Up Form
                        VStack(spacing: 20) {
                            // Accent card header
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(NuraColors.primary)
                                Text("Let’s get you set up in under a minute")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            // Name field (required)
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(NuraColors.primary)
                                TextField("Name", text: $name)
                                    .textFieldStyle(.plain)
                                    .focused($focusedField, equals: .name)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.words)
                            }
                            .padding(14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.10)]),
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                            
                            // Email field with error bubble
                            VStack(spacing: 4) {
                                if showEmailErrorBubble {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(NuraColors.error)
                                            .font(.system(size: 12))
                                        Text("Email \"\(email)\" is invalid")
                                            .font(.caption)
                                            .foregroundColor(NuraColors.error)
                                        Spacer()
                                        Button(action: { showEmailErrorBubble = false }) {
                                            Image(systemName: "xmark")
                                                .foregroundColor(NuraColors.error)
                                                .font(.system(size: 10))
                                        }
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(NuraColors.error.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(NuraColors.error.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                if emailExists && focusedField != .email {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(NuraColors.error)
                                            .font(.system(size: 12))
                                        Text("An account with this email already exists")
                                            .font(.caption)
                                            .foregroundColor(NuraColors.error)
                                        Spacer()
                                        Button(action: { 
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                emailExists = false
                                            }
                                        }) {
                                            Image(systemName: "xmark")
                                                .foregroundColor(NuraColors.error)
                                                .font(.system(size: 10))
                                        }
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(NuraColors.error.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(NuraColors.error.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                if !email.isEmpty && isEmailValid && !emailExists && !isCheckingEmail && focusedField != .email {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(NuraColors.success)
                                            .font(.system(size: 12))
                                        Text("Email is available")
                                            .font(.caption)
                                            .foregroundColor(NuraColors.success)
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(NuraColors.success.opacity(0.1))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(NuraColors.success.opacity(0.3), lineWidth: 1)
                                            )
                                    )
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(NuraColors.primary)
                                    TextField("Email", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .textFieldStyle(.plain)
                                        .focused($focusedField, equals: .email)
                                        .onChange(of: email) { oldValue, newValue in
                                            showEmailError = false
                                            showEmailErrorBubble = false
                                            emailExists = false
                                            
                                            // Convert to lowercase to prevent case sensitivity issues
                                            if newValue != newValue.lowercased() {
                                                email = newValue.lowercased()
                                            }
                                            
                                            // Debounced email availability check
                                            checkEmailAvailability()
                                        }
                                    
                                    // Email availability status indicator
                                    if isCheckingEmail {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .foregroundColor(NuraColors.primary)
                                    } else if emailExists {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(NuraColors.error)
                                            .font(.system(size: 16))
                                    } else if !email.isEmpty && isEmailValid && !emailExists {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(NuraColors.success)
                                            .font(.system(size: 16))
                                    }
                                    
                                    if showEmailError {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                showEmailErrorBubble.toggle()
                                            }
                                        }) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(NuraColors.error)
                                                .font(.system(size: 16))
                                        }
                                    }
                                }
                                .padding(14)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.10)]),
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(getEmailFieldBorderColor(), lineWidth: getEmailFieldBorderWidth())
                                )
                                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                            }
                            
                            // Password field
                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(NuraColors.primary)
                                CustomPasswordField(
                                    text: $password,
                                    placeholder: "Password",
                                    showPassword: showPassword
                                )
                                .focused($focusedField, equals: .password)
                                .onTapGesture {
                                    focusedField = .password
                                }
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.10)]),
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                            .onTapGesture { showPasswordRequirements = true }
                            
                            // Confirm Password field
                            HStack {
                                Image(systemName: "lock.rotation")
                                    .foregroundColor(NuraColors.primary)
                                CustomPasswordField(
                                    text: $confirmPassword,
                                    placeholder: "Confirm Password",
                                    showPassword: showConfirmPassword
                                )
                                .focused($focusedField, equals: .confirmPassword)
                                .onTapGesture {
                                    focusedField = .confirmPassword
                                }
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(14)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.10)]),
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
                            
                            // Password match indicator
                            if passwordsMatch && !confirmPassword.isEmpty {
                                Text("Passwords match!")
                                    .foregroundColor(NuraColors.success)
                                    .font(.caption.bold())
                                    .transition(.opacity)
                            } else if !passwordsMatch && !confirmPassword.isEmpty {
                                Text("Passwords do not match")
                                    .foregroundColor(NuraColors.error)
                                    .font(.caption)
                                    .transition(.opacity)
                            }
                            
                            // Password requirements
                            if showPasswordRequirements || focusedField == .password {
                                PasswordRequirementsView(
                                    isLongEnough: isLongEnough,
                                    hasUpper: hasUpper,
                                    hasLower: hasLower,
                                    hasNumber: hasNumber,
                                    hasSymbol: hasSymbol
                                )
                                .padding(.top, 2)
                            }
                            
                            Spacer(minLength: 0)
                            
                            // Terms agreement and Sign Up button - moved down
                            VStack(spacing: 16) {
                                // Terms agreement with fixed clickability
                                Button(action: { agreeToTerms.toggle() }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: agreeToTerms ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(agreeToTerms ? NuraColors.success : .gray)
                                            .font(.system(size: 16))
                                        Text("I agree to the ")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Link("Terms", destination: URL(string: "https://nura.com/terms")!)
                                            .font(.subheadline)
                                            .foregroundColor(NuraColors.primary)
                                        Text(" and ")
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Link("Privacy Policy", destination: URL(string: "https://nura.com/privacy")!)
                                            .font(.subheadline)
                                            .foregroundColor(NuraColors.primary)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.vertical, 8)
                                
                                // Sign Up button with countdown
                                Button(action: signUp) {
                                    VStack(spacing: 4) {
                                        HStack(spacing: 8) {
                                            if isLoading {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.8)
                                            }
                                            Text(buttonText)
                                                .fontWeight(.semibold)
                                        }
                                        
                                        if isCountdownActive && countdownSeconds > 0 {
                                            Text("try again in \(countdownSeconds) seconds")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.8))
                                                .underline()
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: canSignUp && !isLoading && !isCountdownActive ? [NuraColors.primary, NuraColors.primary.opacity(0.85)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.25)]),
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(canSignUp && !isLoading && !isCountdownActive ? 0.25 : 0.12), lineWidth: 1)
                                    )
                                    .shadow(
                                        color: canSignUp && !isLoading && !isCountdownActive
                                            ? NuraColors.primary.opacity(0.35) 
                                            : .clear, 
                                        radius: 10, x: 0, y: 3
                                    )
                                }
                                                                    .disabled(!canSignUp || isLoading || isCountdownActive)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    
                    // Success/Error banner
                    if showSuccessMessage {
                        HStack {
                            Image(systemName: successMessage.contains("successfully") ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(successMessage.contains("successfully") ? .green : NuraColors.error)
                            Text(successMessage)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Button(action: { showSuccessMessage = false }) {
                                Image(systemName: "xmark")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(successMessage.contains("successfully") ? Color.green.opacity(0.1) : NuraColors.error.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(successMessage.contains("successfully") ? Color.green.opacity(0.3) : NuraColors.error.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    
                    // Decorative bottom illustration
                    VStack(spacing: 0) {
                        Divider().padding(.horizontal, 60)
                        Image(systemName: "leaf")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .foregroundColor(NuraColors.sage)
                            .opacity(0.18)
                        Text("Nura cares about your privacy and security.")
                            .font(.footnote)
                            .foregroundColor(NuraColors.textSecondary)
                            .padding(.bottom, 18)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showEmailVerification) {
                EmailVerificationView(
                    isPresented: $showEmailVerification,
                    email: email,
                    password: password,
                    name: name
                )
                .environmentObject(authManager)
            }
        }
    
    private func signUp() {
        self.errorMessage = nil
        self.showSuccess = false
        guard canSignUp else { return }
        
        // Double-check email availability before proceeding
        guard !emailExists else {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.successMessage = "An account with this email already exists. Please use a different email or sign in."
                self.showSuccessMessage = true
            }
            return
        }
        
        self.isLoading = true
        
        // Normalize email to lowercase to prevent case sensitivity issues
        let normalizedEmail = self.email.lowercased()
        
        Task {
            do {
                print("🔄 Starting sign-up process...")
                print("🔄 Email: \(normalizedEmail)")
                print("🔄 Password length: \(self.password.count)")
                
                // Use Supabase Auth's email/password sign-up
                let response = try await self.authManager.client.auth.signUp(
                    email: normalizedEmail,
                    password: self.password
                )
                
                print("✅ Sign-up successful!")
                print("🔄 Created user ID: \(response.user.id)")
                print("🔄 User email: \(response.user.email ?? "no email")")
                print("🔄 Email confirmed: \(response.user.emailConfirmedAt != nil)")
                print("🔄 Session exists: \(response.session != nil)")
                
                // Check if email confirmation is required
                if response.user.emailConfirmedAt == nil {
                    print("📧 Email confirmation required - user needs to confirm email")
                    print("📧 Email confirmation sent to: \(response.user.email ?? "unknown")")
                    
                    await MainActor.run {
                        self.isLoading = false
                        // Show email verification view instead of banner
                        self.showEmailVerification = true
                    }
                    return
                } else {
                    print("✅ Email already confirmed - proceeding with sign-in")
                    
                    // Sign in immediately after sign-up (only if email is confirmed)
                    print("🔄 Signing in user immediately after sign-up...")
                    print("🔄 Attempting to sign in with email: \(normalizedEmail)")
                    
                    do {
                        let signInResponse = try await self.authManager.client.auth.signIn(
                            email: normalizedEmail,
                            password: self.password
                        )
                        
                        print("✅ User signed in successfully after sign-up")
                        print("🔄 Sign-in session user: \(signInResponse.user.email ?? "no email")")
                        print("🔄 Sign-in session exists: \(signInResponse != nil)")
                        print("🔄 User ID: \(signInResponse.user.id)")
                        print("🔄 User confirmed: \(signInResponse.user.emailConfirmedAt != nil)")
                        
                        // Small delay to ensure session is properly established
                        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        
                        // Test the authentication flow
                        await self.authManager.testAuthenticationFlow()
                        
                        await MainActor.run {
                            self.isLoading = false
                        }
                        
                        // Use the AuthenticationManager's method to create user profile with the name and password
                        let trimmedName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        print("🔄 SignUpView passing name to fetchOrCreateUserProfile: '\(trimmedName)'")
                        print("🔄 SignUpView original name: '\(self.name)'")
                        print("🔄 SignUpView trimmed name: '\(trimmedName)'")
                        print("🔄 SignUpView name length: \(trimmedName.count)")
                        print("🔄 SignUpView user ID: \(response.user.id.uuidString)")
                        print("🔄 SignUpView user email: \(response.user.email ?? "nil")")
                        print("🔄 SignUpView about to call fetchOrCreateUserProfile...")
                        
                        // Ensure the name is properly saved to the database
                        try await self.authManager.fetchOrCreateUserProfile(userId: response.user.id.uuidString, email: response.user.email ?? normalizedEmail, name: trimmedName, password: self.password)
                        
                        print("🔄 SignUpView fetchOrCreateUserProfile completed")
                        
                        // Ensure the name is properly saved and loaded
                        print("🔄 SignUpView calling ensureUserNameIsSaved with name: '\(trimmedName)'")
                        await self.authManager.ensureUserNameIsSaved(userId: response.user.id.uuidString, name: trimmedName)
                        
                        print("🔄 SignUpView ensureUserNameIsSaved completed")
                        
                        // Force refresh the user profile to ensure the name is loaded
                        print("🔄 SignUpView calling forceRefreshUserProfile")
                        await self.authManager.forceRefreshUserProfile()
                        
                        print("🔄 SignUpView forceRefreshUserProfile completed")
                        
                        // Cache successful signup for future email checks
                        await self.authManager.cacheSuccessfulSignup(email: normalizedEmail)
                        
                        // Show success message and complete signup flow (only if we got here via sign-in)
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                self.successMessage = "Account successfully created! Welcome to Nura."
                                self.showSuccessMessage = true
                            }
                            
                            // Complete the signup flow
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                self.showSuccessMessage = false
                                self.isPresented = false
                            }
                        }
                    } catch {
                        print("❌ Sign-in failed after sign-up: \(error)")
                        print("❌ Error details: \(error.localizedDescription)")
                        throw error
                    }
                }
            } catch {
                // Check if the error indicates email already exists
                let errorMessage = error.localizedDescription.lowercased()
                if errorMessage.contains("already exists") || 
                   errorMessage.contains("already registered") ||
                   errorMessage.contains("user already") {
                    // Cache failed signup for future email checks
                    await self.authManager.cacheFailedSignup(email: normalizedEmail)
                }
                
                await MainActor.run {
                    self.isLoading = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.successMessage = "Account creation failed: \(error.localizedDescription)"
                        self.showSuccessMessage = true
                    }
                }
            }
        }
    }
    

    

    

    

    

    
    private func startCountdown() {
        countdownSeconds = 23
        isCountdownActive = true
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdownSeconds > 0 {
                countdownSeconds -= 1
            } else {
                isCountdownActive = false
                timer.invalidate()
            }
        }
    }
    
    // MARK: - Email Availability Check
    
    private func checkEmailAvailability() {
        // Cancel previous timer
        emailCheckTimer?.invalidate()
        
        // Reset states
        emailExists = false
        isCheckingEmail = false
        
        // Don't check if email is empty or invalid
        guard !email.isEmpty && isEmailValid else { return }
        
        // Debounce the check to avoid excessive API calls
        emailCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            Task {
                await performEmailAvailabilityCheck()
            }
        }
    }
    
    private func performEmailAvailabilityCheck() async {
        await MainActor.run {
            isCheckingEmail = true
        }
        
        do {
            // Use smart email checking that avoids rate limiting
            let exists = try await authManager.checkEmailExists(email: email.lowercased())
            
            await MainActor.run {
                isCheckingEmail = false
                emailExists = exists
                
                if exists {
                    print("❌ Email already exists: \(email)")
                } else {
                    print("✅ Email is available: \(email)")
                }
            }
        } catch {
            await MainActor.run {
                isCheckingEmail = false
                print("❌ Error checking email availability: \(error)")
            }
        }
    }
    
    private func getEmailFieldBorderColor() -> Color {
        if showEmailError {
            return NuraColors.error
        } else if emailExists {
            return NuraColors.error
        } else if !email.isEmpty && isEmailValid && !emailExists {
            return NuraColors.success
        } else {
            return Color.white.opacity(0.2)
        }
    }
    
    private func getEmailFieldBorderWidth() -> CGFloat {
        if showEmailError || emailExists || (!email.isEmpty && isEmailValid && !emailExists) {
            return 2
        } else {
            return 1
        }
    }
}

// Password requirements checklist
struct PasswordRequirementsView: View {
    let isLongEnough: Bool
    let hasUpper: Bool
    let hasLower: Bool
    let hasNumber: Bool
    let hasSymbol: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RequirementRow(text: "At least 8 characters", met: isLongEnough)
            RequirementRow(text: "One uppercase letter", met: hasUpper)
            RequirementRow(text: "One lowercase letter", met: hasLower)
            RequirementRow(text: "One number", met: hasNumber)
            RequirementRow(text: "One symbol (!@#$...)", met: hasSymbol)
        }
        .font(.caption)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(NuraColors.card))
    }
}

struct RequirementRow: View {
    let text: String
    let met: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? NuraColors.success : .gray)
            Text(text)
                .foregroundColor(met ? .primary : .gray)
        }
    }
}

// Custom password field that completely disables autofill
struct CustomPasswordField: View {
    @Binding var text: String
    let placeholder: String
    let showPassword: Bool
    @FocusState private var isFocused: Bool
    
    init(text: Binding<String>, placeholder: String, showPassword: Bool = false) {
        self._text = text
        self.placeholder = placeholder
        self.showPassword = showPassword
    }
    
    var body: some View {
        Group {
            if showPassword {
                TextField(placeholder, text: $text)
                    .focused($isFocused)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .textFieldStyle(PlainTextFieldStyle())
                    .allowsHitTesting(true)
                    .submitLabel(.done)
            } else {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
                    .textContentType(.username)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .textFieldStyle(PlainTextFieldStyle())
                    .allowsHitTesting(true)
                    .submitLabel(.done)
            }
        }
        .onAppear {
            // Force disable any autofill suggestions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isFocused = true
                }
            }
        }
        .onChange(of: text) { oldValue, newValue in
            // Prevent any autofill interference when user types
            if newValue.count > oldValue.count {
                // User is typing, ensure focus stays
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isFocused = true
                }
            }
        }
    }
}

// Checkbox toggle style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
        }
    }
}

// Animated gradient background
struct AnimatedGradientBackground: View {
    @State private var animate = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: animate ? [NuraColors.sand, NuraColors.sage, NuraColors.secondary] : [NuraColors.sage, NuraColors.sand, NuraColors.secondary]),
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .animation(Animation.easeInOut(duration: 6).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }
}



#Preview {
    SignUpView(isPresented: .constant(true))
        .environmentObject(AuthenticationManager.shared)
} 