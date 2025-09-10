import SwiftUI

struct UpgradePromptView: View {
    let feature: UserTierManager.PremiumFeature
    let userTierManager: UserTierManager
    let onUpgrade: () -> Void
    
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        let isDark = appearanceManager.isDarkMode
        
        VStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.title)
                .foregroundColor(.orange)
            
            Text(feature.displayName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isDark ? NuraColors.textPrimaryDark : NuraColors.textPrimary)
            
            Text(userTierManager.getUpgradePrompt(for: feature))
                .font(.subheadline)
                .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onUpgrade) {
                HStack {
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
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PremiumFeatureBlurView<Content: View>: View {
    let userTierManager: UserTierManager
    let feature: UserTierManager.PremiumFeature
    let showUpgradePrompt: Bool
    let onUpgrade: () -> Void
    let content: Content
    
    init(
        userTierManager: UserTierManager,
        feature: UserTierManager.PremiumFeature,
        showUpgradePrompt: Bool = true,
        onUpgrade: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.userTierManager = userTierManager
        self.feature = feature
        self.showUpgradePrompt = showUpgradePrompt
        self.onUpgrade = onUpgrade
        self.content = content()
    }
    
    var body: some View {
        Group {
            if userTierManager.isPremium {
                content
            } else {
                VStack(spacing: 16) {
                    content
                        .blur(radius: 3)
                        .disabled(true)
                    
                    if showUpgradePrompt {
                        UpgradePromptView(
                            feature: feature,
                            userTierManager: userTierManager,
                            onUpgrade: onUpgrade
                        )
                    }
                }
            }
        }
    }
}

extension View {
    func premiumFeatureBlur(
        userTierManager: UserTierManager,
        feature: UserTierManager.PremiumFeature,
        showUpgradePrompt: Bool = true,
        onUpgrade: @escaping () -> Void
    ) -> some View {
        PremiumFeatureBlurView(
            userTierManager: userTierManager,
            feature: feature,
            showUpgradePrompt: showUpgradePrompt,
            onUpgrade: onUpgrade
        ) {
            self
        }
    }
} 