import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var productResults: [ProductSearchResult]? = nil
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

// MARK: - ChatGPT API Models

struct ChatGPTVisionRequest: Codable {
    let model: String
    let messages: [ChatGPTMessage]
    let maxTokens: Int
    let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct ChatGPTMessage: Codable {
    let role: String
    let content: [ChatGPTContent]
}

struct ChatGPTContent: Codable {
    let type: String
    let text: String?
    let imageURL: ChatGPTImageURL?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case imageURL = "image_url"
    }
}

struct ChatGPTImageURL: Codable {
    let url: String
}

struct ChatGPTVisionResponse: Codable {
    let id: String
    let choices: [ChatGPTChoice]
    let usage: ChatGPTUsage
}

struct ChatGPTChoice: Codable {
    let message: ChatGPTResponseMessage
    let finishReason: String
    
    enum CodingKeys: String, CodingKey {
        case message
        case finishReason = "finish_reason"
    }
}

struct ChatGPTResponseMessage: Codable {
    let content: String
}

struct ChatGPTUsage: Codable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// MARK: - Product Models
struct ProductSearchResult: Identifiable, Codable {
    let id: UUID
    let name: String
    let brand: String?
    let priceText: String?
    let benefits: [String]
    let imageURL: String?
    let destinationURL: String?
    // Optional ingredients list when available (e.g., from SkincareAPI)
    let ingredients: [String]?
    // Optional product type classification (e.g., cleanser, serum, moisturizer, sunscreen)
    let productType: String?
    // Optional product description for enhanced user experience
    let description: String?

    init(id: UUID = UUID(), name: String, brand: String?, priceText: String?, benefits: [String], imageURL: String?, destinationURL: String?, ingredients: [String]? = nil, productType: String? = nil, description: String? = nil) {
        self.id = id
        self.name = name
        self.brand = brand
        self.priceText = priceText
        self.benefits = benefits
        self.imageURL = imageURL
        self.destinationURL = destinationURL
        self.ingredients = ingredients
        self.productType = productType
        self.description = description
    }
}

// Equatable by id so RoutineOverride can derive Equatable
extension ProductSearchResult: Equatable {
    static func == (lhs: ProductSearchResult, rhs: ProductSearchResult) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Chat Memory Models
struct ChatMemory: Codable {
    var morningRoutine: [String]
    var eveningRoutine: [String]
    var weeklyTreatments: [String]
    var analysisNotes: [String]
    var lastUpdated: Date
    var lastAnalysisDate: Date?
}

struct ChatMemoryUpdate: Codable {
    var morningRoutine: [String]?
    var eveningRoutine: [String]?
    var weeklyTreatments: [String]?
    var analysisNotes: [String]?
}

struct SkinAnalysisResult: Codable {
    let conditions: [SkinCondition]
    let confidence: Double
    let analysisDate: Date
    let recommendations: [String]
    let skinHealthScore: Int // ChatGPT-generated score (0-100)
    let analysisVersion: String // Version tracking for routine generation
    let routineGenerationTimestamp: Date? // When routine was generated
    let analysisProvider: AnalysisProvider // Which AI service was used
    let imageCount: Int // Number of images analyzed
    let skinAgeYears: Int? // Estimated facial skin age from the photos
    
    enum AnalysisProvider: String, Codable {
        case chatGPT35 = "gpt-3.5-turbo"
        case chatGPT4 = "gpt-4-vision-preview"
        case replicate = "replicate"
        case mock = "mock"
    }
}

struct SkinCondition: Codable, Identifiable {
    let id: UUID
    let name: String
    let severity: Severity
    let confidence: Double
    let description: String
    let affectedAreas: [String]
    
    private enum CodingKeys: String, CodingKey {
        case id, name, severity, confidence, description, affectedAreas
    }
    
    init(id: UUID = UUID(), name: String, severity: Severity, confidence: Double, description: String, affectedAreas: [String]) {
        self.id = id
        self.name = name
        self.severity = severity
        self.confidence = confidence
        self.description = description
        self.affectedAreas = affectedAreas
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try c.decode(String.self, forKey: .name)
        self.severity = try c.decode(Severity.self, forKey: .severity)
        self.confidence = try c.decode(Double.self, forKey: .confidence)
        self.description = try c.decode(String.self, forKey: .description)
        self.affectedAreas = try c.decode([String].self, forKey: .affectedAreas)
    }
    
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
    let stepTime: StepTime
    let conflictsWith: [String]
    let requiresSPF: Bool
    let tips: [String]
    
    private enum CodingKeys: String, CodingKey { case id, name, description, category, duration, frequency, stepTime, conflictsWith, requiresSPF, tips }
    
    init(id: UUID = UUID(), name: String, description: String, category: StepCategory, duration: Int, frequency: Frequency, stepTime: StepTime = .anytime, conflictsWith: [String] = [], requiresSPF: Bool = false, tips: [String]) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.duration = duration
        self.frequency = frequency
        self.stepTime = stepTime
        self.conflictsWith = conflictsWith
        self.requiresSPF = requiresSPF
        self.tips = tips
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        // ID: accept UUID, string, or generate fallback
        if let uuid = try? c.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else if let idString = try? c.decode(String.self, forKey: .id) {
            // Handle string IDs like "step-1", "step-2", etc.
            if let parsed = UUID(uuidString: idString) {
                self.id = parsed
            } else if idString.hasPrefix("step-") || idString.hasPrefix("prod-") {
                // Create a deterministic UUID from string ID
                let hash = idString.hash
                let uuidString = String(format: "%08x-0000-0000-0000-%012x", abs(hash), abs(hash))
                self.id = UUID(uuidString: uuidString) ?? UUID()
                print("✅ SkincareStep: String ID '\(idString)' converted to deterministic UUID")
            } else {
                // Fallback for other string IDs
                let hash = idString.hash
                let uuidString = String(format: "%08x-0000-0000-0000-%012x", abs(hash), abs(hash))
                self.id = UUID(uuidString: uuidString) ?? UUID()
                print("⚠️ SkincareStep: String ID '\(idString)' converted to fallback UUID")
            }
        } else if let intId = try? c.decode(Int.self, forKey: .id) {
            // Create a deterministic UUID namespace using the integer
            self.id = UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", intId))") ?? UUID()
            print("⚠️ SkincareStep: Non-UUID id=\(intId) received, generated fallback UUID")
        } else {
            self.id = UUID()
            print("⚠️ SkincareStep: Missing/invalid id, generated UUID")
        }
        self.name = try c.decode(String.self, forKey: .name)
        self.description = try c.decode(String.self, forKey: .description)
        // Category tolerant parsing
        if let cat = try? c.decode(StepCategory.self, forKey: .category) {
            self.category = cat
        } else if let catRaw = try? c.decode(String.self, forKey: .category) {
            self.category = StepCategory(rawValue: catRaw.lowercased()) ?? .treatment
            print("⚠️ SkincareStep: Unknown category='\(catRaw)'; defaulting to .treatment")
        } else {
            self.category = .treatment
        }
        if let d = try? c.decode(Int.self, forKey: .duration) {
            self.duration = d
        } else if let dStr = try? c.decode(String.self, forKey: .duration), let d = Int(dStr) {
            self.duration = d
        } else {
            self.duration = 60
        }
        // Frequency tolerant
        if let f = try? c.decode(Frequency.self, forKey: .frequency) {
            self.frequency = f
        } else if let fRaw = try? c.decode(String.self, forKey: .frequency) {
            self.frequency = Frequency(rawValue: fRaw.lowercased()) ?? .daily
            if Frequency(rawValue: fRaw.lowercased()) == nil { print("⚠️ SkincareStep: Unknown frequency='\(fRaw)'; defaulting to .daily") }
        } else {
            self.frequency = .daily
        }
        // StepTime tolerant
        if let st = try? c.decode(StepTime.self, forKey: .stepTime) {
            self.stepTime = st
        } else if let stRaw = try? c.decode(String.self, forKey: .stepTime) {
            self.stepTime = StepTime(rawValue: stRaw.lowercased()) ?? .anytime
        } else {
            self.stepTime = .anytime
        }
        self.conflictsWith = try c.decodeIfPresent([String].self, forKey: .conflictsWith) ?? []
        if let rs = try? c.decode(Bool.self, forKey: .requiresSPF) {
            self.requiresSPF = rs
        } else if let rsStr = try? c.decode(String.self, forKey: .requiresSPF) {
            self.requiresSPF = (rsStr as NSString).boolValue
        } else {
            self.requiresSPF = name.lowercased().contains("spf") || name.lowercased().contains("sunscreen") || category == .sunscreen
        }
        self.tips = try c.decodeIfPresent([String].self, forKey: .tips) ?? []
    }
    
    enum StepCategory: String, Codable, CaseIterable {
        case cleanser = "cleanser"
        case toner = "toner"
        case serum = "serum"
        case moisturizer = "moisturizer"
        case sunscreen = "sunscreen"
        case treatment = "treatment"
        case mask = "mask"
        case exfoliant = "exfoliant"
        case bha = "bha"
        case aha = "aha"
        case clay = "clay"
    }
    
    enum Frequency: String, Codable, CaseIterable {
        case daily = "daily"
        case twiceDaily = "twice_daily"
        case nightly = "nightly"
        case twoToThreePerWeek = "two_to_three_per_week"
        case weekly = "weekly"
        case asNeeded = "as_needed"
    }
    
    enum StepTime: String, Codable, CaseIterable {
        case morning = "morning"
        case evening = "evening"
        case anytime = "anytime"
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
    
    private enum CodingKeys: String, CodingKey { case id, name, brand, category, price, rating, description, ingredients, benefits, imageURL, purchaseURL }
    
    init(id: UUID = UUID(), name: String, brand: String, category: String, price: Double, rating: Double, description: String, ingredients: [String], benefits: [String], imageURL: String?, purchaseURL: String?) {
        self.id = id
        self.name = name
        self.brand = brand
        self.category = category
        self.price = price
        self.rating = rating
        self.description = description
        self.ingredients = ingredients
        self.benefits = benefits
        self.imageURL = imageURL
        self.purchaseURL = purchaseURL
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try c.decode(String.self, forKey: .name)
        self.brand = try c.decodeIfPresent(String.self, forKey: .brand) ?? ""
        self.category = try c.decodeIfPresent(String.self, forKey: .category) ?? ""
        self.price = try c.decodeIfPresent(Double.self, forKey: .price) ?? 0
        self.rating = try c.decodeIfPresent(Double.self, forKey: .rating) ?? 0
        self.description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.ingredients = try c.decodeIfPresent([String].self, forKey: .ingredients) ?? []
        self.benefits = try c.decodeIfPresent([String].self, forKey: .benefits) ?? []
        self.imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
        self.purchaseURL = try c.decodeIfPresent(String.self, forKey: .purchaseURL)
    }
}

struct ProgressMetrics: Codable {
    let skinHealthScore: Double
    let improvementAreas: [String]
    let nextCheckIn: Date
    let goals: [String]

    private enum CodingKeys: String, CodingKey { case skinHealthScore, improvementAreas, nextCheckIn, goals }

    init(skinHealthScore: Double, improvementAreas: [String], nextCheckIn: Date, goals: [String]) {
        self.skinHealthScore = skinHealthScore
        self.improvementAreas = improvementAreas
        self.nextCheckIn = nextCheckIn
        self.goals = goals
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.skinHealthScore = try c.decodeIfPresent(Double.self, forKey: .skinHealthScore) ?? 0.0
        self.improvementAreas = try c.decodeIfPresent([String].self, forKey: .improvementAreas) ?? []
        // Tolerant date parsing: ISO8601 string or numeric seconds
        if let isoString = try? c.decode(String.self, forKey: .nextCheckIn) {
            let f = ISO8601DateFormatter()
            if let d = f.date(from: isoString) {
                self.nextCheckIn = d
            } else if let seconds = Double(isoString) {
                self.nextCheckIn = Date(timeIntervalSince1970: seconds)
            } else {
                print("⚠️ ProgressMetrics: Unrecognized nextCheckIn string='\(isoString)'; defaulting to +7d")
                self.nextCheckIn = Date().addingTimeInterval(7*24*3600)
            }
        } else if let seconds = try? c.decode(Double.self, forKey: .nextCheckIn) {
            self.nextCheckIn = Date(timeIntervalSince1970: seconds)
        } else {
            self.nextCheckIn = Date().addingTimeInterval(7*24*3600)
            print("⚠️ ProgressMetrics: Missing nextCheckIn; defaulting to +7d")
        }
        self.goals = try c.decodeIfPresent([String].self, forKey: .goals) ?? []
    }
}

// MARK: - Routine History Tracking

struct RoutineHistory: Codable, Identifiable {
    let id: UUID
    let userId: String
    let routineVersion: String
    let generatedAt: Date
    let analysisResultId: String
    let skinHealthScore: Int
    let routine: [SkincareStep]
    let reloadCount: Int
    let maxReloads: Int
    let nextReloadTime: Date?
    let isActive: Bool
}

struct ReloadTracking: Codable {
    let userId: String
    let routineId: String
    let reloadCount: Int
    let maxReloads: Int
    let lastReloadTime: Date
    let nextReloadTime: Date?
    let tier: UserTierManager.Tier
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
    let reason: String?
    
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
