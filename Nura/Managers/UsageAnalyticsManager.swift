import Foundation
import Supabase

@MainActor
class UsageAnalyticsManager: ObservableObject {
    static let shared = UsageAnalyticsManager()
    
    @Published var currentUsage: UsageStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseClient: SupabaseClient
    
    private init() {
        self.supabaseClient = AuthenticationManager.shared.client
    }
    
    // MARK: - Usage Statistics
    
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
    
    // MARK: - Public Methods
    
    func refreshUsageStats() async {
        guard let session = AuthenticationManager.shared.session else {
            errorMessage = "Not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let stats = try await fetchUsageStats(userId: session.user.id.uuidString)
            currentUsage = stats
        } catch {
            errorMessage = error.localizedDescription
            print("❌ UsageAnalyticsManager: Failed to fetch usage stats: \(error)")
        }
    }
    
    func getUsageHistory(days: Int = 7) async -> [DailyUsage] {
        guard let session = AuthenticationManager.shared.session else {
            return []
        }
        
        do {
            return try await fetchUsageHistory(userId: session.user.id.uuidString, days: days)
        } catch {
            print("❌ UsageAnalyticsManager: Failed to fetch usage history: \(error)")
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private struct ProfileTierRow: Decodable { let premium_tier: String? }
    private struct UsageRow: Decodable {
        let tokens_used: Int?
        let cost_usd: Double?
        let timestamp: String?
    }

    private func fetchUsageStats(userId: String) async throws -> UsageStats {
        // Get user's tier first
        let profile: ProfileTierRow = try await supabaseClient
            .from("profiles")
            .select("premium_tier")
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        let tier = profile.premium_tier ?? "free"
        let maxRequestsPerMinute = getMaxRequestsForTier(tier)
        
        // Get today's usage
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        
        let todayUsage: [UsageRow] = try await supabaseClient
            .from("api_usage")
            .select("tokens_used, cost_usd")
            .eq("user_id", value: userId)
            .gte("timestamp", value: startOfDay.iso8601)
            .execute()
            .value
        
        let totalTokensToday = todayUsage.reduce(0) { $0 + (rowValue($1.tokens_used)) }
        let totalCostToday = todayUsage.reduce(0.0) { $0 + (($1.cost_usd) ?? 0.0) }
        
        // Count requests in the last minute
        let oneMinuteAgo = Date().addingTimeInterval(-60)
        let requestsResponse: PostgrestResponse<[UsageRow]> = try await supabaseClient
            .from("api_usage")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId)
            .gte("timestamp", value: oneMinuteAgo.iso8601)
            .execute()
        
        let requestsThisMinuteCount = requestsResponse.count ?? 0
        let remainingRequestsThisMinute = max(0, maxRequestsPerMinute - requestsThisMinuteCount)
        
        return UsageStats(
            totalRequestsToday: todayUsage.count,
            totalTokensToday: totalTokensToday,
            totalCostToday: totalCostToday,
            requestsThisMinute: requestsThisMinuteCount,
            tier: tier,
            maxRequestsPerMinute: maxRequestsPerMinute,
            remainingRequestsThisMinute: remainingRequestsThisMinute
        )
    }
    
    private func fetchUsageHistory(userId: String, days: Int) async throws -> [DailyUsage] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let usageData: [UsageRow] = try await supabaseClient
            .from("api_usage")
            .select("tokens_used, cost_usd, timestamp")
            .eq("user_id", value: userId)
            .gte("timestamp", value: startDate.iso8601)
            .order("timestamp", ascending: false)
            .execute()
            .value
        
        // Group by day
        var dailyUsage: [String: DailyUsage] = [:]
        
        for usage in usageData {
            let dateForRow = parseTimestampToDate(usage.timestamp) ?? Date()
            let dateString = formatDate(dateForRow)
            
            if dailyUsage[dateString] == nil {
                dailyUsage[dateString] = DailyUsage(
                    date: dateString,
                    requests: 0,
                    tokens: 0,
                    cost: 0.0
                )
            }
            
            dailyUsage[dateString]?.requests += 1
            dailyUsage[dateString]?.tokens += usage.tokens_used ?? 0
            dailyUsage[dateString]?.cost += usage.cost_usd ?? 0.0
        }
        
        return Array(dailyUsage.values).sorted { $0.date > $1.date }
    }
    
    private func getMaxRequestsForTier(_ tier: String) -> Int {
        switch tier {
        case "pro_unlimited":
            return 100
        case "pro":
            return 60
        case "free":
            return 20
        default:
            return 20
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Parsing helpers
    /// Parses a decimal value that may arrive as String, Double, Int, or NSDecimalNumber
    private func parseDecimalValue(_ any: Any?) -> Double {
        if let number = any as? Double { return number }
        if let number = any as? Int { return Double(number) }
        if let number = any as? NSNumber { return number.doubleValue }
        if let decimal = any as? NSDecimalNumber { return decimal.doubleValue }
        if let string = any as? String { return Double(string) ?? 0.0 }
        return 0.0
    }

    /// Accepts ISO8601 string, or epoch seconds/milliseconds as Int/Double/NSNumber
    private func parseTimestampToDate(_ any: Any?) -> Date? {
        if let iso = any as? String {
            let f = ISO8601DateFormatter()
            if let d = f.date(from: iso) { return d }
            // Try trimming fractional seconds if present
            if let dotRange = iso.range(of: ".") {
                let trimmed = String(iso[..<dotRange.lowerBound]) + "Z"
                if let d2 = f.date(from: trimmed) { return d2 }
            }
        }
        if let secs = any as? Double {
            // Heuristic: treat > 10^12 as milliseconds
            return Date(timeIntervalSince1970: secs > 1_000_000_000_000 ? secs / 1000.0 : secs)
        }
        if let secsInt = any as? Int {
            let value = Double(secsInt)
            return Date(timeIntervalSince1970: value > 1_000_000_000_000 ? value / 1000.0 : value)
        }
        if let num = any as? NSNumber {
            return Date(timeIntervalSince1970: num.doubleValue > 1_000_000_000_000 ? num.doubleValue / 1000.0 : num.doubleValue)
        }
        return nil
    }

    private func rowValue(_ value: Int?) -> Int { value ?? 0 }
}

// MARK: - Data Models

struct DailyUsage: Identifiable {
    let id = UUID()
    let date: String
    var requests: Int
    var tokens: Int
    var cost: Double
    
    var costFormatted: String {
        return String(format: "$%.4f", cost)
    }
    
    var tokensFormatted: String {
        if tokens >= 1000 {
            return String(format: "%.1fk", Double(tokens) / 1000.0)
        }
        return "\(tokens)"
    }
}

// MARK: - Extensions

extension Date {
    var iso8601: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
