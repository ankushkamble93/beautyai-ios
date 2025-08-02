import SwiftUI
import Foundation
import Supabase

struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showEmailValidation = false
    @State private var showPasswordResetSheet = false
    
    // Animation states
    @State private var animateBackground = false
    @State private var animateCard = false
    @State private var animateIcon = false
    
    var canSend: Bool { 
        !email.isEmpty && isValidEmail(email)
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
                            TitleSection()
                            
                            if showPasswordResetSheet {
                                // This will be handled by the sheet
                            } else {
                                // Email input field
                                EmailInputSection(
                                    email: $email,
                                    showEmailValidation: $showEmailValidation
                                )
                                
                                // Action button
                                ActionButtonSection(
                                    canSend: canSend,
                                    isLoading: isLoading,
                                    action: sendReset
                                )
                            }
                            
                            // Error message
                            if let error = errorMessage {
                                ErrorSection(error: error)
                            }
                            
                            // Helpful information
                            HelpSection()
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
                withAnimation(.easeInOut(duration: 1.2).delay(0.4)) {
                    animateIcon = true
                }
            }
            .sheet(isPresented: $showPasswordResetSheet) {
                PasswordResetView(isPresented: $showPasswordResetSheet, email: email)
                    .environmentObject(authManager)
            }
            .onChange(of: showPasswordResetSheet) { oldValue, newValue in
                if oldValue == false && newValue == true {
                    print("📱 ForgotPasswordView: Presenting PasswordResetView sheet")
                } else if oldValue == true && newValue == false {
                    print("📱 ForgotPasswordView: PasswordResetView sheet was dismissed")
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func sendReset() {
        print("🔐 ForgotPasswordView: Starting email verification for: \(email)")
        errorMessage = nil
        showEmailValidation = false
        
        guard canSend else { 
            print("❌ ForgotPasswordView: Email validation failed")
            showEmailValidation = true
            return 
        }
        
        isLoading = true
        print("🔄 ForgotPasswordView: Loading started")
        
        // Simulate a brief loading delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("✅ ForgotPasswordView: Email format validated, proceeding to password reset")
            
            self.isLoading = false
            print("🎯 ForgotPasswordView: Showing password reset sheet")
            self.showPasswordResetSheet = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func formatErrorMessage(_ error: Error) -> String {
        let errorString = error.localizedDescription
        
        // Custom error messages for better UX
        if errorString.contains("Invalid email") {
            return "Please enter a valid email address"
        } else if errorString.contains("User not found") {
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
            // Base gradient
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
            
            // Animated floating elements
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
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(NuraColors.primary.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "lock.rotation")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(NuraColors.primary)
            }
            
            // Title
            Text("Forgot Password?")
                .font(.custom("DancingScript-Bold", size: 42))
                .foregroundColor(NuraColors.primary)
                .multilineTextAlignment(.center)
            
            // Description
            Text("No worries! Enter your email and we'll send you a reset link to get back into your account.")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(NuraColors.primary.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Email Input Section
private struct EmailInputSection: View {
    @Binding var email: String
    @Binding var showEmailValidation: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Email field
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(NuraColors.card.opacity(0.12))
                    .shadow(color: NuraColors.primary.opacity(0.06), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(
                                showEmailValidation ? NuraColors.errorStrong : NuraColors.primary.opacity(0.3),
                                lineWidth: showEmailValidation ? 2 : 1
                            )
                    )
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(NuraColors.primary)
                        .frame(width: 24)
                    
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("Enter your email address")
                                .foregroundColor(NuraColors.primary.opacity(0.6))
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                        }
                        TextField("", text: $email)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(NuraColors.primary)
                            .accentColor(NuraColors.primary)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .focused($isFocused)
                    }
                }
                .padding(.horizontal, 18)
                .frame(height: 56)
            }
            .frame(maxWidth: 320)
            
            // Validation message
            if showEmailValidation && email.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(NuraColors.errorStrong)
                    
                    Text("Please enter your email address")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(NuraColors.errorStrong)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Action Button Section
private struct ActionButtonSection: View {
    let canSend: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button(action: action) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(isLoading ? "Verifying..." : "Verify Email")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: 320)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: canSend ? 
                            [NuraColors.primary, NuraColors.primary.opacity(0.8)] : 
                            [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                        ),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
                .shadow(
                    color: canSend ? NuraColors.primary.opacity(0.3) : .clear,
                    radius: 12,
                    x: 0,
                    y: 6
                )
                .scaleEffect(canSend ? 1.0 : 0.98)
                .animation(.easeInOut(duration: 0.2), value: canSend)
            }
            .disabled(!canSend || isLoading)
            .buttonStyle(PlainButtonStyle())
            
            // Additional help text
            Text("We'll verify your email and help you reset your password")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(NuraColors.primary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
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
    ForgotPasswordView(isPresented: .constant(true))
        .environmentObject(AuthenticationManager.shared)
} 