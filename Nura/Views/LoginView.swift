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
            // Blurred, full-screen background image
            Image("login_background")
                .resizable()
                .scaledToFill()
                .blur(radius: 8)
                .ignoresSafeArea()
            // Semi-transparent black overlay for contrast
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            // Centered login card
            LoginCardView(
                showSignUp: $showSignUp,
                showForgotPassword: $showForgotPassword,
                email: $email,
                password: $password,
                arrowFill: $arrowFill,
                animateArrow: $animateArrow,
                showHeart: $showHeart
            )
        }
        .sheet(isPresented: $showSignUp) {
            Text("Sign up flow coming soon!")
        }
        .sheet(isPresented: $showForgotPassword) {
            Text("Forgot password flow coming soon!")
        }
    }
}

private struct LoginCardView: View {
    @Binding var showSignUp: Bool
    @Binding var showForgotPassword: Bool
    @Binding var email: String
    @Binding var password: String
    @Binding var arrowFill: CGFloat
    @Binding var animateArrow: Bool
    @Binding var showHeart: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    var body: some View {
        VStack(spacing: 0) {
            // Title as floater (just floating text)
            HStack {
                Spacer()
                Text("nura.")
                    .font(.custom("DancingScript-Bold", size: 76)) // Increased font size
                    .foregroundColor(NuraColors.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .kerning(2)
                    .shadow(color: NuraColors.primary.opacity(0.18), radius: 8, x: 0, y: 3)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 8)
                Spacer()
            }
            .padding(.top, 92) // Move title even lower for better centering
            Spacer(minLength: 12)
            // Login elements stacked above the icon/quote
            VStack(spacing: 18) {
                SignInButtonsView(email: $email, password: $password)
                LoginFieldsView(email: $email, password: $password)
                // Sign up and Forgot password below fields, styled subtly
                HStack(spacing: 16) {
                    Button("Sign up") { showSignUp = true }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(NuraColors.secondary)
                    Button("Forgot password") { showForgotPassword = true }
                        .font(.caption)
                        .foregroundColor(NuraColors.accent)
                }
                .padding(.top, 2)
                // Move arrow higher and a bit to the left, below forgot password row
                HStack {
                    Spacer(minLength: 0)
                    LoginArrowView(password: $password, arrowFill: $arrowFill, animateArrow: $animateArrow)
                        .padding(.leading, 32) // Move arrow a bit to the left
                    Spacer()
                }
                .padding(.top, -8) // Move arrow higher (closer to forgot password)
                .padding(.bottom, 4) // minimal gap above icon
            }
            .padding(.bottom, 0)
            // Animated heart above the quote
            VStack(spacing: 8) {
                AnimatedHeartView(show: $showHeart)
                    .frame(width: 48, height: 48)
                    .padding(.bottom, 2)
                    .foregroundColor(NuraColors.taupe)
                Text("unlock the next you")
                    .font(.footnote)
                    .foregroundColor(NuraColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        showHeart = true
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 0)
        .padding(.bottom, 0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .foregroundColor(NuraColors.textPrimary)
    }
}

private struct SignInButtonsView: View {
    @Binding var email: String
    @Binding var password: String
    var body: some View {
        VStack(spacing: 10) {
            Button(action: { /* Apple sign-in action */ }) {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black.opacity(0.85))
                    Text("Sign in with Apple")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.black.opacity(0.85))
                }
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(PlainButtonStyle())
            .background(
                LinearGradient(gradient: Gradient(colors: [Color(red: 0.99, green: 0.99, blue: 0.97), Color(red: 0.95, green: 0.95, blue: 0.93)]), startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(22)
            .shadow(color: Color.black.opacity(0.07), radius: 10, x: 0, y: 4)
            .frame(maxWidth: 300)
            .scaleEffect(1.0)
            .contentShape(RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 0)
            .animation(.easeInOut(duration: 0.15), value: false)
            Button(action: { /* Google sign-in action */ }) {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Sign in with Google")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(PlainButtonStyle())
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.black, Color(red: 0.13, green: 0.13, blue: 0.13)]), startPoint: .top, endPoint: .bottom)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
            )
            .cornerRadius(22)
            .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 4)
            .frame(maxWidth: 300)
            .scaleEffect(1.0)
            .contentShape(RoundedRectangle(cornerRadius: 22))
            .padding(.horizontal, 0)
            .animation(.easeInOut(duration: 0.15), value: false)
        }
        .padding(.top, 8)
    }
}

private struct LoginFieldsView: View {
    @Binding var email: String
    @Binding var password: String
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(NuraColors.card.opacity(0.12)) // Lighten the bubble
                    .shadow(color: NuraColors.primary.opacity(0.06), radius: 10, x: 0, y: 4)
                TextField("", text: $email)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 18)
                    .foregroundColor(NuraColors.textPrimary)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .accentColor(NuraColors.primary)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .placeholder(when: email.isEmpty) {
                        Text("Email")
                            .foregroundColor(Color.gray.opacity(0.55))
                            .italic()
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .padding(.horizontal, 18)
                    }
            }
            .frame(maxWidth: 300)
            .frame(height: 48)
            .padding(.horizontal, 0)
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(NuraColors.card.opacity(0.12)) // Lighten the bubble
                    .shadow(color: NuraColors.primary.opacity(0.06), radius: 10, x: 0, y: 4)
                SecureField("", text: $password)
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 18)
                    .foregroundColor(NuraColors.textPrimary)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .accentColor(NuraColors.primary)
                    .placeholder(when: password.isEmpty) {
                        Text("Password")
                            .foregroundColor(Color.gray.opacity(0.55))
                            .italic()
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .padding(.horizontal, 18)
                    }
            }
            .frame(maxWidth: 300)
            .frame(height: 48)
            .padding(.horizontal, 0)
        }
    }
}

private struct LoginArrowView: View {
    @Binding var password: String
    @Binding var arrowFill: CGFloat
    @Binding var animateArrow: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    var body: some View {
        Spacer().frame(height: 18)
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
                            .foregroundColor(NuraColors.primary) // taupe arrow
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
// Update the sign-in buttons to be content-sized and centered
struct NuraAppleButton: View {
    var body: some View {
        Button(action: { /* Apple login logic */ }) {
            HStack(spacing: 8) {
                Image(systemName: "applelogo")
                    .font(.system(size: 16, weight: .medium))
                Text("Sign in with Apple")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(NuraColors.background)
            .padding(.vertical, 7)
            .padding(.horizontal, 18)
            .background(Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NuraGoogleButton: View {
    var body: some View {
        Button(action: { /* Google login logic */ }) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                Text("Sign in with Google")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundColor(NuraColors.textPrimary)
            .padding(.vertical, 7)
            .padding(.horizontal, 18)
            .background(Color.clear)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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

// Custom placeholder modifier for styled placeholder text
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 