import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Profile")
                    .font(.title)
                    .fontWeight(.bold)
                
                Button("Sign Out") {
                    authManager.signOut()
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .navigationTitle("Profile")
        }
    }
}
