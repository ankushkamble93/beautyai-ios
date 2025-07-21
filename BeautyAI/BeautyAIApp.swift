import SwiftUI
// import Firebase // Temporarily disabled until Firebase is set up

@main
struct BeautyAIApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var skinAnalysisManager = SkinAnalysisManager()
    @StateObject private var chatManager = ChatManager()
    
    init() {
        // FirebaseApp.configure() // Temporarily disabled until Firebase is set up
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(skinAnalysisManager)
                .environmentObject(chatManager)
        }
    }
}
