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

        // Always include a motivation and a helping quote, plus one additional contextual item
        let motivationPool: [String] = [
            "Small daily habits create big changes. You've got this.",
            "Progress over perfection. Show up for your skin today.",
            "Consistency is the most powerful active in your routine."
        ]
        let helpingPool: [String] = [
            "Apply moisturizer on damp skin to lock in hydration.",
            "Use a pea-sized amount of retinoid; buffer with moisturizer if sensitive.",
            "Reapply sunscreen every 2 hours when outdoors.",
            "Patch test new actives on the jawline for 2-3 nights before full-face.",
            "The two-finger rule helps you apply enough SPF for face and neck.",
            "Avoid stacking strong exfoliants in the same routine as retinoids.",
            "Cleanse for ~60 seconds to gently lift oils and sunscreen."
        ]

        let motivation = Insight(
            id: UUID(),
            title: "Motivation",
            description: motivationPool.randomElement() ?? motivationPool[0],
            type: .achievement,
            date: now,
            reason: "Always include one motivational nudge."
        )

        // Helpful tip should add value beyond simply listing routine steps
        let helpingDescription: String = {
            guard let recs = recommendations else { return helpingPool.randomElement() ?? helpingPool[0] }

            let lowerNames: [String] = (
                recs.morningRoutine + recs.eveningRoutine + recs.weeklyTreatments
            ).map { $0.name.lowercased() }

            var candidates: [String] = []
            // Context-aware candidates based on present actives
            if lowerNames.contains(where: { $0.contains("vitamin c") || $0.contains("ascorbic") }) {
                candidates.append("Use vitamin C in the morning and reapply SPF every 2 hours when outdoors.")
            }
            if lowerNames.contains(where: { $0.contains("retinol") || $0.contains("retinoid") || $0.contains("tretinoin") }) {
                candidates.append("Introduce retinoids slowly (2-3x/week) and use a pea-sized amount—buffer with moisturizer if sensitive.")
            }
            if lowerNames.contains(where: { $0.contains("aha") || $0.contains("bha") || $0.contains("glycolic") || $0.contains("salicylic") || $0.contains("lactic") || $0.contains("peel") }) {
                candidates.append("Avoid combining strong exfoliants with retinoids in the same night to reduce irritation.")
            }
            if lowerNames.contains(where: { $0.contains("clay") || $0.contains("mask") }) {
                candidates.append("After a clay mask, follow with a hydrating serum and rich moisturizer to prevent dryness.")
            }

            // If we generated context-aware tips, prefer one of them; otherwise fall back to general pool
            if let chosen = candidates.randomElement() { return chosen }
            return helpingPool.randomElement() ?? helpingPool[0]
        }()

        let helping = Insight(
            id: UUID(),
            title: "Helpful Tip",
            description: helpingDescription,
            type: .tip,
            date: now,
            reason: "Provide one practical step the user can apply right now."
        )

        // Choose one contextual insight from computed list above if available
        let contextual = insights.first ?? Insight(
            id: UUID(),
            title: "Routine Ready",
            description: "Your personalized routine is ready to follow.",
            type: .improvement,
            date: now,
            reason: "Fallback contextual insight."
        )

        return [motivation, helping, contextual]
    }
}
