import SwiftUI

struct ShareOptionsView: View {
    let analysis: SkinAnalysisResult
    let skinScore: Double
    @ObservedObject var shareManager: ShareManager
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Enhanced gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.6),
                    Color.purple.opacity(0.3),
                    Color.pink.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPresented = false
                }
            }
            
            // Share options card
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Share Your Results")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                // Share options
                VStack(spacing: 16) {
                    // Instagram
                    ShareOptionButton(
                        title: "Share to Instagram",
                        subtitle: "Post to your Instagram story",
                        icon: "camera.fill",
                        iconColor: .purple,
                        backgroundColor: LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ) {
                        shareManager.shareToInstagram()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                    
                    // Snapchat
                    ShareOptionButton(
                        title: "Share to Snapchat",
                        subtitle: "Send to your Snapchat story",
                        icon: "camera.fill",
                        iconColor: .yellow,
                        backgroundColor: LinearGradient(
                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ) {
                        shareManager.shareToSnapchat()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                    
                    // Text/Message
                    ShareOptionButton(
                        title: "Share via Text",
                        subtitle: "Send via Messages or other apps",
                        icon: "message.fill",
                        iconColor: .green,
                        backgroundColor: LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ) {
                        shareManager.shareToText()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                    
                    // General share
                    ShareOptionButton(
                        title: "More Options",
                        subtitle: "Share to other apps",
                        icon: "square.and.arrow.up.fill",
                        iconColor: .blue,
                        backgroundColor: LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.cyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ) {
                        shareManager.shareSkinAnalysisResult(analysis: analysis, skinScore: skinScore)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                }
            }
            .padding(24)
            .background(
                ZStack {
                    // Main background
                    Color(.systemBackground)
                    
                    // Subtle gradient overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.purple.opacity(0.05),
                            Color.pink.opacity(0.03)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
            .padding(.horizontal, 40)
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
        }
    }
}

struct ShareOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let backgroundColor: LinearGradient
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Share Button Component

struct ShareButton: View {
    let analysis: SkinAnalysisResult
    let skinScore: Double
    @EnvironmentObject var shareManager: ShareManager
    @State private var showShareOptions = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showShareOptions = true
            }
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.3))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .sheet(isPresented: $showShareOptions) {
            ShareOptionsView(
                analysis: analysis,
                skinScore: skinScore,
                shareManager: shareManager,
                isPresented: $showShareOptions
            )
        }
    }
} 