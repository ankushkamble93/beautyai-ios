import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    
    var body: some View {
        if authManager.isAuthenticated {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
                    .tag(0)
                
                SkinAnalysisView()
                    .tabItem {
                        Image(systemName: "camera.fill")
                        Text("Analysis")
                    }
                    .tag(1)
                
                ChatView()
                    .tabItem {
                        Image(systemName: "message.fill")
                        Text("AI Chat")
                    }
                    .tag(2)
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(3)
            }
            .accentColor(.purple)
        } else {
            AuthenticationView()
        }
    }
}
