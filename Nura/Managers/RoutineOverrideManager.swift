import Foundation
import SwiftUI

@MainActor
final class RoutineOverrideManager: ObservableObject {
    struct RoutineOverride: Identifiable, Codable, Equatable {
        let id: UUID
        let product: ProductSearchResult
        let category: SkincareStep.StepCategory
        let stepTime: SkincareStep.StepTime
    }

    @Published private(set) var overrides: [RoutineOverride] = []

    private let storageKey = "nura.routine.overrides.v1"

    init() {
        load()
    }

    func save(product: ProductSearchResult, inferredFrom name: String) {
        let category = Self.inferCategory(from: product.name) ?? Self.inferCategory(from: name) ?? .treatment
        let stepTime = Self.inferStepTime(from: product.name) ?? Self.inferStepTime(from: name) ?? .anytime

        let new = RoutineOverride(id: UUID(), product: product, category: category, stepTime: stepTime)
        // Replace existing override for same slot
        overrides.removeAll { $0.category == category && $0.stepTime == stepTime }
        overrides.append(new)
        persist()
        print("💾 RoutineOverride: saved product=\(product.name) cat=\(category.rawValue) time=\(stepTime.rawValue)")
    }

    // Explicit slot API for targeted swaps
    func save(product: ProductSearchResult, category: SkincareStep.StepCategory, stepTime: SkincareStep.StepTime) {
        let new = RoutineOverride(id: UUID(), product: product, category: category, stepTime: stepTime)
        overrides.removeAll { $0.category == category && $0.stepTime == stepTime }
        overrides.append(new)
        persist()
        print("💾 RoutineOverride: saved (explicit) product=\(product.name) cat=\(category.rawValue) time=\(stepTime.rawValue)")
    }

    func override(for category: SkincareStep.StepCategory, stepTime: SkincareStep.StepTime) -> RoutineOverride? {
        if let exact = overrides.first(where: { $0.category == category && $0.stepTime == stepTime }) {
            return exact
        }
        // Fallback: allow an override saved with `.anytime` to apply to either morning or evening
        return overrides.first { $0.category == category && $0.stepTime == .anytime }
    }

    func clearAll() {
        overrides.removeAll()
        persist()
    }

    // Apply overrides to AI recommendations; returns a modified copy
    func applyOverrides(to recs: SkincareRecommendations) -> SkincareRecommendations {
        func mapSteps(_ steps: [SkincareStep], time: SkincareStep.StepTime) -> [SkincareStep] {
            steps.map { step in
                if let o = override(for: step.category, stepTime: time) {
                    return SkincareStep(
                        id: step.id,
                        name: o.product.name,
                        description: step.description,
                        category: step.category,
                        duration: step.duration,
                        frequency: step.frequency,
                        stepTime: time,
                        conflictsWith: step.conflictsWith,
                        requiresSPF: step.requiresSPF,
                        tips: step.tips
                    )
                }
                return step
            }
        }

        let modifiedMorning = mapSteps(recs.morningRoutine, time: .morning)
        let modifiedEvening = mapSteps(recs.eveningRoutine, time: .evening)
        let modifiedWeekly = recs.weeklyTreatments // no overrides for weekly yet

        return SkincareRecommendations(
            morningRoutine: modifiedMorning,
            eveningRoutine: modifiedEvening,
            weeklyTreatments: modifiedWeekly,
            lifestyleTips: recs.lifestyleTips,
            productRecommendations: recs.productRecommendations,
            progressTracking: recs.progressTracking
        )
    }

    // MARK: - Persistence
    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey), let saved = try? JSONDecoder().decode([RoutineOverride].self, from: data) {
            overrides = saved
        }
    }
    private func persist() {
        if let data = try? JSONEncoder().encode(overrides) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - Inference Helpers
    static func inferCategory(from text: String) -> SkincareStep.StepCategory? {
        let l = text.lowercased()
        if l.contains("sunscreen") || l.contains("spf") { return .sunscreen }
        if l.contains("cleanser") || l.contains("wash") { return .cleanser }
        if l.contains("toner") { return .toner }
        if l.contains("retinol") || l.contains("retinoid") { return .treatment }
        if l.contains("vitamin c") || l.contains("vit c") { return .serum }
        if l.contains("serum") { return .serum }
        if l.contains("moistur") || l.contains("cream") || l.contains("lotion") { return .moisturizer }
        if l.contains("mask") { return .mask }
        return nil
    }

    static func inferStepTime(from text: String) -> SkincareStep.StepTime? {
        let l = text.lowercased()
        if l.contains("sunscreen") || l.contains("spf") || l.contains("vitamin c") { return .morning }
        if l.contains("retinol") || l.contains("retinoid") { return .evening }
        return nil
    }
}


