import SwiftUI

struct ComicBookPremiumBanner: View {
    let feature: UserTierManager.PremiumFeature
    let userTierManager: UserTierManager
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    
    @EnvironmentObject var appearanceManager: AppearanceManager
    @State private var isVisible = false
    
    var body: some View {
        let isDark = appearanceManager.isDarkMode
        
        ZStack {
            // Semi-transparent background overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissBanner()
                }
            
            // Comic book speech bubble
            VStack(spacing: 0) {
                // Main bubble content
                VStack(spacing: 16) {
                    // Icon and title
                    HStack(spacing: 12) {
                        Image(systemName: feature.icon)
                            .font(.title2)
                            .foregroundColor(.orange)
                        
                        Text(feature.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : NuraColors.textPrimary)
                    }
                    
                    // Description
                    Text(userTierManager.getUpgradePrompt(for: feature))
                        .font(.subheadline)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    
                    // Upgrade button
                    Button(action: {
                        onUpgrade()
                        dismissBanner()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.subheadline)
                            Text("Upgrade to Premium")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isDark ? NuraColors.cardDark : Color.white)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                
                // Speech bubble tail pointing down
                Triangle()
                    .fill(isDark ? NuraColors.cardDark : Color.white)
                    .frame(width: 20, height: 12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .offset(y: -1)
            }
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.3)) {
                isVisible = true
            }
        }
    }
    
    private func dismissBanner() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }
}

// Custom triangle shape for speech bubble tail
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// View modifier for easy usage
struct ComicBookPremiumBannerModifier: ViewModifier {
    let userTierManager: UserTierManager
    let feature: UserTierManager.PremiumFeature
    let showBanner: Bool
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if showBanner {
                ComicBookPremiumBanner(
                    feature: feature,
                    userTierManager: userTierManager,
                    onUpgrade: onUpgrade,
                    onDismiss: onDismiss
                )
            }
        }
    }
}

extension View {
    func comicBookPremiumBanner(
        userTierManager: UserTierManager,
        feature: UserTierManager.PremiumFeature,
        showBanner: Bool,
        onUpgrade: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) -> some View {
        self.modifier(ComicBookPremiumBannerModifier(
            userTierManager: userTierManager,
            feature: feature,
            showBanner: showBanner,
            onUpgrade: onUpgrade,
            onDismiss: onDismiss
        ))
    }
} 