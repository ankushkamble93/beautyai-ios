import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    @State private var isTabBarVisible = true
    @State private var fadeOutWorkItem: DispatchWorkItem?
    
    var body: some View {
        ZStack {
            Color(red: 31/255, green: 29/255, blue: 27/255).ignoresSafeArea()
            if authManager.isAuthenticated {
                TabView(selection: $selectedTab) {
                    DashboardView().tag(0)
                    SkinAnalysisView().tag(1)
                    ChatView().tag(2)
                    ProfileView().tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: [.top, .bottom])
                .overlay(
                    CustomTabBar(selectedTab: $selectedTab)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 6)
                        .opacity(isTabBarVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: isTabBarVisible)
                        .ignoresSafeArea(edges: .bottom)
                        .allowsHitTesting(isTabBarVisible)
                        .zIndex(1)
                        .onAppear {
                            showTabBarWithFadeOut()
                        },
                    alignment: .bottom
                )
                .onChange(of: selectedTab) { _, _ in
                    showTabBarWithFadeOut()
                }
            } else {
                LoginView()
            }
        }
    }

    private func showTabBarWithFadeOut() {
        isTabBarVisible = true
        fadeOutWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            withAnimation {
                isTabBarVisible = false
            }
        }
        fadeOutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
}

// TabBarIcon wrapper for bounce animation
struct TabBarIcon<Content: View>: View {
    var selected: Bool
    var content: () -> Content
    @State private var bounce = false
    var body: some View {
        content()
            .scaleEffect(bounce ? 1.18 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: bounce)
            .onChange(of: selected) { _, newValue in
                if newValue {
                    bounce = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { bounce = false }
                }
            }
    }
}
// Dashboard icon: minimal bar chart
struct DashboardTabIcon: View {
    var isSelected: Bool
    var size: CGFloat = 24
    var body: some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2)
                .frame(width: size * 0.18, height: size * 0.42)
            RoundedRectangle(cornerRadius: 2)
                .frame(width: size * 0.18, height: size * 0.75)
            RoundedRectangle(cornerRadius: 2)
                .frame(width: size * 0.18, height: size * 0.58)
        }
        .foregroundColor(isSelected ? Color.softNavy : Color.slate)
        .frame(width: size, height: size)
    }
}
// Skin Analysis icon: stylized droplet with a face
struct SkinAnalysisTabIcon: View {
    var isSelected: Bool
    var size: CGFloat = 24
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: size/2, y: size*0.125))
                path.addQuadCurve(to: CGPoint(x: size*0.83, y: size*0.5), control: CGPoint(x: size*0.92, y: size*0.25))
                path.addQuadCurve(to: CGPoint(x: size/2, y: size*0.92), control: CGPoint(x: size*0.83, y: size*0.92))
                path.addQuadCurve(to: CGPoint(x: size*0.17, y: size*0.5), control: CGPoint(x: size*0.17, y: size*0.92))
                path.addQuadCurve(to: CGPoint(x: size/2, y: size*0.125), control: CGPoint(x: size*0.08, y: size*0.25))
            }
            .stroke(isSelected ? Color.softNavy : Color.slate, lineWidth: 2.2)
            // Minimal face
            Circle().frame(width: size*0.11, height: size*0.11).offset(x: -size*0.13, y: size*0.29).foregroundColor(isSelected ? Color.softNavy : Color.slate)
            Circle().frame(width: size*0.11, height: size*0.11).offset(x: size*0.13, y: size*0.29).foregroundColor(isSelected ? Color.softNavy : Color.slate)
            Path { path in
                path.move(to: CGPoint(x: size*0.42, y: size*0.71))
                path.addQuadCurve(to: CGPoint(x: size*0.58, y: size*0.71), control: CGPoint(x: size/2, y: size*0.79))
            }.stroke(isSelected ? Color.softNavy : Color.slate, lineWidth: 1.2)
        }
        .frame(width: size, height: size)
    }
}
// AI Chat icon: speech bubble with sparkle
struct AIChatTabIcon: View {
    var isSelected: Bool
    var size: CGFloat = 24
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size*0.33)
                .stroke(isSelected ? Color.softNavy : Color.slate, lineWidth: 2.2)
                .frame(width: size*0.83, height: size*0.67)
            Path { path in
                path.move(to: CGPoint(x: size/2, y: size*0.83))
                path.addLine(to: CGPoint(x: size*0.58, y: size*0.67))
                path.addLine(to: CGPoint(x: size*0.42, y: size*0.67))
                path.closeSubpath()
            }.fill(isSelected ? Color.softNavy : Color.slate)
            // Sparkle
            if isSelected {
                Path { path in
                    path.move(to: CGPoint(x: size*0.75, y: size*0.33))
                    path.addLine(to: CGPoint(x: size*0.75, y: size*0.46))
                    path.move(to: CGPoint(x: size*0.69, y: size*0.39))
                    path.addLine(to: CGPoint(x: size*0.81, y: size*0.39))
                }.stroke(Color.sand, lineWidth: 1.2)
            }
        }
        .frame(width: size, height: size)
    }
}
// Profile icon: abstract, non-gendered human silhouette
struct ProfileTabIcon: View {
    var isSelected: Bool
    var size: CGFloat = 24
    var body: some View {
        ZStack {
            Ellipse()
                .stroke(isSelected ? Color.softNavy : Color.slate, lineWidth: 2.2)
                .frame(width: size*0.67, height: size*0.42).offset(y: size*0.25)
            Circle()
                .stroke(isSelected ? Color.softNavy : Color.slate, lineWidth: 2.2)
                .frame(width: size*0.33, height: size*0.33).offset(y: -size*0.08)
        }
        .frame(width: size, height: size)
    }
}
// Custom colors
extension Color {
    static let stone = Color(red: 0.66, green: 0.66, blue: 0.66)
    static let slate = Color(red: 0.43, green: 0.46, blue: 0.51)
    static let sand = Color(red: 0.90, green: 0.85, blue: 0.77)
    static let softNavy = Color(red: 0.23, green: 0.26, blue: 0.34)
}

// CustomTabBar implementation
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<4) { idx in
                Spacer(minLength: 0)
                Button(action: { selectedTab = idx }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.72))
                            .frame(width: 54, height: 54)
                            .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
                        Circle()
                            .stroke(Color.white.opacity(0.0), lineWidth: 2.2) // transparent border
                            .frame(width: 54, height: 54)
                        Group {
                            if idx == 0 {
                                DashboardTabIcon(isSelected: selectedTab == 0, size: 28)
                            } else if idx == 1 {
                                SkinAnalysisTabIcon(isSelected: selectedTab == 1, size: 28)
                            } else if idx == 2 {
                                AIChatTabIcon(isSelected: selectedTab == 2, size: 28)
                            } else {
                                ProfileTabIcon(isSelected: selectedTab == 3, size: 28)
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 0)
        .padding(.vertical, 0)
        // No background, no extra padding
    }
}
