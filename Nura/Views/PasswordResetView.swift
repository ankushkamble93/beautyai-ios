import SwiftUI
import Foundation
import Supabase

struct PasswordResetView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isPresented: Bool
    @State private var email: String
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showSuccess = false
    @State private var currentStep: ResetStep = .password
    
    // Custom initializer to set the initial email
    init(isPresented: Binding<Bool>, email: String) {
        _isPresented = isPresented
        _email = State(initialValue: email)
    }
    
    // Animation states
    @State private var animateBackground = false
    @State private var animateCard = false
    
    enum ResetStep {
        case password
        case success
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Beautiful animated background
                BackgroundView(animate: $animateBackground)
                
                // Main content
                VStack(spacing: 0) {
                    // Header with back button
                    HeaderView(isPresented: $isPresented)
                    
                    // Main content area
                    ScrollView {
                        VStack(spacing: 32) {
                            // Title and description
                            TitleSection(step: currentStep)
                            
                            // Step content
                            switch currentStep {
                            case .password:
                                PasswordStepView(
                                    currentPassword: $currentPassword,
                                    newPassword: $newPassword,
                                    confirmPassword: $confirmPassword,
                                    isLoading: $isLoading,
                                    errorMessage: $errorMessage,
                                    action: resetPassword
                                )
                            case .success:
                                SuccessStepView()
                            }
                            
                            // Helpful information
                            if currentStep == .password {
                                HelpSection()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateBackground = true
                }
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    animateCard = true
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func resetPassword() {
        print("🔐 PasswordResetView: Starting password reset process")
        
        guard !currentPassword.isEmpty else {
            print("❌ PasswordResetView: Current password is empty")
            errorMessage = "Please enter your current password"
            return
        }
        
        guard !newPassword.isEmpty else {
            print("❌ PasswordResetView: New password is empty")
            errorMessage = "Please enter a new password"
            return
        }
        
        guard newPassword == confirmPassword else {
            print("❌ PasswordResetView: Passwords do not match")
            errorMessage = "Passwords do not match"
            return
        }
        
        guard newPassword.count >= 8 else {
            print("❌ PasswordResetView: Password too short (\(newPassword.count) characters)")
            errorMessage = "Password must be at least 8 characters"
            return
        }
        
        print("✅ PasswordResetView: Password validation passed")
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                print("📡 PasswordResetView: Attempting to authenticate and update password...")
                
                // First, authenticate with current password
                try await authManager.client.auth.signIn(email: email, password: currentPassword)
                
                // Then update the password using the authenticated session
                let userAttributes = UserAttributes(password: newPassword)
                let updatedUser = try await authManager.client.auth.update(user: userAttributes)
                
                print("✅ PasswordResetView: Password updated successfully")
                print("✅ PasswordResetView: Updated user ID: \(updatedUser.id)")
                
                // Send confirmation email
                try await authManager.sendPasswordUpdateConfirmationEmail(to: email)
                
                await MainActor.run {
                    isLoading = false
                    print("🎉 PasswordResetView: Showing success step")
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep = .success
                    }
                    
                    // Auto-dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        print("🚪 PasswordResetView: Auto-dismissing sheet")
                        isPresented = false
                    }
                }
            } catch {
                print("❌ PasswordResetView: Error during password reset: \(error.localizedDescription)")
                
                await MainActor.run {
                    isLoading = false
                    let formattedError = formatErrorMessage(error)
                    print("📝 PasswordResetView: Formatted error message: \(formattedError)")
                    errorMessage = formattedError
                }
            }
        }
    }
    
    private func formatErrorMessage(_ error: Error) -> String {
        let errorString = error.localizedDescription
        
        if errorString.contains("Invalid email") {
            return "Please enter a valid email address"
        } else if errorString.contains("Invalid login credentials") ||
                  errorString.contains("Invalid password") {
            return "Current password is incorrect"
        } else if errorString.contains("User not found") || 
                  errorString.contains("No account found") {
            return "No account found with this email address"
        } else if errorString.contains("Too many requests") {
            return "Too many attempts. Please try again in a few minutes"
        } else if errorString.contains("network") {
            return "Network error. Please check your connection and try again"
        } else {
            return "Something went wrong. Please try again"
        }
    }
    

}

// MARK: - Background View
private struct BackgroundView: View {
    @Binding var animate: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    NuraColors.sand,
                    NuraColors.sage.opacity(0.3),
                    NuraColors.secondary.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ForEach(0..<3) { index in
                Circle()
                    .fill(NuraColors.primary.opacity(0.1))
                    .frame(width: CGFloat(100 + index * 50))
                    .offset(
                        x: animate ? CGFloat(50 + index * 30) : CGFloat(-50 - index * 30),
                        y: animate ? CGFloat(-100 + index * 40) : CGFloat(100 - index * 40)
                    )
                    .animation(
                        Animation.easeInOut(duration: 8 + Double(index))
                        .repeatForever(autoreverses: true),
                        value: animate
                    )
            }
        }
    }
}

// MARK: - Header View
private struct HeaderView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        HStack {
            Button(action: { isPresented = false }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(NuraColors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(NuraColors.card)
                        .shadow(color: NuraColors.primary.opacity(0.1), radius: 8, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }
}

// MARK: - Title Section
private struct TitleSection: View {
    let step: PasswordResetView.ResetStep
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(NuraColors.primary.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: iconForStep)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(NuraColors.primary)
            }
            
            // Title
            Text(titleForStep)
                .font(.custom("DancingScript-Bold", size: 42))
                .foregroundColor(NuraColors.primary)
                .multilineTextAlignment(.center)
            
            // Description
            Text(descriptionForStep)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(NuraColors.primary.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 20)
        }
    }
    
    private var iconForStep: String {
        switch step {
        case .password: return "lock.rotation"
        case .success: return "checkmark.shield"
        }
    }
    
    private var titleForStep: String {
        switch step {
        case .password: return "Update Password"
        case .success: return "Success!"
        }
    }
    
    private var descriptionForStep: String {
        switch step {
        case .password: return "Enter your current password and create a new secure password for your account."
        case .success: return "Your password has been updated successfully!"
        }
    }
}



// MARK: - Password Step View
private struct PasswordStepView: View {
    @Binding var currentPassword: String
    @Binding var newPassword: String
    @Binding var confirmPassword: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    let action: () -> Void
    
    var canReset: Bool {
        !currentPassword.isEmpty &&
        !newPassword.isEmpty && 
        !confirmPassword.isEmpty && 
        newPassword == confirmPassword && 
        newPassword.count >= 8
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Current Password Field
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(NuraColors.card.opacity(0.12))
                    .shadow(color: NuraColors.primary.opacity(0.06), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(NuraColors.primary.opacity(0.3), lineWidth: 1)
                    )
                
                HStack(spacing: 12) {
                    Image(systemName: "lock")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(NuraColors.primary)
                        .frame(width: 24)
                    
                    ZStack(alignment: .leading) {
                        if currentPassword.isEmpty {
                            Text("Current password")
                                .foregroundColor(NuraColors.primary.opacity(0.6))
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                        }
                        SecureField("", text: $currentPassword)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(NuraColors.primary)
                            .accentColor(NuraColors.primary)
                            .textContentType(.password)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 56)
            }
            .frame(maxWidth: 320)
            
            // New Password Field
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(NuraColors.card.opacity(0.12))
                    .shadow(color: NuraColors.primary.opacity(0.06), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(NuraColors.primary.opacity(0.3), lineWidth: 1)
                    )
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(NuraColors.primary)
                        .frame(width: 24)
                    
                    ZStack(alignment: .leading) {
                        if newPassword.isEmpty {
                            Text("New password")
                                .foregroundColor(NuraColors.primary.opacity(0.6))
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                        }
                        SecureField("", text: $newPassword)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(NuraColors.primary)
                            .accentColor(NuraColors.primary)
                            .textContentType(.newPassword)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 56)
            }
            .frame(maxWidth: 320)
            
            // Confirm Password Field
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(NuraColors.card.opacity(0.12))
                    .shadow(color: NuraColors.primary.opacity(0.06), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(NuraColors.primary.opacity(0.3), lineWidth: 1)
                    )
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(NuraColors.primary)
                        .frame(width: 24)
                    
                    ZStack(alignment: .leading) {
                        if confirmPassword.isEmpty {
                            Text("Confirm password")
                                .foregroundColor(NuraColors.primary.opacity(0.6))
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                        }
                        SecureField("", text: $confirmPassword)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(NuraColors.primary)
                            .accentColor(NuraColors.primary)
                            .textContentType(.newPassword)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 56)
            }
            .frame(maxWidth: 320)
            
            // Password requirements
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: newPassword.count >= 8 ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(newPassword.count >= 8 ? NuraColors.success : NuraColors.primary.opacity(0.3))
                    Text("At least 8 characters")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(NuraColors.primary.opacity(0.7))
                    Spacer()
                }
                
                HStack {
                    Image(systemName: newPassword == confirmPassword && !newPassword.isEmpty ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(newPassword == confirmPassword && !newPassword.isEmpty ? NuraColors.success : NuraColors.primary.opacity(0.3))
                    Text("Passwords match")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(NuraColors.primary.opacity(0.7))
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            
            // Reset Button
            Button(action: action) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isLoading ? "Updating..." : "Update Password")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: 320)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: canReset ? 
                            [NuraColors.primary, NuraColors.primary.opacity(0.8)] : 
                            [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
                .shadow(
                    color: canReset ? NuraColors.primary.opacity(0.3) : .clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
                .scaleEffect(canReset ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.2), value: canReset)
            }
            .disabled(!canReset || isLoading)
            .buttonStyle(PlainButtonStyle())
            
            // Error message
            if let error = errorMessage {
                ErrorSection(error: error)
            }
        }
    }
}

// MARK: - Success Step View
private struct SuccessStepView: View {
    @State private var animateCheckmark = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Animated checkmark
            ZStack {
                Circle()
                    .fill(NuraColors.success.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(NuraColors.success)
                    .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: animateCheckmark)
            }
            
            Text("Password Reset!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(NuraColors.primary)
            
            Text("Your password has been updated successfully! You can now sign in with your new password immediately.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(NuraColors.primary.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(NuraColors.card.opacity(0.1))
                .shadow(color: NuraColors.success.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                animateCheckmark = true
            }
        }
    }
}

// MARK: - Error Section
private struct ErrorSection: View {
    let error: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(NuraColors.errorStrong)
            
            Text(error)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(NuraColors.errorStrong)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(NuraColors.error.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(NuraColors.errorStrong.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Help Section
private struct HelpSection: View {
    var body: some View {
        VStack(spacing: 20) {
            Divider()
                .background(NuraColors.primary.opacity(0.2))
                .padding(.horizontal, 40)
            
            VStack(spacing: 12) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24))
                    .foregroundColor(NuraColors.sage)
                    .opacity(0.6)
                
                Text("Need help?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(NuraColors.primary)
                
                Text("Contact our support team if you're having trouble accessing your account")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(NuraColors.primary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PasswordResetView(isPresented: .constant(true), email: "test@example.com")
        .environmentObject(AuthenticationManager.shared)
} 