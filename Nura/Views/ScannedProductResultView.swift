import SwiftUI

struct ScannedProductResultView: View {
    let resolved: ResolvedProduct
    let verdict: FitVerdict
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager
    @EnvironmentObject var routineOverrideManager: RoutineOverrideManager
    var onAskNura: (() -> Void)?
    var onClose: (() -> Void)?
    @State private var showManualSheet = false

    var body: some View {
        let isDark = appearanceManager.isDarkMode
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image header
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 220)
                        .cornerRadius(18)
                    if let urlStr = resolved.imageURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): image.resizable().scaledToFit()
                            case .failure: Image(systemName: "photo").resizable().scaledToFit().foregroundColor(.secondary)
                            case .empty: ProgressView()
                            @unknown default: ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                    }
                }

                // Title & brand
                VStack(alignment: .leading, spacing: 4) {
                    Text(resolved.name.isEmpty ? "Unknown product" : resolved.name)
                        .font(.title2).fontWeight(.bold)
                    if let b = resolved.brand, !b.isEmpty {
                        Text(b).foregroundColor(.secondary)
                    }
                }

                // Verdict chip
                HStack {
                    Text(verdict.verdict)
                        .font(.subheadline).fontWeight(.semibold)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(verdictColor().opacity(0.15))
                        .foregroundColor(verdictColor())
                        .cornerRadius(16)
                    Spacer()
                }

                // Why & warnings
                if !verdict.why.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why it fits you").font(.headline)
                        ForEach(verdict.why, id: \.self) { item in
                            HStack(spacing: 8) { Image(systemName: "checkmark.seal.fill").foregroundColor(.green); Text(item).foregroundColor(.secondary) }
                        }
                    }
                }
                if !verdict.warnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Warnings").font(.headline)
                        ForEach(verdict.warnings, id: \.self) { item in
                            HStack(spacing: 8) { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange); Text(item).foregroundColor(.secondary) }
                        }
                    }
                }

                // No data state
                if resolved.ingredients == nil || resolved.ingredients?.isEmpty == true {
                    Text("We don’t have data for this product yet.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Add details manually") { showManualSheet = true }
                        .font(.caption)
                        .padding(.top, 4)
                }

                // Actions
                VStack(spacing: 12) {
                    if !(resolved.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || resolved.name.lowercased() == "unknown product") {
                        Button(action: { onAskNura?() }) {
                            HStack(spacing: 8) { Image(systemName: "sparkles"); Text("Ask Nura for a deeper fit").fontWeight(.semibold) }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(LinearGradient(gradient: Gradient(colors: [NuraColors.primary, .purple]), startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(24)
                        }
                    }

                    if resolved.ingredients != nil && !(resolved.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || resolved.name.lowercased() == "unknown product") {
                        SaveToRoutineChooser(productName: resolved.name) { selections in
                            for s in selections { routineOverrideManager.save(product: s.product, category: s.category, stepTime: s.stepTime) }
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .background(isDark ? NuraColors.backgroundDark : Color(red: 0.98, green: 0.97, blue: 0.95))
        .sheet(isPresented: $showManualSheet) {
            ManualProductEntrySheet(initialName: resolved.name) { name, brand, ingredients in
                let ing = ingredients.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let updated = ResolvedProduct(barcode: resolved.barcode, name: name, brand: brand, imageURL: resolved.imageURL, ingredients: ing, retailerURL: resolved.retailerURL)
                Task { await SupabaseProductCacheManager.shared.upsert(resolved: updated, source: .manual, manual: true) }
            }
            .environmentObject(appearanceManager)
        }
    }

    private func verdictColor() -> Color {
        switch verdict.verdict {
        case "Great fit": return .green
        case "Okay with caveats": return .orange
        default: return .red
        }
    }
}

private struct ManualProductEntrySheet: View {
    let initialName: String
    var onSave: (String, String?, String) -> Void
    @EnvironmentObject var appearanceManager: AppearanceManager
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var brand: String = ""
    @State private var ingredients: String = ""

    var body: some View {
        let isDark = appearanceManager.isDarkMode
        NavigationView {
            Form {
                Section(header: Text("Name")) { TextField("Product name", text: $name) }
                Section(header: Text("Brand (optional)")) { TextField("Brand", text: $brand) }
                Section(header: Text("Ingredients (comma-separated)")) { TextField("e.g. water, glycerin, niacinamide", text: $ingredients) }
            }
            .navigationTitle("Add details")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Save") { onSave(name, brand.isEmpty ? nil : brand, ingredients); dismiss() }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }
            }
            .background(isDark ? NuraColors.backgroundDark : Color(.systemGroupedBackground))
            .onAppear { name = initialName == "Unknown product" ? "" : initialName }
        }
    }
}

private struct SaveToRoutineChooser: View {
    struct Selection { let product: ProductSearchResult; let category: SkincareStep.StepCategory; let stepTime: SkincareStep.StepTime }
    let productName: String
    var onSave: ([Selection]) -> Void
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager
    @State private var isPresented = false
    @State private var selections: Set<String> = []

    var body: some View {
        Button(action: { isPresented = true }) {
            HStack(spacing: 8) { Image(systemName: "plus.circle.fill"); Text("Save to Routine").fontWeight(.semibold) }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(LinearGradient(gradient: Gradient(colors: [NuraColors.primary, .purple]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(24)
        }
        .sheet(isPresented: $isPresented) {
            RoutineMultiSelectSheet(productName: productName, selections: $selections) { final in
                onSave(final)
                isPresented = false
            }
            .environmentObject(appearanceManager)
            .environmentObject(userTierManager)
        }
    }
}

private struct RoutineMultiSelectSheet: View {
    let productName: String
    @Binding var selections: Set<String>
    var onDone: ([SaveToRoutineChooser.Selection]) -> Void
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager

    // Placeholder routine list; in implementation, pull from user's current routine
    private var items: [(title: String, category: SkincareStep.StepCategory, time: SkincareStep.StepTime)] {
        [
            ("Morning • Cleanser", .cleanser, .morning),
            ("Morning • Serum", .serum, .morning),
            ("Morning • Moisturizer", .moisturizer, .morning),
            ("Morning • Sunscreen", .sunscreen, .morning),
            ("Evening • Cleanser", .cleanser, .evening),
            ("Evening • Treatment", .treatment, .evening)
        ]
    }

    var body: some View {
        let isDark = appearanceManager.isDarkMode
        NavigationView {
            List {
                ForEach(items, id: \.title) { item in
                    HStack { Text(item.title); Spacer(); if selections.contains(item.title) { Image(systemName: "checkmark").foregroundColor(.blue) } }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selections.contains(item.title) { selections.remove(item.title) } else { selections.insert(item.title) }
                        }
                }
            }
            .navigationTitle("Select routine steps")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let mapped: [SaveToRoutineChooser.Selection] = items.filter { selections.contains($0.title) }.map { item in
                            let psr = ProductSearchResult(name: productName, brand: nil, priceText: nil, benefits: [], imageURL: nil, destinationURL: nil)
                            return SaveToRoutineChooser.Selection(product: psr, category: item.category, stepTime: item.time)
                        }
                        onDone(mapped)
                    }.disabled(selections.isEmpty)
                }
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { selections.removeAll(); onDone([]) } }
            }
            .background(isDark ? NuraColors.backgroundDark : Color(.systemBackground))
        }
    }
}


