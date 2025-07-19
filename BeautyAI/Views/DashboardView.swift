import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Dashboard")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Welcome to BeautyAI Dashboard")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Dashboard")
        }
    }
}
