import Foundation

// MARK: - Shared Types
// This file contains shared enums and types used across multiple views
// It should be compiled first to ensure proper type resolution

// MARK: - Billing Cycle
public enum BillingCycle: String, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }
    
    var savingsMessage: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Save up to 35%"
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let nuraAnalysisCompleted = Notification.Name("nura.analysis.completed")
    static let nuraRecommendationsUpdated = Notification.Name("nura.recommendations.updated")
    static let nuraSwitchTab = Notification.Name("nura.switch.tab")
}

// MARK: - API Usage Models
struct UsageStats {
    let totalRequestsToday: Int
    let totalTokensToday: Int
    let totalCostToday: Double
    let requestsThisMinute: Int
    let tier: String
    let maxRequestsPerMinute: Int
    let remainingRequestsThisMinute: Int
    
    var costFormatted: String {
        return String(format: "$%.4f", totalCostToday)
    }
    
    var isNearLimit: Bool {
        return remainingRequestsThisMinute <= 2
    }
    
    var isAtLimit: Bool {
        return remainingRequestsThisMinute <= 0
    }
}

// DailyUsage lives in UsageAnalyticsManager to avoid duplication/ambiguity