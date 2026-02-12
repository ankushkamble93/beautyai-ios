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
    @StateObject private var routineOverrideManager = RoutineOverrideManager()
    @AppStorage("colorSchemePreference") private var colorSchemePreference: String = "light"
    
    init() {
        // FirebaseApp.configure() // Temporarily disabled until Firebase is set up
        let authManager = AuthenticationManager.shared
        self._userTierManager = StateObject(wrappedValue: UserTierManager(authManager: authManager))
        self._skinAnalysisManager = StateObject(wrappedValue: SkinAnalysisManager(userTierManager: UserTierManager(authManager: authManager)))
        // Setup Google CSE credentials for development
        GoogleAPIConfig.setupDevelopmentCredentials()
        // Diagnostic: confirm Google CSE keys presence at launch (no UI changes)
        let hasCSEKey = (GoogleAPIConfig.apiKey?.isEmpty == false)
        let hasCSEId = (GoogleAPIConfig.searchEngineId?.isEmpty == false)
        print("🔎 [Diag] Google CSE configured? key=\(hasCSEKey) id=\(hasCSEId)")
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
                        .environmentObject(routineOverrideManager)
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
                        .onReceive(authManager.$isAuthenticated) { isAuthenticated in
                            if isAuthenticated {
                                print("🔍 NuraApp: User authenticated, ensuring recommendations are loaded")
                                skinAnalysisManager.loadCachedRecommendations()
                                chatManager.absorb(skinAnalysisManager.recommendations)
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
                        .environmentObject(routineOverrideManager)
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
                        .onReceive(authManager.$isAuthenticated) { isAuthenticated in
                            if isAuthenticated {
                                print("🔍 NuraApp: User authenticated, ensuring recommendations are loaded")
                                skinAnalysisManager.loadCachedRecommendations()
                                chatManager.absorb(skinAnalysisManager.recommendations)
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
                print("🔗 URL scheme: \(url.scheme ?? "nil")")
                print("🔗 URL host: \(url.host ?? "nil")")
                print("🔗 URL path: \(url.path)")
                print("🔗 URL query: \(url.query ?? "nil")")
                print("🔗 Full URL string: \(url.absoluteString)")
                
                // Supabase OAuth callbacks use the custom scheme com.nura://
                // Route those to AuthenticationManager so it can exchange the code for a session.
                // Other custom URLs (like nura://reset-password) continue to flow through URLHandler.
                if url.scheme == "com.nura" {
                    print("🔗 Routing com.nura:// URL to AuthenticationManager.handleDeepLink")
                    Task {
                        await authManager.handleDeepLink(url: url)
                    }
                } else {
                    print("🔗 Routing URL to URLHandler")
                    urlHandler.handleURL(url)
                }
            }
        }
    }
}
