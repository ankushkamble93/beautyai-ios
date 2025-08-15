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
} 