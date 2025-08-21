import Foundation
import SwiftUI

@MainActor
final class StreakManager: ObservableObject {
    static let shared = StreakManager()

    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published private(set) var lastCheckInDate: Date? = nil
    @Published private(set) var pendingReward: StreakReward? = nil

    private let userDefaults = UserDefaults.standard

    // Milestones in days that unlock rewards or celebrations
    let milestones: [Int] = [7, 14, 30, 90, 365]

    private init() {
        load()
        NotificationCenter.default.addObserver(
            forName: .nuraAnalysisCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.recordCheckIn(source: .analysis)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Public API

    enum CheckInSource: String {
        case analysis
        case diary
        case routine
        case manual
    }

    enum StreakReward: Equatable {
        case celebration(days: Int)
        case freeProMonth
    }

    func recordCheckIn(source: CheckInSource) {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastCheckInDate.map({ Calendar.current.startOfDay(for: $0) }) {
            // If already checked in today, ignore
            if Calendar.current.isDate(last, inSameDayAs: today) {
                save()
                return
            }
            let daysBetween = Calendar.current.dateComponents([.day], from: last, to: today).day ?? 0
            if daysBetween == 1 {
                currentStreak += 1
            } else if daysBetween > 1 {
                currentStreak = 1
            } else {
                currentStreak = max(currentStreak, 1)
            }
        } else {
            currentStreak = 1
        }

        lastCheckInDate = Date()
        if currentStreak > longestStreak { longestStreak = currentStreak }

        // Determine rewards
        if currentStreak == 30 && !isMilestoneRedeemed(30) {
            pendingReward = .freeProMonth
        } else if let milestone = milestones.filter({ $0 != 30 }).first(where: { $0 == currentStreak }) {
            pendingReward = .celebration(days: milestone)
        } else {
            pendingReward = nil
        }

        save()
    }

    func nextMilestone() -> Int? {
        guard let next = milestones.first(where: { $0 > currentStreak }) else { return nil }
        return next
    }

    func daysToNextMilestone() -> Int? {
        guard let next = nextMilestone() else { return nil }
        return max(next - currentStreak, 0)
    }

    func markCelebrationAcknowledged() {
        if case .celebration = pendingReward { pendingReward = nil }
    }

    func redeemFreeProMonth(using userTierManager: UserTierManager) {
        guard pendingReward == .freeProMonth else { return }
        markMilestoneRedeemed(30)
        pendingReward = nil
        userTierManager.applyPromoPro(forDays: 30)
    }

    // MARK: - Persistence

    private var prefix: String {
        // Use a stable, anonymous user key if auth is not available; rely on device
        let userId = AuthenticationManager.shared.userProfile?.id ?? "anonymous"
        return "streak_\(userId)_"
    }

    private var currentKey: String { prefix + "current" }
    private var longestKey: String { prefix + "longest" }
    private var lastDateKey: String { prefix + "last_date" }
    private var redeemedKey: String { prefix + "redeemed_milestones" }

    private func load() {
        currentStreak = max(0, userDefaults.integer(forKey: currentKey))
        longestStreak = max(0, userDefaults.integer(forKey: longestKey))
        lastCheckInDate = userDefaults.object(forKey: lastDateKey) as? Date
    }

    private func save() {
        userDefaults.set(currentStreak, forKey: currentKey)
        userDefaults.set(longestStreak, forKey: longestKey)
        if let lastCheckInDate = lastCheckInDate {
            userDefaults.set(lastCheckInDate, forKey: lastDateKey)
        }
    }

    private func isMilestoneRedeemed(_ days: Int) -> Bool {
        let redeemed = userDefaults.array(forKey: redeemedKey) as? [Int] ?? []
        return redeemed.contains(days)
    }

    private func markMilestoneRedeemed(_ days: Int) {
        var redeemed = userDefaults.array(forKey: redeemedKey) as? [Int] ?? []
        if !redeemed.contains(days) { redeemed.append(days) }
        userDefaults.set(redeemed, forKey: redeemedKey)
    }
}

// Intentionally no local notifications defined here; streaks are driven by .nuraAnalysisCompleted


