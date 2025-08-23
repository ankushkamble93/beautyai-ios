import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var routineOverrideManager: RoutineOverrideManager
    @StateObject private var streakManager = StreakManager.shared
    @State private var selectedTab = 0
    @State private var isTabBarVisible = true
    @State private var fadeOutWorkItem: DispatchWorkItem?
    
    var body: some View {
        ZStack {
            Color(red: 31/255, green: 29/255, blue: 27/255).ignoresSafeArea()
            if authManager.isAuthenticated {
                if let profile = authManager.userProfile, !profile.onboarding_complete {
                    // Show onboarding questionnaire if not completed
                    OnboardingQuestionnaireView()
                        .environmentObject(authManager)
                } else {
                    // Show main app with tab bar if onboarding is complete
                    TabView(selection: $selectedTab) {
                        DashboardView()
                            .environmentObject(authManager)
                            .environmentObject(skinAnalysisManager)
                            .environmentObject(appearanceManager)
                            .environmentObject(streakManager)
                            .environmentObject(routineOverrideManager)
                            .tag(0)
                        SkinAnalysisView()
                            .environmentObject(authManager)
                            .environmentObject(skinAnalysisManager)
                            .tag(1)
                        ChatView()
                            .environmentObject(authManager)
                            .environmentObject(routineOverrideManager)
                            .tag(2)
                        ProfileView()
                            .environmentObject(authManager)
                            .tag(3)
                    }
                    .id(appearanceManager.colorSchemePreference)
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
                    // Listen for programmatic tab switches (e.g., from Dashboard Analyze button)
                    .onReceive(NotificationCenter.default.publisher(for: .nuraSwitchTab)) { notification in
                        if let targetIndex = notification.object as? Int {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                selectedTab = targetIndex
                            }
                        }
                    }
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
        .foregroundColor(isSelected ? NuraColors.primary : NuraColors.textSecondary)
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
            .stroke(isSelected ? NuraColors.primary : NuraColors.textSecondary, lineWidth: 2.2)
            // Minimal face
            Circle()
                .frame(width: size*0.11, height: size*0.11)
                .offset(x: -size*0.13, y: size*0.29)
                .foregroundColor(isSelected ? NuraColors.primary : NuraColors.textSecondary)
            Circle()
                .frame(width: size*0.11, height: size*0.11)
                .offset(x: size*0.13, y: size*0.29)
                .foregroundColor(isSelected ? NuraColors.primary : NuraColors.textSecondary)
            Path { path in
                path.move(to: CGPoint(x: size*0.42, y: size*0.71))
                path.addQuadCurve(to: CGPoint(x: size*0.58, y: size*0.71), control: CGPoint(x: size/2, y: size*0.79))
            }
            .stroke(isSelected ? NuraColors.primary : NuraColors.textSecondary, lineWidth: 1.2)
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
                .stroke(isSelected ? NuraColors.primary : NuraColors.textSecondary, lineWidth: 2.2)
                .frame(width: size*0.83, height: size*0.67)
            Path { path in
                path.move(to: CGPoint(x: size/2, y: size*0.83))
                path.addLine(to: CGPoint(x: size*0.58, y: size*0.67))
                path.addLine(to: CGPoint(x: size*0.42, y: size*0.67))
                path.closeSubpath()
            }
            .fill(isSelected ? NuraColors.primary : NuraColors.textSecondary)
            // Sparkle
            if isSelected {
                Path { path in
                    path.move(to: CGPoint(x: size*0.75, y: size*0.33))
                    path.addLine(to: CGPoint(x: size*0.75, y: size*0.46))
                    path.move(to: CGPoint(x: size*0.69, y: size*0.39))
                    path.addLine(to: CGPoint(x: size*0.81, y: size*0.39))
                }
                .stroke(NuraColors.sand, lineWidth: 1.2)
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
                .stroke(isSelected ? NuraColors.primary : NuraColors.textSecondary, lineWidth: 2.2)
                .frame(width: size*0.67, height: size*0.42)
                .offset(y: size*0.25)
            Circle()
                .stroke(isSelected ? NuraColors.primary : NuraColors.textSecondary, lineWidth: 2.2)
                .frame(width: size*0.33, height: size*0.33)
                .offset(y: -size*0.08)
        }
        .frame(width: size, height: size)
    }
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
