import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.pink.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        VStack(spacing: 20) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                            
                            Text("BeautyAI")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Your AI-powered skin health companion")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 50)
                        
                        VStack(spacing: 20) {
                            if isSignUp {
                                TextField("Full Name", text: $name)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.words)
                            }
                            
                            TextField("Email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            SecureField("Password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Button(action: {
                                if isSignUp {
                                    authManager.signUp(email: email, password: password, name: name)
                                } else {
                                    authManager.signIn(email: email, password: password)
                                }
                            }) {
                                HStack {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.purple)
                                .cornerRadius(12)
                            }
                            .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (isSignUp && name.isEmpty))
                            
                            if let errorMessage = authManager.errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button(action: {
                                isSignUp.toggle()
                                authManager.errorMessage = nil
                            }) {
                                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .foregroundColor(.white)
                                    .underline()
                            }
                            
                            if !isSignUp {
                                Button("Forgot Password?") {
                                    showForgotPassword = true
                                }
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
}

struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Button("Send Reset Link") {
                    authManager.resetPassword(email: email)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(authManager.isLoading || email.isEmpty)
                
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
} 