import SwiftUI
// import Firebase // Temporarily disabled until Firebase is set up

@main
struct NuraApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var skinAnalysisManager = SkinAnalysisManager()
    @StateObject private var chatManager = ChatManager()
    @StateObject private var appearanceManager = AppearanceManager()
    @AppStorage("colorSchemePreference") private var colorSchemePreference: String = "system"
    
    init() {
        // FirebaseApp.configure() // Temporarily disabled until Firebase is set up
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(skinAnalysisManager)
                        .environmentObject(chatManager)
                        .environmentObject(appearanceManager)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                        .environmentObject(skinAnalysisManager)
                        .environmentObject(chatManager)
                        .environmentObject(appearanceManager)
                }
            }
            .preferredColorScheme(
                authManager.isAuthenticated ?
                    (appearanceManager.colorSchemePreference == "dark" ? .dark :
                        (appearanceManager.colorSchemePreference == "light" ? .light : nil))
                    : .light
            )
        }
    }
}
