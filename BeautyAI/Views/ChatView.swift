import SwiftUI

struct ChatView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("AI Chat")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Chat with your AI skin assistant")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("AI Chat")
        }
    }
}
