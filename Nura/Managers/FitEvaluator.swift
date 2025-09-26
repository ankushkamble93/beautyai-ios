import Foundation

struct FitVerdict {
    let score: Int
    let verdict: String
    let why: [String]
    let warnings: [String]
}

final class FitEvaluator {
    static let shared = FitEvaluator()

    func evaluate(productName: String, ingredients: [String]?, onboarding: OnboardingAnswers) -> FitVerdict {
        // If we have no usable metadata, return a neutral unavailable verdict
        let nameTrimmed = productName.trimmingCharacters(in: .whitespacesAndNewlines)
        let noIngredients = (ingredients == nil) || (ingredients?.isEmpty == true)
        let isUnknownName = nameTrimmed.isEmpty || nameTrimmed.lowercased() == "unknown product"
        if noIngredients && isUnknownName {
            return FitVerdict(score: 50, verdict: "Data unavailable", why: [], warnings: [])
        }

        var score = 50
        var why: [String] = []
        var warnings: [String] = []

        let name = productName.lowercased()
        let ings = Set((ingredients ?? []).map { $0.lowercased() })
        let conds = onboarding.skinConditions.lowercased()
        let goal = onboarding.skincareGoal.lowercased()
        let health = onboarding.healthConditions.lowercased()

        func bump(_ v: Int, reason: String) { score += v; if v > 0 { why.append(reason) } }
        func warn(_ v: Int, reason: String) { score -= v; warnings.append(reason) }

        // Acne/oily signals
        if conds.contains("acne") || conds.contains("oily") {
            if containsAny(in: ings, ["salicylic", "bpo", "benzoyl", "niacinamide"]) { bump(15, reason: "Supports acne-prone skin") }
            if containsAny(in: ings, ["isopropyl myristate", "coconut oil", "lanolin"]) { warn(15, reason: "May clog pores for acne-prone skin") }
        }

        // Sensitive/eczema/rosacea
        if conds.contains("sensitive") || conds.contains("eczema") || conds.contains("rosacea") {
            if containsAny(in: ings, ["ceramide", "panthenol", "oat", "allantoin"]) { bump(12, reason: "Soothing ingredients for sensitive skin") }
            if containsAny(in: ings, ["fragrance", "parfum", "essential oil", "alcohol denat"]) { warn(12, reason: "Potential irritants for sensitive skin") }
        }

        // Hydration goal
        if goal.contains("hydrate") || goal.contains("hydration") || goal.contains("dry") {
            if containsAny(in: ings, ["hyaluronic", "glycerin", "squalane", "ceramide"]) { bump(12, reason: "Hydrating ingredients match your goal") }
        }

        // Hyperpigmentation
        if goal.contains("dark spot") || goal.contains("pigment") || conds.contains("melasma") {
            if containsAny(in: ings, ["ascorbic", "vitamin c", "azelaic", "kojic", "niacinamide"]) { bump(10, reason: "Targets discoloration concerns") }
        }

        // Pregnancy caution
        if health.contains("pregnan") {
            if containsAny(in: ings, ["retinol", "retinal", "tretinoin"]) { warn(30, reason: "Retinoids are not recommended during pregnancy") }
            if containsAny(in: ings, ["salicylic"]) { warn(8, reason: "High-strength salicylates may be unsuitable during pregnancy") }
        }

        // SPF sanity for sunscreen
        if name.contains("sunscreen") || name.contains("spf") {
            bump(5, reason: "Daily sun protection is beneficial")
        }

        // Clamp and map verdict
        score = max(0, min(100, score))
        let verdict: String = score >= 75 ? "Great fit" : (score >= 50 ? "Okay with caveats" : "Not recommended")
        return FitVerdict(score: score, verdict: verdict, why: Array(why.prefix(4)), warnings: Array(warnings.prefix(4)))
    }

    private func containsAny(in set: Set<String>, _ keys: [String]) -> Bool {
        for k in keys { if set.contains(where: { $0.contains(k) }) { return true } }
        return false
    }
}


