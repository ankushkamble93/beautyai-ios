import Foundation

struct InsightEngine {
    static func generate(
        profile: OnboardingAnswers?,
        analysis: SkinAnalysisResult?,
        recommendations: SkincareRecommendations?,
        tasks: [DashboardTask] = [],
        weeklyTask: DashboardTask? = nil,
        lastUpdated: Date? = nil
    ) -> [Insight] {
        var insights: [Insight] = []
        let now = Date()

        // 1) Progress/Achievement insight based on skin health score delta (persist last score locally)
        if let score = analysis?.skinHealthScore {
            let defaults = UserDefaults.standard
            let lastKey = "nura.lastSkinScore"
            let last = defaults.integer(forKey: lastKey)
            defaults.set(score, forKey: lastKey)
            if last > 0 {
                let delta = score - last
                if delta != 0 {
                    let sign = delta >= 0 ? "+" : ""
                    insights.append(Insight(
                        id: UUID(),
                        title: delta >= 0 ? "Great Progress!" : "Heads-up",
                        description: "Your skin health score changed by \(sign)\(delta)% since your last check.",
                        type: delta >= 0 ? .improvement : .warning,
                        date: now,
                        reason: "Based on change in skin score from your latest analysis."
                    ))
                }
            } else if lastUpdated != nil {
                insights.append(Insight(
                    id: UUID(),
                    title: "Routine Ready",
                    description: "Your personalized routine is ready to follow.",
                    type: .achievement,
                    date: now,
                    reason: "A new routine was generated recently."
                ))
            }
        } else if lastUpdated != nil {
            insights.append(Insight(
                id: UUID(),
                title: "Routine Ready",
                description: "Your personalized routine is ready to follow.",
                type: .achievement,
                date: now,
                reason: "A new routine was generated recently."
            ))
        }

        // 2) Contextual/risk insight based on routine contents vs profile/conditions/tasks
        if let recs = recommendations {
            let eveningNames = recs.eveningRoutine.map { $0.name.lowercased() }
            let weeklyNames = recs.weeklyTreatments.map { $0.name.lowercased() }
            let hasRetinoid = (eveningNames + weeklyNames).contains { $0.contains("retinol") || $0.contains("retinoid") || $0.contains("tretinoin") }

            if hasRetinoid {
                var caution = "Add moisturizer sandwiching and start 2-3x/week."
                if let goal = profile?.skincareGoal.lowercased(), goal.contains("hydration") { caution = "Go slow with retinoids and buffer with a rich moisturizer." }

                insights.append(Insight(
                    id: UUID(),
                    title: "Retinoid Tolerance",
                    description: caution,
                    type: .warning,
                    date: now,
                    reason: "Evening or weekly routine includes a retinoid."
                ))
            }
            let morningNames = recs.morningRoutine.map { $0.name.lowercased() }
            let hasVitaminC = morningNames.contains { $0.contains("vitamin c") || $0.contains("ascorbic") }
            if hasVitaminC {
                insights.append(Insight(
                    id: UUID(),
                    title: "SPF Priority",
                    description: "Vitamin C pairs best with daily SPF. Reapply if outdoors.",
                    type: .tip,
                    date: now,
                    reason: "Morning routine includes vitamin C."
                ))
            }
        }

        // Weekly task timing insight (due soon)
        if let weekly = weeklyTask {
            let timeRemaining = weekly.dueDate.timeIntervalSince(now)
            if timeRemaining > 0 {
                let days = Int(ceil(timeRemaining / 86400))
                insights.append(Insight(
                    id: UUID(),
                    title: "Weekly Treatment Due",
                    description: "Your weekly step is due in \(days) day\(days == 1 ? "" : "s").",
                    type: .tip,
                    date: now,
                    reason: "Based on your weekly routine task."
                ))
            }
        }

        // 3) Goal alignment tip (always try to include one)
        if let goal = profile?.skincareGoal.trimmingCharacters(in: .whitespacesAndNewlines), !goal.isEmpty {
            let tip: String
            switch goal.lowercased() {
            case let g where g.contains("even") || g.contains("tone"):
                tip = "Consider azelaic acid 10% at night on non-retinoid days to support even tone."
            case let g where g.contains("acne"):
                tip = "Gentle cleanse + BP/niacinamide in AM; retinoid nights for long-term clarity."
            case let g where g.contains("hydration"):
                tip = "Layer hyaluronic serum on damp skin, then seal with a ceramide-rich moisturizer."
            default:
                tip = "Keep a simple, consistent routine to support your goal."
            }
            insights.append(Insight(
                id: UUID(),
                title: "Goal-aligned Tip",
                description: tip,
                type: .tip,
                date: now,
                reason: "Your stated goal: \(goal)."
            ))
        }

        // If we still have fewer than 3, add a motivational fallback
        if insights.count < 3 {
            insights.append(Insight(
                id: UUID(),
                title: "Stay Consistent",
                description: "Small daily habits create big changes. You've got this.",
                type: .achievement,
                date: now,
                reason: "General motivation when limited data is available."
            ))
        }

        // Always return up to 3 prioritized items: improvement/warning first, then tip, then achievement
        let prioritized = insights.sorted { lhs, rhs in
            func rank(_ t: Insight.InsightType) -> Int {
                switch t {
                case .improvement: return 0
                case .warning: return 1
                case .achievement: return 2
                case .tip: return 3
                }
            }
            return rank(lhs.type) < rank(rhs.type)
        }
        return Array(prioritized.prefix(3))
    }
}
