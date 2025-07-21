import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var email = ""
    @State private var password = ""
    @State private var showHeart = false
    
    var canLogin: Bool { !email.isEmpty && !password.isEmpty }
    
    var body: some View {
        ZStack {
            NuraHingeBackground()
                .ignoresSafeArea()
            VStack {
                // Top right actions
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Button("Sign up") { showSignUp = true }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(NuraColors.primary)
                            .padding(.top, 12)
                            .padding(.trailing, 24)
                        Button("Forgot password") { showForgotPassword = true }
                            .font(.caption)
                            .foregroundColor(NuraColors.textSecondary)
                            .padding(.trailing, 24)
                    }
                }
                Spacer()
                // Centered, large, cursive Nura title
                HStack {
                    Spacer()
                    Text("Nura")
                        .font(.system(size: 54, weight: .bold, design: .serif))
                        .italic()
                        .foregroundColor(NuraColors.primary)
                        .padding(.bottom, 32)
                    Spacer()
                }
                VStack(spacing: 18) {
                    SignInWithAppleButton()
                    SignInWithGoogleButton()
                }
                // Add space between Google button and login fields
                Spacer().frame(height: 24)
                // Login bubble, centered and aligned with Google button
                VStack(spacing: 14) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(NuraColors.card.opacity(0.95))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(NuraColors.primary.opacity(0.25), lineWidth: 2)
                        )
                        .shadow(color: NuraColors.primary.opacity(0.08), radius: 4, x: 0, y: 2)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding(.horizontal, 32)
                    SecureField("Password", text: $password)
                        .padding()
                        .background(NuraColors.card.opacity(0.95))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(NuraColors.primary.opacity(0.25), lineWidth: 2)
                        )
                        .shadow(color: NuraColors.primary.opacity(0.08), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 32)
                    Button("Log in") {
                        if canLogin {
                            authManager.isAuthenticated = true
                        }
                    }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: 220)
                        .padding(.vertical, 10)
                        .background(canLogin ? NuraColors.primary : NuraColors.primary.opacity(0.4))
                        .cornerRadius(18)
                        .shadow(color: NuraColors.primary.opacity(0.12), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 32)
                        .disabled(!canLogin)
                }
                Spacer()
                // Animated heart above the quote
                VStack(spacing: 8) {
                    AnimatedHeartView(show: $showHeart)
                        .frame(width: 48, height: 48)
                        .padding(.bottom, 2)
                    Text("Nurture your natural beauty with Nura ✨")
                        .font(.footnote)
                        .foregroundColor(NuraColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 24)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 1.2)) {
                            showHeart = true
                        }
                    }
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

// MARK: - Animated Heart
struct AnimatedHeartView: View {
    @Binding var show: Bool
    @State private var drawAmount: CGFloat = 0
    var body: some View {
        HeartCursiveShape()
            .trim(from: 0, to: drawAmount)
            .stroke(NuraColors.primary, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .frame(width: 48, height: 48)
            .opacity(drawAmount > 0 ? 1 : 0)
            .onChange(of: show, initial: false) { oldValue, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        drawAmount = 1
                    }
                } else {
                    drawAmount = 0
                }
            }
            .onAppear {
                if show {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        drawAmount = 1
                    }
                }
            }
    }
}

struct HeartCursiveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        // Cursive, classic heart
        path.move(to: CGPoint(x: width * 0.5, y: height * 0.8))
        path.addCurve(to: CGPoint(x: 0, y: height * 0.3),
                      control1: CGPoint(x: width * 0.2, y: height),
                      control2: CGPoint(x: 0, y: height * 0.6))
        path.addCurve(to: CGPoint(x: width * 0.5, y: height * 0.2),
                      control1: CGPoint(x: 0, y: height * 0.1),
                      control2: CGPoint(x: width * 0.2, y: height * 0.1))
        path.addCurve(to: CGPoint(x: width, y: height * 0.3),
                      control1: CGPoint(x: width * 0.8, y: height * 0.1),
                      control2: CGPoint(x: width, y: height * 0.1))
        path.addCurve(to: CGPoint(x: width * 0.5, y: height * 0.8),
                      control1: CGPoint(x: width, y: height * 0.6),
                      control2: CGPoint(x: width * 0.8, y: height))
        return path
    }
}

// MARK: - Nura Hinge-Inspired Animated Background
struct NuraHingeBackground: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            // Dark base
            Color(red: 31/255, green: 29/255, blue: 27/255)
                .ignoresSafeArea()
            // Blurred, moving mauve ellipse
            Ellipse()
                .fill(Color(red: 168/255, green: 139/255, blue: 163/255).opacity(0.22))
                .frame(width: 340, height: 180)
                .blur(radius: 48)
                .offset(x: animate ? -60 : 60, y: animate ? -120 : -80)
                .animation(Animation.easeInOut(duration: 7).repeatForever(autoreverses: true), value: animate)
            // Blurred, moving sage ellipse
            Ellipse()
                .fill(Color(red: 157/255, green: 169/255, blue: 158/255).opacity(0.18))
                .frame(width: 260, height: 120)
                .blur(radius: 36)
                .offset(x: animate ? 80 : -80, y: animate ? 100 : 60)
                .animation(Animation.easeInOut(duration: 9).repeatForever(autoreverses: true), value: animate)
            // Subtle grain overlay
            GrainOverlay()
                .blendMode(.overlay)
                .opacity(0.12)
        }
        .onAppear { animate = true }
    }
}

struct GrainOverlay: View {
    var body: some View {
        // Simulate grain with noise using a random dot pattern
        GeometryReader { geo in
            Canvas { context, size in
                for _ in 0..<400 {
                    let x = CGFloat.random(in: 0..<size.width)
                    let y = CGFloat.random(in: 0..<size.height)
                    let opacity = Double.random(in: 0.04...0.12)
                    let color = Color.white.opacity(opacity)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2)),
                        with: .color(color)
                    )
                }
            }
        }
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