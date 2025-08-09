import Foundation
import SwiftUI

@MainActor
class UserTierManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var currentUserProfile: UserProfile?
    
    enum Tier: String { case free, pro, proUnlimited }
    @Published var tier: Tier = .free
    
    private let authManager: AuthenticationManager
    
    init(authManager: AuthenticationManager) {
        self.authManager = authManager
        self.updatePremiumStatus()
        
        // Listen for user profile changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userProfileDidChange),
            name: .userProfileDidChange,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Premium Status Management
    
    func updatePremiumStatus() {
        if let profile = authManager.userProfile {
            self.currentUserProfile = profile
            // Prefer premium_tier (enum in Supabase). Fallback to legacy plan or premium bool
            if let tierValue = profile.premium_tier?.lowercased() {
                switch tierValue {
                case "pro_unlimited": tier = .proUnlimited; isPremium = true
                case "pro": tier = .pro; isPremium = true
                default: tier = .free; isPremium = false
                }
            } else if let plan = profile.plan?.lowercased() {
                switch plan {
                case "pro_unlimited": tier = .proUnlimited; isPremium = true
                case "pro": tier = .pro; isPremium = true
                default: tier = .free; isPremium = false
                }
            } else if let premiumText = profile.premium?.lowercased() {
                switch premiumText {
                case "pro_unlimited": tier = .proUnlimited; isPremium = true
                case "pro": tier = .pro; isPremium = true
                default: tier = .free; isPremium = false
                }
            } else {
                // Fallback when nothing is present
                self.isPremium = false
                self.tier = .free
            }
        } else {
            self.isPremium = false
            self.tier = .free
            self.currentUserProfile = nil
        }
    }
    
    @objc private func userProfileDidChange(_ notification: Notification) {
        Task { @MainActor in
            self.updatePremiumStatus()
            // Clear any cached analysis data when user changes
            self.clearCachedAnalysisData()
        }
    }
    
    /// Clear cached analysis data for the previous user
    private func clearCachedAnalysisData() {
        // This ensures a clean state when switching users
        // The new user will start with fresh daily limits
        print("🔄 UserTierManager: Cleared cached analysis data for user switch")
    }
    
    // MARK: - Feature Gates
    
    /// Check if user has access to premium chat features
    func hasPremiumChatAccess() -> Bool { return tier != .free }
    /// Check if user has access to advanced skin analysis
    func hasAdvancedSkinAnalysisAccess() -> Bool { return tier != .free }
    /// Check if user has access to personalized routines
    func hasPersonalizedRoutinesAccess() -> Bool { return tier != .free }
    /// Check if user has access to priority support
    func hasPrioritySupportAccess() -> Bool { return tier != .free }
    /// Check if user has access to unlimited skin analysis
    func hasUnlimitedAnalysisAccess() -> Bool { return tier == .proUnlimited }
    /// Check if user has access to advanced tracking features
    func hasAdvancedTrackingAccess() -> Bool { return tier != .free }
    
    // MARK: - Daily Analysis Limits
    
    private let userDefaults = UserDefaults.standard
    
    // Make keys user-specific to avoid cross-user caching
    private var analysisCountKey: String {
        guard let userId = authManager.userProfile?.id else { return "daily_analysis_count_default" }
        return "daily_analysis_count_\(userId)"
    }
    
    private var analysisDateKey: String {
        guard let userId = authManager.userProfile?.id else { return "daily_analysis_date_default" }
        return "daily_analysis_date_\(userId)"
    }
    
    /// Get the maximum daily analysis count for the user
    func getDailyAnalysisLimit() -> Int {
        switch tier {
            case .free: return 1
            case .pro: return 3
            case .proUnlimited: return Int.max
        }
    }
    
    /// Get the current daily analysis count
    func getCurrentDailyAnalysisCount() -> Int {
        if tier == .proUnlimited { return 0 } // unlimited, we do not track meaningful limits
        let today = Calendar.current.startOfDay(for: Date())
        let lastAnalysisDate = userDefaults.object(forKey: analysisDateKey) as? Date ?? Date.distantPast
        let currentCount = userDefaults.integer(forKey: analysisCountKey)
        
        print("🔄 UserTierManager: User \(authManager.userProfile?.id ?? "unknown") - Current count: \(currentCount), Last date: \(lastAnalysisDate), Today: \(today)")
        
        // Reset count if it's a new day
        if !Calendar.current.isDate(lastAnalysisDate, inSameDayAs: today) {
            userDefaults.set(0, forKey: analysisCountKey)
            userDefaults.set(today, forKey: analysisDateKey)
            print("🔄 UserTierManager: Reset daily count for new day")
            return 0
        }
        
        return currentCount
    }
    
    /// Check if user can perform analysis today
    func canPerformAnalysis() -> Bool {
        if tier == .proUnlimited { return true }
        let currentCount = getCurrentDailyAnalysisCount()
        let limit = getDailyAnalysisLimit()
        return currentCount < limit
    }
    
    /// Increment the daily analysis count
    func incrementAnalysisCount() {
        guard tier != .proUnlimited else { return }
        let currentCount = getCurrentDailyAnalysisCount()
        let today = Calendar.current.startOfDay(for: Date())
        
        userDefaults.set(currentCount + 1, forKey: analysisCountKey)
        userDefaults.set(today, forKey: analysisDateKey)
        
        print("🔄 UserTierManager: Incremented analysis count for user \(authManager.userProfile?.id ?? "unknown") - New count: \(currentCount + 1)")
    }
    
    /// Get the next available analysis time
    func getNextAnalysisTime() -> Date {
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
    }
    
    // MARK: - Premium Feature Descriptions
    
    func getPremiumFeatureDescription(for feature: PremiumFeature) -> String {
        switch feature {
        case .premiumChat:
            return "Unlock unlimited AI conversations with personalized skincare advice"
        case .advancedSkinAnalysis:
            return "Get detailed skin condition analysis with professional-grade insights"
        case .personalizedRoutines:
            return "Receive custom skincare routines tailored to your unique skin profile"
        case .prioritySupport:
            return "Get priority customer support with faster response times"
        case .unlimitedAnalysis:
            return "Perform unlimited skin analysis sessions without daily limits"
        case .advancedTracking:
            return "Track your skin progress with advanced metrics and insights"
        }
    }
    
    // MARK: - Upgrade Prompts
    
    func getUpgradePrompt(for feature: PremiumFeature) -> String {
        switch feature {
        case .premiumChat:
            return "Upgrade to Nura Premium to unlock unlimited AI conversations with personalized skincare advice."
        case .advancedSkinAnalysis:
            return "Upgrade to Nura Premium for detailed skin condition analysis with professional-grade insights."
        case .personalizedRoutines:
            return "Upgrade to Nura Premium to receive custom skincare routines tailored to your unique skin profile."
        case .prioritySupport:
            return "Upgrade to Nura Premium for priority customer support with faster response times."
        case .unlimitedAnalysis:
            return "Upgrade to Nura Premium for unlimited skin analysis sessions without daily limits."
        case .advancedTracking:
            return "Upgrade to Nura Premium to track your skin progress with advanced metrics and insights."
        }
    }
    
    // MARK: - Upgrade Navigation
    
    func navigateToUpgrade() {
        // This will be handled by the calling view
        // Typically navigates to NuraProView or subscription screen
        print("🔄 UserTierManager: Navigate to upgrade requested")
    }
    
    // MARK: - Premium Features Enum
    
    enum PremiumFeature: String, CaseIterable {
        case premiumChat = "premium_chat"
        case advancedSkinAnalysis = "advanced_skin_analysis"
        case personalizedRoutines = "personalized_routines"
        case prioritySupport = "priority_support"
        case unlimitedAnalysis = "unlimited_analysis"
        case advancedTracking = "advanced_tracking"
        
        var displayName: String {
            switch self {
            case .premiumChat:
                return "Premium Chat"
            case .advancedSkinAnalysis:
                return "Advanced Skin Analysis"
            case .personalizedRoutines:
                return "Personalized Routines"
            case .prioritySupport:
                return "Priority Support"
            case .unlimitedAnalysis:
                return "Unlimited Analysis"
            case .advancedTracking:
                return "Advanced Tracking"
            }
        }
        
        var icon: String {
            switch self {
            case .premiumChat:
                return "message.circle.fill"
            case .advancedSkinAnalysis:
                return "camera.circle.fill"
            case .personalizedRoutines:
                return "list.bullet.circle.fill"
            case .prioritySupport:
                return "person.crop.circle.fill"
            case .unlimitedAnalysis:
                return "infinity.circle.fill"
            case .advancedTracking:
                return "chart.line.uptrend.xyaxis.circle.fill"
            }
        }
    }
}

// MARK: - Premium Feature Gate View Modifier

struct PremiumFeatureGate: ViewModifier {
    let userTierManager: UserTierManager
    let feature: UserTierManager.PremiumFeature
    let showUpgradePrompt: Bool
    let action: () -> Void
    
    func body(content: Content) -> some View {
        Group {
            if userTierManager.isPremium {
                content
            } else {
                VStack(spacing: 16) {
                    content
                        .blur(radius: 3)
                        .disabled(true)
                    
                    if showUpgradePrompt {
                        VStack(spacing: 8) {
                            Image(systemName: feature.icon)
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            Text(feature.displayName)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text(userTierManager.getUpgradePrompt(for: feature))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: action) {
                                Text("Upgrade to Premium")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
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
            }
        }
    }
}

extension View {
    func premiumFeatureGate(
        userTierManager: UserTierManager,
        feature: UserTierManager.PremiumFeature,
        showUpgradePrompt: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        self.modifier(PremiumFeatureGate(
            userTierManager: userTierManager,
            feature: feature,
            showUpgradePrompt: showUpgradePrompt,
            action: action
        ))
    }
} 