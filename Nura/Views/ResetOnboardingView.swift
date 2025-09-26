import SwiftUI

struct ResetOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var draft: OnboardingAnswers? = nil
    @State private var originalAnswers: OnboardingAnswers? = nil
    @State private var error: String? = nil
    @State private var isSaving: Bool = false
    @State private var showConfirm: Bool = false
    // Local UI state for dermatologist composite controls
    @State private var dermSelection: String = ""
    @State private var medsSelection: String = ""

    private let purple = Color(red: 0.52, green: 0.24, blue: 0.67)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Basics", items: [
                        dropdown("Age", keyPath: \OnboardingAnswers.age, options: ["18-24","25-34","35-44","45-54","55-64","65+"]),
                        dropdown("Sex", keyPath: \OnboardingAnswers.sex, options: ["Female","Male","Non-binary","Prefer not to say"]),
                        dropdown("Skincare goal", keyPath: \OnboardingAnswers.skincareGoal, options: ["Clear up acne","Reduce dryness","Improve glow","Slow aging","Just exploring"])])

                    sectionCard(title: "Lifestyle", items: [
                        dropdown("Activity level", keyPath: \OnboardingAnswers.activityLevel, options: ["Sedentary","Light activity","Moderate","Intense"]),
                        dropdown("Hydration level", keyPath: \OnboardingAnswers.hydrationLevel, options: ["<0.5 gal","0.5–1 gal","1–1.5 gal",">1.5 gal"]),
                        dropdown("Smoking status", keyPath: \OnboardingAnswers.smokingStatus, options: ["No","Occasionally","Daily"]),
                        dropdown("Sleep quality", keyPath: \OnboardingAnswers.sleepQuality, options: ["<6 hrs","6–7 hrs","7–8 hrs",">8 hrs"])])

                    sectionCard(title: "Skin & Health", items: [
                        dropdown("Skin conditions", keyPath: \OnboardingAnswers.skinConditions, options: ["None","Acne","Eczema","Rosacea"]) ,
                        dermatologistComposite(),
                        dropdown("Health conditions", keyPath: \OnboardingAnswers.healthConditions, options: ["None","PCOS","Thyroid","Autoimmune","Family history","Other"])])

                    sectionCard(title: "Women's Health (Optional)", items: [
                        dropdownOptional("Period/Cycle info", keyPath: \OnboardingAnswers.periodCycleInfo, options: ["","24d","28d","32d","Follicular","Luteal"]) ,
                        dropdownOptional("Birth control", keyPath: \OnboardingAnswers.birthControlInfo, options: ["","None","Pill","IUD","Implant","Ring"])])

                    if let error = error { Text(error).foregroundColor(.red) }
                }
                .padding()
            }
            .background(LinearGradient(gradient: Gradient(colors: [Color(red:1.0,green:0.97,blue:0.94), Color(red:0.98,green:0.93,blue:0.98)]), startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea())
            .navigationTitle("Edit Onboarding")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Apply") { Task { await save() } }
                        .disabled(isSaving)
                }
            }
            .onAppear { loadDraft() }
            // Keep the draft in sync if the profile arrives/changes after view appears
            .onReceive(NotificationCenter.default.publisher(for: .userProfileDidChange)) { _ in
                loadDraft()
            }
        }
    }

    private func loadDraft() {
        if let answers = authManager.getOnboardingAnswers() {
            draft = answers
            originalAnswers = answers
            let parsed = parseDermatologistStatus(answers.dermatologistStatus)
            dermSelection = parsed.derm
            medsSelection = parsed.meds
        } else {
            // Initialize an empty but valid draft to allow editing
            draft = OnboardingAnswers(
                age: "",
                sex: "",
                activityLevel: "",
                hydrationLevel: "",
                skincareGoal: "",
                skinConditions: "",
                dermatologistStatus: "",
                healthConditions: "",
                smokingStatus: "",
                sleepQuality: ""
            )
            originalAnswers = nil
            dermSelection = ""
            medsSelection = ""
        }
    }

    private func binding(_ keyPath: WritableKeyPath<OnboardingAnswers, String>) -> Binding<String> {
        Binding<String>(
            get: { draft?[keyPath: keyPath] ?? "" },
            set: { draft?[keyPath: keyPath] = $0 }
        )
    }

    private func optionalBinding(_ keyPath: WritableKeyPath<OnboardingAnswers, String?>) -> Binding<String> {
        Binding<String>(
            get: { draft?[keyPath: keyPath] ?? "" },
            set: { draft?[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }

    private func saveDiff(_ updated: OnboardingAnswers) async throws {
        await authManager.setOnboardingComplete(onboardingAnswers: updated)
    }

    private func save() async {
        guard let updated = draft else { return }
        await MainActor.run { isSaving = true; error = nil }
        do {
            try await saveDiff(updated)
            await MainActor.run { isSaving = false; dismiss() }
        } catch {
            await MainActor.run {
                isSaving = false
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - UI Helpers
extension ResetOnboardingView {
    @ViewBuilder
    func sectionCard(title: String, items: [AnyView]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            VStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, v in v }
            }
            .padding(12)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }

    func dropdown(_ label: String, keyPath: WritableKeyPath<OnboardingAnswers, String>, options: [String]) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 6) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Menu {
                    ForEach(options, id: \.self) { opt in
                        Button(opt) { draft?[keyPath: keyPath] = opt }
                    }
                } label: {
                    HStack {
                        Text(draft?[keyPath: keyPath].isEmpty == false ? draft![keyPath: keyPath] : "Select")
                            .foregroundColor(draft?[keyPath: keyPath].isEmpty == false ? .primary : .secondary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color(red:0.97,green:0.96,blue:0.98))
                    .cornerRadius(10)
                }
                if let original = originalAnswers?[keyPath: keyPath], !original.isEmpty {
                    Text("Selected: \(original)")
                        .font(.caption2)
                        .italic()
                        .foregroundColor(.secondary)
                }
            }
        )
    }

    func dropdownOptional(_ label: String, keyPath: WritableKeyPath<OnboardingAnswers, String?>, options: [String]) -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 6) {
                Text(label).font(.caption).foregroundColor(.secondary)
                Menu {
                    ForEach(options, id: \.self) { opt in
                        Button(opt.isEmpty ? "—" : opt) { draft?[keyPath: keyPath] = opt.isEmpty ? nil : opt }
                    }
                } label: {
                    HStack {
                        Text((draft?[keyPath: keyPath] ?? "").isEmpty == false ? (draft?[keyPath: keyPath] ?? "") : "Select")
                            .foregroundColor(((draft?[keyPath: keyPath] ?? "").isEmpty == false) ? .primary : .secondary)
                        Spacer()
                        Image(systemName: "chevron.down").foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color(red:0.97,green:0.96,blue:0.98))
                    .cornerRadius(10)
                }
                if let originalVal = originalAnswers?[keyPath: keyPath], !originalVal.isEmpty {
                    Text("Selected: \(originalVal)")
                        .font(.caption2)
                        .italic()
                        .foregroundColor(.secondary)
                }
            }
        )
    }

    // Composite control: Dermatologist + Medications
    func dermatologistComposite() -> AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: 6) {
                Text("Dermatologist status").font(.caption).foregroundColor(.secondary)
                VStack(spacing: 8) {
                    // Dermatologist
                    Menu {
                        ForEach(["No","Yes – checkups only","Yes – currently under treatment"], id: \.self) { opt in
                            Button(opt) {
                                dermSelection = opt
                                draft?.dermatologistStatus = composeDermatologistStatus(derm: dermSelection, meds: medsSelection)
                            }
                        }
                    } label: {
                        HStack {
                            Text(dermSelection.isEmpty ? "Select" : dermSelection)
                                .foregroundColor(dermSelection.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down").foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color(red:0.97,green:0.96,blue:0.98))
                        .cornerRadius(10)
                    }
                    if let original = originalAnswers?.dermatologistStatus, !original.isEmpty {
                        let parsed = parseDermatologistStatus(original)
                        Text("Selected: \(parsed.derm)")
                            .font(.caption2)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                    // Medications
                    Menu {
                        ForEach(["None","Topicals (e.g., retinoids)","Orals (e.g., antibiotics)","Both"], id: \.self) { opt in
                            Button(opt) {
                                medsSelection = opt
                                draft?.dermatologistStatus = composeDermatologistStatus(derm: dermSelection, meds: medsSelection)
                            }
                        }
                    } label: {
                        HStack {
                            Text(medsSelection.isEmpty ? "Select" : medsSelection)
                                .foregroundColor(medsSelection.isEmpty ? .secondary : .primary)
                            Spacer()
                            Image(systemName: "chevron.down").foregroundColor(.secondary)
                        }
                        .padding(10)
                        .background(Color(red:0.97,green:0.96,blue:0.98))
                        .cornerRadius(10)
                    }
                    if let original = originalAnswers?.dermatologistStatus, !original.isEmpty {
                        let parsed = parseDermatologistStatus(original)
                        Text("Selected: \(parsed.meds)")
                            .font(.caption2)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                }
            }
        )
    }

    // MARK: - Parsing helpers for dermatologist composite
    func parseDermatologistStatus(_ value: String) -> (derm: String, meds: String) {
        if value.contains("Dermatologist:") && value.contains("Medications:") {
            let parts = value.split(separator: "|").map { String($0).trimmingCharacters(in: .whitespaces) }
            var derm = ""
            var meds = ""
            for part in parts {
                if part.lowercased().hasPrefix("dermatologist:") {
                    derm = part.replacingOccurrences(of: "Dermatologist:", with: "").trimmingCharacters(in: .whitespaces)
                } else if part.lowercased().hasPrefix("medications:") {
                    meds = part.replacingOccurrences(of: "Medications:", with: "").trimmingCharacters(in: .whitespaces)
                }
            }
            return (derm, meds)
        }
        return ("", "")
    }

    func composeDermatologistStatus(derm: String, meds: String) -> String {
        guard !derm.isEmpty || !meds.isEmpty else { return "" }
        return "Dermatologist: \(derm.isEmpty ? "No" : derm) | Medications: \(meds.isEmpty ? "None" : meds)"
    }
}
