import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct ChatRequest: Codable {
    let message: String
    let conversationHistory: [String]
    let userContext: UserContext
}

struct ChatResponse: Codable {
    let message: String
    let confidence: Double
}

struct UserContext: Codable {
    let skinType: String
    let recentConditions: [String]
    let preferences: [String]
    let lastAnalysis: Date
}

struct SkinAnalysisRequest: Codable {
    let imageURLs: [String]
    let userProfile: LocalUserProfile
}

struct SkinAnalysisResult: Codable {
    let conditions: [SkinCondition]
    let confidence: Double
    let analysisDate: Date
    let recommendations: [String]
}

struct SkinCondition: Codable, Identifiable {
    let id: UUID
    let name: String
    let severity: Severity
    let confidence: Double
    let description: String
    let affectedAreas: [String]
    
    enum Severity: String, Codable, CaseIterable {
        case mild = "mild"
        case moderate = "moderate"
        case severe = "severe"
        
        var color: String {
            switch self {
            case .mild: return "green"
            case .moderate: return "orange"
            case .severe: return "red"
            }
        }
    }
}

struct WeatherData: Codable {
    let temperature: Double
    let humidity: Double
    let uvIndex: Double
    let condition: String
}

struct RecommendationRequest: Codable {
    let skinConditions: [SkinCondition]
    let userProfile: LocalUserProfile
    let weatherData: WeatherData?
}

struct SkincareRecommendations: Codable {
    let morningRoutine: [SkincareStep]
    let eveningRoutine: [SkincareStep]
    let weeklyTreatments: [SkincareStep]
    let lifestyleTips: [String]
    let productRecommendations: [ProductRecommendation]
    let progressTracking: ProgressMetrics
}

struct SkincareStep: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let category: StepCategory
    let duration: Int
    let frequency: Frequency
    let tips: [String]
    
    enum StepCategory: String, Codable, CaseIterable {
        case cleanser = "cleanser"
        case toner = "toner"
        case serum = "serum"
        case moisturizer = "moisturizer"
        case sunscreen = "sunscreen"
        case treatment = "treatment"
        case mask = "mask"
    }
    
    enum Frequency: String, Codable, CaseIterable {
        case daily = "daily"
        case twiceDaily = "twice_daily"
        case weekly = "weekly"
        case asNeeded = "as_needed"
    }
}

struct ProductRecommendation: Codable, Identifiable {
    let id: UUID
    let name: String
    let brand: String
    let category: String
    let price: Double
    let rating: Double
    let description: String
    let ingredients: [String]
    let benefits: [String]
    let imageURL: String?
    let purchaseURL: String?
}

struct ProgressMetrics: Codable {
    let skinHealthScore: Double
    let improvementAreas: [String]
    let nextCheckIn: Date
    let goals: [String]
}

struct DashboardData: Codable {
    let currentRoutine: [SkincareStep]
    let progress: ProgressMetrics
    let recentAnalysis: SkinAnalysisResult?
    let upcomingTasks: [DashboardTask]
    let insights: [Insight]
}

struct DashboardTask: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let dueDate: Date
    let priority: Priority
    let isCompleted: Bool
    
    enum Priority: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
    }
}

struct Insight: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let type: InsightType
    let date: Date
    
    enum InsightType: String, Codable, CaseIterable {
        case improvement = "improvement"
        case warning = "warning"
        case tip = "tip"
        case achievement = "achievement"
    }
}

struct Subscription: Codable {
    let id: String
    let type: SubscriptionType
    let price: Double
    let features: [String]
    let isActive: Bool
    let startDate: Date
    let endDate: Date?
    
    enum SubscriptionType: String, Codable, CaseIterable {
        case basic = "basic"
        case premium = "premium"
        case pro = "pro"
    }
}

struct PaymentMethod: Codable {
    let id: String
    let type: String
    let last4: String
    let brand: String
    let isDefault: Bool
}

// MARK: - Notification Models

struct NotificationPreferences: Codable {
    let id: String
    let userId: String
    let pushEnabled: Bool
    let emailEnabled: Bool
    let smsEnabled: Bool
    let dailyPhotoReminder: NotificationTypePreference
    let dashboardScoreShare: NotificationTypePreference
    let routineFollowUp: NotificationTypePreference
    let emailAddress: String?
    let phoneNumber: String?
    let preferredTime: Date
    let timezone: String
    let createdAt: Date
    let updatedAt: Date
}

struct NotificationTypePreference: Codable {
    let enabled: Bool
    let frequency: NotificationFrequency
    let channels: [NotificationChannel]
    let customMessage: String?
    
    enum NotificationFrequency: String, Codable, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case never = "never"
    }
    
    enum NotificationChannel: String, Codable, CaseIterable {
        case push = "push"
        case email = "email"
        case sms = "sms"
    }
}

struct NotificationTemplate: Codable, Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let body: String
    let icon: String
    let actionURL: String?
    let category: NotificationCategory
    
    enum NotificationType: String, Codable, CaseIterable {
        case dailyPhotoReminder = "daily_photo_reminder"
        case dashboardScoreShare = "dashboard_score_share"
        case routineFollowUp = "routine_follow_up"
        case skinAnalysisComplete = "skin_analysis_complete"
        case routineReminder = "routine_reminder"
        case progressMilestone = "progress_milestone"
    }
    
    enum NotificationCategory: String, Codable, CaseIterable {
        case reminder = "reminder"
        case achievement = "achievement"
        case routine = "routine"
        case analysis = "analysis"
    }
}

struct ScheduledNotification: Codable, Identifiable {
    let id: String
    let userId: String
    let templateId: String
    let scheduledDate: Date
    let status: NotificationStatus
    let sentAt: Date?
    let deliveredAt: Date?
    let openedAt: Date?
    let channels: [NotificationTypePreference.NotificationChannel]
    
    enum NotificationStatus: String, Codable, CaseIterable {
        case scheduled = "scheduled"
        case sent = "sent"
        case delivered = "delivered"
        case opened = "opened"
        case failed = "failed"
        case cancelled = "cancelled"
    }
}

struct NotificationAnalytics: Codable {
    let notificationId: String
    let userId: String
    let sentAt: Date
    let deliveredAt: Date?
    let openedAt: Date?
    let actionTaken: String?
    let timeToOpen: TimeInterval?
    let channel: NotificationTypePreference.NotificationChannel
}
