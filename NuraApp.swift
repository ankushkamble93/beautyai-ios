import SwiftUI

@main
struct NuraApp: App {
    @StateObject var authManager = AuthenticationManager.shared
    @StateObject var skinAnalysisManager = SkinAnalysisManager()
    @StateObject var appearanceManager = AppearanceManager()
    
    var body: some Scene {
        WindowGroup {
            RootFlowView(
                authManager: authManager,
                skinAnalysisManager: skinAnalysisManager,
                appearanceManager: appearanceManager
            )
            .environmentObject(authManager)
            .environmentObject(skinAnalysisManager)
            .environmentObject(appearanceManager)
            .onOpenURL { url in
                // Handle the deep link asynchronously
                Task {
                    await authManager.handleDeepLink(url: url)
                }
            }
        }
    }
}

struct RootFlowView: View {
    @ObservedObject var authManager: AuthenticationManager
    @ObservedObject var skinAnalysisManager: SkinAnalysisManager
    @ObservedObject var appearanceManager: AppearanceManager
    @State private var refreshTrigger = 0
    
    init(authManager: AuthenticationManager, skinAnalysisManager: SkinAnalysisManager, appearanceManager: AppearanceManager) {
        self.authManager = authManager
        self.skinAnalysisManager = skinAnalysisManager
        self.appearanceManager = appearanceManager
        print("🔍 RootFlowView: Initialized with all managers")
    }
    
    var body: some View {
        let _ = print("🔍 RootFlowView: Body called - isInitialized: \(authManager.isInitialized), isAuthenticated: \(authManager.isAuthenticated), userProfile: \(authManager.userProfile != nil), onboarding_complete: \(authManager.userProfile?.onboarding_complete ?? false)")
        
        // Force view refresh when any relevant state changes
        let _ = authManager.isAuthenticated
        let _ = authManager.userProfile?.onboarding_complete
        
        return ZStack {
            if !authManager.isInitialized {
                // Show loading while auth manager initializes
                VStack {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .mint))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
            } else if authManager.isAuthenticated {
                if let profile = authManager.userProfile {
                    print("🔍 Navigation Debug: User profile found")
                    print("🔍 Navigation Debug: onboarding_complete = \(profile.onboarding_complete)")
                    print("🔍 Navigation Debug: isAuthenticated = \(authManager.isAuthenticated)")
                    print("🔍 Navigation Debug: User ID = \(profile.id)")
                    print("🔍 Navigation Debug: User email = \(profile.email)")
                    
                    // Proper navigation logic
                    if !profile.onboarding_complete {
                        print("🔍 Navigation Debug: onboarding_complete is FALSE - Showing OnboardingQuestionnaireView")
                        OnboardingQuestionnaireView()
                            .onAppear {
                                print("🔍 OnboardingQuestionnaireView: Actually appeared!")
                            }
                    } else {
                        print("🔍 Navigation Debug: onboarding_complete is TRUE - Showing DashboardView")
                        DashboardView()
                            .environmentObject(skinAnalysisManager)
                            .environmentObject(appearanceManager)
                            .onAppear {
                                print("🔍 DashboardView: Actually appeared!")
                            }
                    }
                    
                } else {
                    print("🔍 Navigation Debug: No user profile found, showing loading...")
                    // Show loading while we wait for profile to load
                    VStack {
                        ProgressView("Loading profile...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .mint))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
                }
            } else {
                // Only show LoginView if we're certain there's no cached session
                // This prevents the flash when there's a valid cached session
                if authManager.session == nil {
                    LoginView()
                } else {
                    // Show loading while we check the session
                    VStack {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .mint))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
                }
            }
        }
        .onAppear {
            print("🔍 RootFlowView: Appeared")
        }
        .onChange(of: authManager.userProfile?.id) { oldValue, newValue in
            print("🔍 RootFlowView: User profile ID changed from \(oldValue ?? "nil") to \(newValue ?? "nil")")
            refreshTrigger += 1
        }
        .onChange(of: authManager.userProfile?.onboarding_complete) { oldValue, newValue in
            print("🔍 RootFlowView: Onboarding complete changed from \(oldValue ?? false) to \(newValue ?? false)")
            refreshTrigger += 1
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            print("🔍 RootFlowView: isAuthenticated changed from \(oldValue) to \(newValue)")
            refreshTrigger += 1
        }
        .onChange(of: authManager.userProfile) { oldValue, newValue in
            print("🔍 RootFlowView: userProfile changed from \(oldValue?.id ?? "nil") to \(newValue?.id ?? "nil")")
            print("🔍 RootFlowView: old onboarding_complete = \(oldValue?.onboarding_complete ?? false)")
            print("🔍 RootFlowView: new onboarding_complete = \(newValue?.onboarding_complete ?? false)")
            refreshTrigger += 1
        }
        .onChange(of: authManager.userProfile?.onboarding_complete) { oldValue, newValue in
            print("🔍 RootFlowView: onboarding_complete changed from \(oldValue ?? false) to \(newValue ?? false)")
            refreshTrigger += 1
        }
        .id(refreshTrigger)
    }
} 