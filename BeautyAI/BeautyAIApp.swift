import SwiftUI
import Firebase

@main
struct BeautyAIApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var skinAnalysisManager = SkinAnalysisManager()
    @StateObject private var chatManager = ChatManager()
    
    init() {
        FirebaseApp.configure()
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
