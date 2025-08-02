import SwiftUI
import Supabase

struct EmailVerificationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isPresented: Bool
    let email: String
    let password: String
    let name: String
    
    @State private var isLoading = false
    @State private var showResendSuccess = false
    @State private var errorMessage: String? = nil
    @State private var verificationCode = ""
    @State private var showCodeInput = false
    @FocusState private var isCodeFieldFocused: Bool
    @State private var resendCount = 0 // Track resend attempts for this session
    @State private var maxResendsAllowed = 2 // Allow 2 resends total (initial + 2 resends)
    @State private var resendCountdown = 0 // Countdown timer for resend cooldown
    @State private var hasShownCountdown = false // Track if countdown has been shown
    @State private var hasResentOnce = false // Track if user has clicked resend at least once
    
    // MARK: - Computed Properties
    
    private var backButton: some View {
        Button(action: { 
            isPresented = false
        }) {
            Image(systemName: "chevron.left")
                .font(.title2)
                .foregroundColor(NuraColors.primary)
                .padding(8)
                .background(Circle().fill(NuraColors.card))
        }
    }
    
    private var focusIndicator: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(getFocusIndicatorColor(), lineWidth: 2)
            .padding(-4)
    }
    
    private var iconSection: some View {
        Image(systemName: "envelope.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(NuraColors.primary)
            .padding(.bottom, 8)
    }
    
    private var titleSection: some View {
        Text("Verify your email")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .multilineTextAlignment(.center)
    }
    
    private var descriptionText1: some View {
        Text("We've sent a 6-digit verification code to")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    private var emailText: some View {
        Text(email)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(NuraColors.primary)
    }
    
    private var descriptionText2: some View {
        Text("Enter the code below to verify your account.")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
    }
    

    
    private var verifyButton: some View {
        Button(action: verifyCode) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text("Verify Code")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(getVerifyButtonBackground())
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(color: getVerifyButtonShadow(), radius: 8, x: 0, y: 2)
        }
        .disabled(isLoading || verificationCode.count != 6)
    }
    
    private var resendButton: some View {
        Button(action: resendCode) {
            HStack {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14, weight: .medium))
                Text(getResendButtonText())
            }
            .font(.subheadline)
            .foregroundColor(getResendButtonForeground())
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(getResendButtonBackground())
            .cornerRadius(8)
        }
        .disabled(isLoading || resendCount >= maxResendsAllowed || (hasResentOnce && resendCountdown > 0 && hasShownCountdown))
    }
    
    private func getResendButtonText() -> String {
        if resendCount >= maxResendsAllowed {
            return "Resend limit reached"
        } else if hasResentOnce && resendCountdown > 0 && hasShownCountdown {
            return "Resend in \(resendCountdown)s"
        } else {
            let remainingResends = maxResendsAllowed - resendCount
            return "Resend verification code (\(remainingResends) left)"
        }
    }
    
    private func getVerifyButtonBackground() -> Color {
        verificationCode.count == 6 ? NuraColors.primary : Color.gray.opacity(0.3)
    }
    
    private func getVerifyButtonShadow() -> Color {
        verificationCode.count == 6 ? NuraColors.primary.opacity(0.3) : .clear
    }
    
    private func getResendButtonForeground() -> Color {
        resendCount >= maxResendsAllowed ? .gray : NuraColors.primary
    }
    
    private func getResendButtonBackground() -> Color {
        resendCount >= maxResendsAllowed ? Color.gray.opacity(0.1) : NuraColors.primary.opacity(0.1)
    }
    
    private func getFocusIndicatorColor() -> Color {
        isCodeFieldFocused ? NuraColors.primary.opacity(0.3) : Color.clear
    }
    
    private func getFooterTextString() -> String {
        if resendCount >= maxResendsAllowed {
            return "Please check your spam folder and email inbox for the verification code."
        } else if hasResentOnce && resendCountdown > 0 && hasShownCountdown {
            return "Please wait for the countdown to finish before resending."
        } else {
            return "Check your spam folder if you don't see the code."
        }
    }
    
    private func getFooterText() -> some View {
        Text(getFooterTextString())
            .font(.footnote)
            .foregroundColor(NuraColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.bottom, 18)
    }
    
    private var alternativeButton: some View {
        Button(action: checkEmailVerification) {
            Text("I verified via email link")
                .font(.subheadline)
                .foregroundColor(NuraColors.secondary)
                .underline()
        }
        .disabled(isLoading)
    }
    
    private var successMessageView: some View {
        Group {
            if showResendSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Verification code sent!")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                .padding(12)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var errorMessageView: some View {
        Group {
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding(12)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    private var descriptionSection: some View {
        VStack(spacing: 12) {
            descriptionText1
            emailText
            descriptionText2
        }
    }
    
    private var footerText: some View {
        getFooterText()
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [NuraColors.sand, NuraColors.sage, NuraColors.secondary]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            headerSection
            Spacer()
            contentSection
            Spacer()
            footerSection
        }
    }
    
    private var headerSection: some View {
        HStack {
            backButton
            Spacer()
        }
        .padding(.top, 12)
        .padding(.horizontal)
    }
    
    private var contentSection: some View {
        VStack(spacing: 24) {
            iconSection
            titleSection
            descriptionSection
            verificationInputSection
            actionButtonsSection
            successMessageView
            errorMessageView
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(NuraColors.card)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
    
    private var verificationInputSection: some View {
        VStack(spacing: 16) {
            codeInputField
            hiddenTextField
        }
    }
    
    private var codeInputField: some View {
        HStack(spacing: 12) {
            ForEach(0..<6, id: \.self) { index in
                VerificationDigitField(
                    digit: getDigit(at: index),
                    isActive: index == verificationCode.count,
                    onDigitChange: handleDigitChange,
                    onFocusTrigger: { isCodeFieldFocused = true }
                )
            }
        }
        .padding(.horizontal, 20)
        .onTapGesture {
            isCodeFieldFocused = true
        }
        .overlay(focusIndicator)
    }
    
    private var hiddenTextField: some View {
        TextField("", text: $verificationCode)
            .keyboardType(.numberPad)
            .focused($isCodeFieldFocused)
            .opacity(0)
            .frame(height: 1)
            .onChange(of: verificationCode) { oldValue, newValue in
                if errorMessage != nil {
                    errorMessage = nil
                }
                
                if newValue.count > 6 {
                    verificationCode = String(newValue.prefix(6))
                }
                
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    verificationCode = filtered
                }
            }
            .onTapGesture {
                isCodeFieldFocused = true
            }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            verifyButton
            resendButton
            alternativeButton
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Divider().padding(.horizontal, 60)
            Image(systemName: "leaf")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundColor(NuraColors.sage)
                .opacity(0.18)
            footerText
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                mainContentView
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Focus the hidden text field to show keyboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isCodeFieldFocused = true
            }
        }
    }
    
    private func verifyCode() {
        guard verificationCode.count == 6 else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Verify the code with Supabase
                let response = try await authManager.client.auth.verifyOTP(
                    email: email,
                    token: verificationCode,
                    type: .signup
                )
                
                print("✅ Code verification successful!")
                print("🔄 User: \(response.user.email ?? "no email")")
                print("🔄 Email confirmed: \(response.user.emailConfirmedAt != nil)")
                
                // Save the name to Supabase Auth metadata now that we have a session
                let trimmedName = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    print("🔄 Saving name to Supabase Auth metadata after verification: '\(trimmedName)'")
                    print("🔄 Current user metadata before update: \(response.user.userMetadata)")
                    print("🔄 User ID: \(response.user.id)")
                    
                    do {
                        try await authManager.client.auth.update(user: UserAttributes(data: ["name": AnyJSON.string(trimmedName)]))
                        print("✅ Name saved to Supabase Auth metadata after verification")
                        
                        // Wait a moment for the session to update
                        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        
                        // Verify the update worked by checking the session again
                        let updatedSession = try await authManager.client.auth.session
                        print("🔄 Updated user metadata after save: \(updatedSession.user.userMetadata)")
                        print("🔄 Updated user metadata keys: \(updatedSession.user.userMetadata.keys)")
                        
                        if let savedName = updatedSession.user.userMetadata["name"]?.stringValue {
                            print("✅ Name verification successful: '\(savedName)'")
                        } else {
                            print("❌ Name verification failed: name not found in metadata")
                        }
                        
                        // CRITICAL FIX: Pass the name directly to profile creation
                        print("🔄 CRITICAL: Passing name directly to profile creation: '\(trimmedName)'")
                        try await authManager.fetchOrCreateUserProfile(
                            userId: response.user.id.uuidString,
                            email: response.user.email ?? "",
                            name: trimmedName
                        )
                        
                        // Set temporary name for immediate display
                        authManager.setTempUserName(trimmedName)
                        print("🔄 CRITICAL: Set temporary name for immediate display: '\(trimmedName)'")
                    } catch {
                        print("❌ Failed to save name to Auth metadata: \(error)")
                        print("❌ Error details: \(error.localizedDescription)")
                    }
                } else {
                    print("⚠️ No name to save (empty or whitespace only)")
                }
                
                await MainActor.run {
                    isLoading = false
                    
                    // Close this view and let the auth state change handle navigation
                    isPresented = false
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid verification code. Please try again."
                    // Maintain focus after error so user can edit
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isCodeFieldFocused = true
                    }
                }
                print("❌ Code verification failed: \(error)")
            }
        }
    }
    
    private func checkEmailVerification() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Try to sign in to check if email is verified
                let response = try await authManager.client.auth.signIn(
                    email: email,
                    password: password
                )
                
                print("✅ Email verification successful!")
                print("🔄 User: \(response.user.email ?? "no email")")
                print("🔄 Email confirmed: \(response.user.emailConfirmedAt != nil)")
                
                await MainActor.run {
                    isLoading = false
                    
                    // Close this view and let the auth state change handle navigation
                    isPresented = false
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Email not yet verified. Please check your email and click the verification link."
                }
                print("❌ Email verification failed: \(error)")
            }
        }
    }
    
    private func resendCode() {
        // Check if resend limit has been reached
        guard resendCount < maxResendsAllowed else {
            errorMessage = "Resend limit reached. Please check your spam folder and email inbox for the verification code."
            return
        }
        
        // Check if countdown is still active (only if user has already resent once)
        if hasResentOnce && hasShownCountdown && resendCountdown > 0 {
            errorMessage = "Please wait for the countdown to finish before resending."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Check if we have a valid session for resend
        Task {
            do {
                let currentSession = try await authManager.client.auth.session
                print("🔄 Current session for resend: \(currentSession.user.email ?? "no email")")
            } catch {
                print("❌ No session available for resend: \(error)")
                // Continue anyway, as resend might work without session
            }
        }
        
        Task {
            do {
                print("🔄 Attempting to resend verification code to: \(email)")
                print("🔄 Current resend count: \(resendCount)/\(maxResendsAllowed)")
                

                
                // Resend verification code
                try await authManager.client.auth.resend(
                    email: email,
                    type: .signup
                )
                
                print("✅ Supabase resend API call completed successfully")
                
                await MainActor.run {
                    isLoading = false
                    resendCount += 1 // Increment resend count AFTER successful resend
                    hasResentOnce = true // Mark that user has clicked resend at least once
                    showResendSuccess = true
                    
                    // Only start countdown after the first successful resend
                    if resendCount == 1 {
                        hasShownCountdown = true
                        startResendCountdown() // Start countdown after first successful resend
                    }
                    
                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showResendSuccess = false
                    }
                }
                
                print("✅ Verification code resent successfully (attempt \(resendCount)/\(maxResendsAllowed))")
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to resend verification code. Please try again."
                    // Don't increment resendCount on failure
                }
                print("❌ Failed to resend verification code: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getDigit(at index: Int) -> String {
        guard index < verificationCode.count else { return "" }
        let startIndex = verificationCode.startIndex
        let digitIndex = verificationCode.index(startIndex, offsetBy: index)
        return String(verificationCode[digitIndex])
    }
    
    private func handleDigitChange(_ digit: String) {
        if digit.isEmpty {
            if !verificationCode.isEmpty {
                verificationCode.removeLast()
            }
        } else {
            if verificationCode.count < 6 {
                verificationCode += digit
            }
        }
    }
    
    private func startResendCountdown() {
        resendCountdown = 60 // 60 seconds cooldown
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if resendCountdown > 0 {
                resendCountdown -= 1
            } else {
                timer.invalidate()
            }
        }
    }
}

// MARK: - Custom verification digit field
struct VerificationDigitField: View {
    let digit: String
    let isActive: Bool
    let onDigitChange: (String) -> Void
    let onFocusTrigger: () -> Void
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(getDigitFieldFillColor())
                .frame(width: 50, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getDigitFieldStrokeColor(), lineWidth: 2)
                )
            
            Text(digit)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .onTapGesture {
            // Remove the digit and ensure focus is maintained
            onDigitChange("")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onFocusTrigger()
            }
        }
    }
    
    private func getDigitFieldFillColor() -> Color {
        isActive ? NuraColors.primary.opacity(0.1) : Color.gray.opacity(0.1)
    }
    
    private func getDigitFieldStrokeColor() -> Color {
        isActive ? NuraColors.primary : Color.gray.opacity(0.3)
    }
}

// MARK: - Preview
#Preview {
    EmailVerificationView(
        isPresented: .constant(true),
        email: "test@example.com",
        password: "password123",
        name: "Test User"
    )
    .environmentObject(AuthenticationManager.shared)
} 