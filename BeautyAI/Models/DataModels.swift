import Foundation

// MARK: - Chat Models
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}

struct UserProfile: Codable {
    let age: Int
    let gender: String
    let skinType: String
    let race: String
    let location: String
}

struct SkinCondition: Codable, Identifiable {
    let id = UUID()
    let name: String
    let severity: String
    let confidence: Double
    let description: String
}

struct SkincareRecommendations: Codable {
    let morningRoutine: [String]
    let eveningRoutine: [String]
    let lifestyleTips: [String]
}
