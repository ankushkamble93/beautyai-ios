import SwiftUI

struct SkinAnalysisView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Skin Analysis")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Upload photos for AI analysis")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Analysis")
        }
    }
}
