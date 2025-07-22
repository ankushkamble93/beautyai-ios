import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var email = ""
    @State private var password = ""
    @State private var showHeart = false
    // Add state for arrow fill progress
    @State private var arrowFill: CGFloat = 0.0
    // Add state to control one-time animation
    @State private var animateArrow = false
    
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
                // Shift Nura app title higher, center between top actions and sign-in buttons, and use Google cursive style
                HStack {
                    Spacer()
                    Text("nura.")
                        .font(.custom("DancingScript-Bold", size: 64))
                        .foregroundColor(Color(red: 0.976, green: 0.965, blue: 0.949)) // #F9F6F2 creamy off-white
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .kerning(2)
                        .shadow(color: NuraColors.primary.opacity(0.18), radius: 8, x: 0, y: 3)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                }
                VStack(spacing: 18) {
                    SignInWithAppleButton()
                    SignInWithGoogleButton()
                }
                // Add space between Google button and login fields
                Spacer().frame(height: 24)
                // Username and password fields remain in their current position
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
                }
                // Update arrowFill as the user types password
                .onChange(of: password) { oldValue, newValue in
                    // Fill progress based on password length (max 1.0 at 8+ chars)
                    withAnimation(.easeOut(duration: 0.7)) {
                        arrowFill = min(CGFloat(newValue.count) / 8.0, 1.0)
                    }
                }
                // Login button arrow: straight, primary color, transparent background, shine and shadow pop when password is typed (always animating for testing)
                HStack {
                    Spacer()
                    if !password.isEmpty || true { // keep always visible for testing
                        Button(action: { authManager.isAuthenticated = true }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.clear)
                                    .frame(width: 64, height: 64)
                                    .shadow(color: NuraColors.primary.opacity(0.18), radius: 10, x: 0, y: 4)
                                // Arrow with shine and pop
                                Image(systemName: "arrow.right")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(NuraColors.primary)
                                    .modifier(ShineAndPopEffect(animate: animateArrow))
                            }
                        }
                        .frame(width: 64, height: 64)
                        .padding(.trailing, 36)
                        .padding(.top, 4)
                        .onAppear {
                            animateArrow = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                                animateArrow = false
                            }
                        }
                    }
                }
                Spacer().frame(height: 8)
                // Animated heart above the quote
                VStack(spacing: 8) {
                    AnimatedHeartView(show: $showHeart)
                        .frame(width: 48, height: 48)
                        .padding(.bottom, 2)
                    Text("unlock the next you")
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

// HandwrittenArrow shape
struct HandwrittenArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Elegant, professional, hand-drawn right arrow
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.5))
        path.addCurve(to: CGPoint(x: w * 0.75, y: h * 0.5),
                      control1: CGPoint(x: w * 0.35, y: h * 0.15),
                      control2: CGPoint(x: w * 0.55, y: h * 0.85))
        path.move(to: CGPoint(x: w * 0.55, y: h * 0.32))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.68))
        return path
    }
} 

// Shine and pop effect modifier
struct ShineAndPopEffect: ViewModifier {
    var animate: Bool
    @State private var shine: CGFloat = 0.0
    @State private var pop: CGFloat = 1.0
    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.12 : 1.0)
            .shadow(color: NuraColors.primary.opacity(animate ? 0.35 : 0.18), radius: animate ? 18 : 10, x: 0, y: 4)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.0), Color.white.opacity(0.5), Color.white.opacity(0.0)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .blendMode(.plusLighter)
                .mask(
                    Rectangle()
                        .frame(width: animate ? 44 : 0, height: 44)
                        .offset(x: animate ? 0 : -44)
                        .animation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: false), value: animate)
                )
            )
    }
} 