import SwiftUI

struct LoginView: View {
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggedIn = false
    
    var body: some View {
        ZStack {
            // Motion background: animated skincare product silhouettes
            SkincareMotionBackground()
                .ignoresSafeArea()
            
            VStack {
                // Top right actions
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Button("Sign up") { showSignUp = true }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.0))
                            .padding(.top, 12)
                            .padding(.trailing, 24)
                        Button("Forgot password") { showForgotPassword = true }
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.trailing, 24)
                    }
                }
                Spacer()
                // App logo or name (optional)
                Text("Nura")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.45, green: 0.35, blue: 0.25))
                    .padding(.bottom, 32)
                // Social login buttons
                VStack(spacing: 18) {
                    SignInWithAppleButton()
                    SignInWithGoogleButton()
                }
                .padding(.bottom, 32)
                // Email/password fields (modern, rounded)
                VStack(spacing: 14) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(red: 0.85, green: 0.4, blue: 0.0).opacity(0.25), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal, 32)
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.white.opacity(0.85))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color(red: 0.85, green: 0.4, blue: 0.0).opacity(0.25), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 32)
                    Button("Log in") { isLoggedIn = true }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.85, green: 0.4, blue: 0.0))
                        .cornerRadius(10)
                        .padding(.horizontal, 32)
                }
                Spacer()
            }
            // Simulate navigation to main app after login
            if isLoggedIn {
                Color.clear
                    .fullScreenCover(isPresented: $isLoggedIn) {
                        ContentView()
                    }
            }
        }
        .sheet(isPresented: $showSignUp) {
            Text("Sign up flow coming soon!")
        }
        .sheet(isPresented: $showForgotPassword) {
            Text("Forgot password flow coming soon!")
        }
    }
}

// MARK: - Skincare Motion Background
struct SkincareMotionBackground: View {
    @State private var bottleOffset: CGSize = .zero
    @State private var jarOffset: CGSize = .zero
    @State private var tubeOffset: CGSize = .zero
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.98, green: 0.93, blue: 0.85), Color(red: 0.93, green: 0.87, blue: 0.77)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.9)
            // Animated skincare bottle
            SkincareBottleShape()
                .fill(Color(red: 0.95, green: 0.85, blue: 0.65).opacity(0.22))
                .frame(width: 80, height: 180)
                .offset(bottleOffset)
                .blur(radius: 6)
                .animation(.easeInOut(duration: 7).repeatForever(autoreverses: true), value: bottleOffset)
            // Animated skincare jar
            SkincareJarShape()
                .fill(Color(red: 0.85, green: 0.7, blue: 0.5).opacity(0.18))
                .frame(width: 120, height: 60)
                .offset(jarOffset)
                .blur(radius: 8)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: jarOffset)
            // Animated skincare tube
            SkincareTubeShape()
                .fill(Color(red: 0.98, green: 0.93, blue: 0.85).opacity(0.18))
                .frame(width: 60, height: 140)
                .offset(tubeOffset)
                .blur(radius: 7)
                .animation(.easeInOut(duration: 12).repeatForever(autoreverses: true), value: tubeOffset)
        }
        .onAppear {
            bottleOffset = CGSize(width: -60, height: -100)
            jarOffset = CGSize(width: 90, height: 120)
            tubeOffset = CGSize(width: 60, height: -120)
            // Animate to new positions
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                bottleOffset = CGSize(width: 40, height: -40)
                jarOffset = CGSize(width: -50, height: 80)
                tubeOffset = CGSize(width: -80, height: 100)
            }
        }
    }
}

// MARK: - Abstract Skincare Product Shapes
struct SkincareBottleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Bottle body
        path.addRoundedRect(in: CGRect(x: rect.midX - rect.width * 0.18, y: rect.minY + rect.height * 0.18, width: rect.width * 0.36, height: rect.height * 0.64), cornerSize: CGSize(width: rect.width * 0.18, height: rect.width * 0.18))
        // Bottle neck
        path.addRect(CGRect(x: rect.midX - rect.width * 0.09, y: rect.minY, width: rect.width * 0.18, height: rect.height * 0.18))
        return path
    }
}
struct SkincareJarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Jar base
        path.addRoundedRect(in: CGRect(x: rect.minX + rect.width * 0.1, y: rect.midY - rect.height * 0.18, width: rect.width * 0.8, height: rect.height * 0.36), cornerSize: CGSize(width: rect.height * 0.18, height: rect.height * 0.18))
        // Jar lid
        path.addRect(CGRect(x: rect.minX + rect.width * 0.18, y: rect.midY - rect.height * 0.28, width: rect.width * 0.64, height: rect.height * 0.12))
        return path
    }
}
struct SkincareTubeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Tube body
        path.move(to: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.28, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.28, y: rect.maxY))
        path.closeSubpath()
        // Tube cap
        path.addRoundedRect(in: CGRect(x: rect.midX - rect.width * 0.12, y: rect.maxY - rect.height * 0.08, width: rect.width * 0.24, height: rect.height * 0.08), cornerSize: CGSize(width: rect.width * 0.04, height: rect.width * 0.04))
        return path
    }
}

// MARK: - Social Login Buttons (UI only for now)
struct SignInWithAppleButton: View {
    var body: some View {
        Button(action: { /* Apple login logic */ }) {
            HStack {
                Image(systemName: "applelogo")
                    .font(.title2)
                Text("Sign in with Apple")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.black)
            .cornerRadius(10)
            .padding(.horizontal, 32)
        }
    }
}

struct SignInWithGoogleButton: View {
    var body: some View {
        Button(action: { /* Google login logic */ }) {
            HStack {
                Image(systemName: "globe")
                    .font(.title2)
                Text("Sign in with Google")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(10)
            .padding(.horizontal, 32)
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
} 