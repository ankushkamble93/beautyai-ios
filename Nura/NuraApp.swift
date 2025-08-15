import SwiftUI
// import Firebase // Temporarily disabled until Firebase is set up

@main
struct NuraApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var skinAnalysisManager: SkinAnalysisManager
    @StateObject private var chatManager = ChatManager()
    @StateObject private var shareManager = ShareManager()
    @StateObject private var skinDiaryManager = SkinDiaryManager()
    @StateObject private var appearanceManager = AppearanceManager()
    @StateObject private var urlHandler = URLHandler.shared
    @StateObject private var userTierManager: UserTierManager
    @AppStorage("colorSchemePreference") private var colorSchemePreference: String = "light"
    
    init() {
        // FirebaseApp.configure() // Temporarily disabled until Firebase is set up
        let authManager = AuthenticationManager.shared
        self._userTierManager = StateObject(wrappedValue: UserTierManager(authManager: authManager))
        self._skinAnalysisManager = StateObject(wrappedValue: SkinAnalysisManager(userTierManager: UserTierManager(authManager: authManager)))
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(skinAnalysisManager)
                        .environmentObject(chatManager)
                        .environmentObject(shareManager)
                        .environmentObject(skinDiaryManager)
                        .environmentObject(appearanceManager)
                        .environmentObject(userTierManager)
                        .onAppear {
                            // On app open, let chat absorb any cached recommendations
                            chatManager.absorb(skinAnalysisManager.recommendations)
                            chatManager.absorbAnalysisSummary(skinAnalysisManager.analysisResults)
                            skinAnalysisManager.loadCachedRecommendations()
                            chatManager.absorb(skinAnalysisManager.recommendations)
                            NotificationCenter.default.addObserver(forName: .nuraAnalysisCompleted, object: nil, queue: .main) { note in
                                let result = note.object as? SkinAnalysisResult
                                chatManager.absorbAnalysisSummary(result)
                            }
                            NotificationCenter.default.addObserver(forName: .nuraRecommendationsUpdated, object: nil, queue: .main) { note in
                                let recs = note.object as? SkincareRecommendations
                                chatManager.absorb(recs)
                            }
                        }
                } else {
                    LoginView()
                        .environmentObject(authManager)
                        .environmentObject(skinAnalysisManager)
                        .environmentObject(chatManager)
                        .environmentObject(shareManager)
                        .environmentObject(skinDiaryManager)
                        .environmentObject(appearanceManager)
                        .environmentObject(userTierManager)
                        .onAppear {
                            chatManager.absorb(skinAnalysisManager.recommendations)
                            chatManager.absorbAnalysisSummary(skinAnalysisManager.analysisResults)
                            skinAnalysisManager.loadCachedRecommendations()
                            chatManager.absorb(skinAnalysisManager.recommendations)
                            NotificationCenter.default.addObserver(forName: .nuraAnalysisCompleted, object: nil, queue: .main) { note in
                                let result = note.object as? SkinAnalysisResult
                                chatManager.absorbAnalysisSummary(result)
                            }
                            NotificationCenter.default.addObserver(forName: .nuraRecommendationsUpdated, object: nil, queue: .main) { note in
                                let recs = note.object as? SkincareRecommendations
                                chatManager.absorb(recs)
                            }
                        }
                }
            }
            .preferredColorScheme(
                authManager.isAuthenticated ?
                    (appearanceManager.colorSchemePreference == "dark" ? .dark :
                        (appearanceManager.colorSchemePreference == "light" ? .light : nil))
                    : .light
            )
            .environmentObject(urlHandler)
            .onOpenURL { url in
                print("🔗 NuraApp: Received URL: \(url)")
                urlHandler.handleURL(url)
            }
        }
    }
}
