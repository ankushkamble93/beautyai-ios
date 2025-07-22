import SwiftUI
// import Firebase // Temporarily disabled until Firebase is set up

@main
struct NuraApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var skinAnalysisManager = SkinAnalysisManager()
    @StateObject private var chatManager = ChatManager()
    
    init() {
        // FirebaseApp.configure() // Temporarily disabled until Firebase is set up
    }
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
                    .environmentObject(skinAnalysisManager)
                    .environmentObject(chatManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
                    .environmentObject(skinAnalysisManager)
                    .environmentObject(chatManager)
            }
        }
    }
}
