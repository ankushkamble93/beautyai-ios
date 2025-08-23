import SwiftUI

struct RoutineView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @EnvironmentObject var routineOverrideManager: RoutineOverrideManager
    @State private var showSwapSheet: Bool = false
    @State private var swapQuery: String = ""
    @State private var swapResults: [ProductSearchResult] = []
    @State private var swappingSlot: (time: SkincareStep.StepTime, category: SkincareStep.StepCategory)? = nil
    @State private var animate = false
    let bubbleWidth: CGFloat = 340
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
    private var mainBackground: LinearGradient {
        colorScheme == .dark ?
            LinearGradient(gradient: Gradient(colors: [Color.black, Color(red: 0.13, green: 0.12, blue: 0.11)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(gradient: Gradient(colors: [Color(red: 0.97, green: 0.96, blue: 0.99), Color(red: 0.93, green: 0.94, blue: 0.98)]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var body: some View {
        NavigationView {
            ZStack {
                mainBackground.ignoresSafeArea()
                // Abstract floating shapes for spa-like effect
                Circle()
                    .fill(colorScheme == .dark ? Color.purple.opacity(0.13) : Color.purple.opacity(0.08))
                    .frame(width: 220, height: 220)
                    .offset(x: -120, y: -180)
                RoundedRectangle(cornerRadius: 80)
                    .fill(colorScheme == .dark ? Color.blue.opacity(0.13) : Color.blue.opacity(0.07))
                    .frame(width: 180, height: 90)
                    .rotationEffect(.degrees(18))
                    .offset(x: 120, y: 220)
                Circle()
                    .fill(colorScheme == .dark ? Color.orange.opacity(0.11) : Color.orange.opacity(0.06))
                    .frame(width: 120, height: 120)
                    .offset(x: 100, y: -100)
                ScrollView {
                    VStack(alignment: .center, spacing: 28) {
                        // Title higher up
                        HStack {
                            Spacer()
                            Text("Your Routine")
                                .font(.largeTitle).fontWeight(.bold)
                                .padding(.top, 24)
                                .padding(.bottom, 2)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        // Top row: Combined Routine (left) and Quick Stats (right)
                        HStack(alignment: .top, spacing: 18) {
                            // Combined Routine Floater (left)
                            CombinedRoutineView(
                                morning: displayedMorningSteps,
                                evening: displayedEveningSteps,
                                weekly: displayedWeeklySteps,
                                cardBackground: cardBackground,
                                onSwap: { time, category in
                                    startSwap(time, category)
                                }
                            )
                                .frame(width: bubbleWidth * 0.55)
                                .opacity(animate ? 1 : 0)
                                .offset(y: animate ? 0 : 30)
                                .animation(.easeOut(duration: 0.7).delay(0.1), value: animate)
                                .overlay(alignment: .topTrailing) {
                                    Menu {
                                        Button("Swap Morning Cleanser") { startSwap(.morning, .cleanser) }
                                        Button("Swap Morning Serum") { startSwap(.morning, .serum) }
                                        Button("Swap Evening Treatment") { startSwap(.evening, .treatment) }
                                    } label: {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .foregroundColor(.blue)
                                            .padding(6)
                                    }
                                }
                            // Quick Stats Floater (right)
                            VStack(spacing: 16) {
                                StatBubbleView(
                                    title: "Hydration",
                                    value: "8 cups",
                                    icon: "drop.fill",
                                    gradient: colorScheme == .dark ? Gradient(colors: [Color.cyan.opacity(0.23), Color.blue.opacity(0.18)]) : Gradient(colors: [Color.cyan.opacity(0.18), Color.blue.opacity(0.13)]),
                                    cardBackground: cardBackground
                                )
                                StatBubbleView(
                                    title: "Workout",
                                    value: "30 min",
                                    icon: "figure.walk",
                                    gradient: colorScheme == .dark ? Gradient(colors: [Color.green.opacity(0.23), Color.blue.opacity(0.18)]) : Gradient(colors: [Color.green.opacity(0.18), Color.blue.opacity(0.13)]),
                                    cardBackground: cardBackground
                                )
                                StatBubbleView(
                                    title: "Weather",
                                    value: "Sunny",
                                    icon: "sun.max.fill",
                                    gradient: colorScheme == .dark ? Gradient(colors: [Color.orange.opacity(0.23), Color.yellow.opacity(0.18)]) : Gradient(colors: [Color.orange.opacity(0.18), Color.yellow.opacity(0.13)]),
                                    cardBackground: cardBackground
                                )
                            }
                            .frame(width: bubbleWidth * 0.45)
                            .opacity(animate ? 1 : 0)
                            .offset(y: animate ? 0 : 30)
                            .animation(.easeOut(duration: 0.7).delay(0.2), value: animate)
                        }
                        .frame(maxWidth: bubbleWidth)
                        .padding(.top, 0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 0)
                    // Modern, finished bottom section
                    GeometryReader { geo in
                        VStack(spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Color.yellow.opacity(0.7))
                                    .font(.system(size: 20, weight: .medium))
                                Text("Small daily habits create big changes.")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 16, weight: .medium))
                                Text("3-day streak! Keep it up 🌱")
                                    .font(.footnote)
                                    .foregroundColor(colorScheme == .dark ? Color.orange.opacity(0.95) : Color.orange.opacity(0.85))
                            }
                            .padding(.top, 2)
                        }
                        .frame(maxWidth: .infinity)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.5), value: animate)
                    }
                    .frame(height: 120) // Adjust height as needed for vertical centering
                    // End modern bottom section
                    .onAppear { animate = true }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle("")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { presentationMode.wrappedValue.dismiss() }
                    }
                }
            }
        }
        .sheet(isPresented: $showSwapSheet) {
            NavigationView {
                VStack(spacing: 12) {
                    HStack {
                        TextField("Search products…", text: $swapQuery)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Search") { Task { await performSwapSearch() } }
                    }
                    .padding()
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(swapResults) { p in
                                Button(action: { selectSwapProduct(p) }) {
                                    ProductCardView(product: p)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .navigationTitle("Swap Step")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Done") { showSwapSheet = false } }
                }
            }
        }
    }

    // MARK: - Derived routines from latest recommendations with overrides applied
    private var displayedMorningSteps: [SkincareStep] {
        guard let recs = skinAnalysisManager.recommendations else { return sampleMorning }
        let overridden = routineOverrideManager.applyOverrides(to: recs)
        return overridden.morningRoutine
    }
    private var displayedEveningSteps: [SkincareStep] {
        guard let recs = skinAnalysisManager.recommendations else { return sampleEvening }
        let overridden = routineOverrideManager.applyOverrides(to: recs)
        return overridden.eveningRoutine
    }
    private var displayedWeeklySteps: [SkincareStep] {
        guard let recs = skinAnalysisManager.recommendations else { return [] }
        let overridden = routineOverrideManager.applyOverrides(to: recs)
        return overridden.weeklyTreatments
    }
    private var sampleMorning: [SkincareStep] {
        [
            SkincareStep(name: "Cleanser", description: "", category: .cleanser, duration: 60, frequency: .daily, stepTime: .morning, tips: []),
            SkincareStep(name: "Vitamin C Serum", description: "", category: .serum, duration: 60, frequency: .daily, stepTime: .morning, tips: []),
            SkincareStep(name: "Moisturizer", description: "", category: .moisturizer, duration: 60, frequency: .daily, stepTime: .morning, tips: []),
            SkincareStep(name: "SPF 50", description: "", category: .sunscreen, duration: 60, frequency: .daily, stepTime: .morning, tips: [])
        ]
    }
    private var sampleEvening: [SkincareStep] {
        [
            SkincareStep(name: "Cleanser", description: "", category: .cleanser, duration: 60, frequency: .daily, stepTime: .evening, tips: []),
            SkincareStep(name: "Retinol Serum", description: "", category: .treatment, duration: 60, frequency: .nightly, stepTime: .evening, tips: []),
            SkincareStep(name: "Moisturizer", description: "", category: .moisturizer, duration: 60, frequency: .nightly, stepTime: .evening, tips: [])
        ]
    }
}

// Combined Routine Floater (for easy ChatGPT integration)
struct CombinedRoutineView: View {
    let morning: [SkincareStep]
    let evening: [SkincareStep]
    let weekly: [SkincareStep]
    let cardBackground: Color
    var onSwap: ((SkincareStep.StepTime, SkincareStep.StepCategory) -> Void)? = nil
    @State private var animateOnce: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sun.max.fill").foregroundColor(.yellow)
                Text("Morning Routine")
                    .font(.headline).fontWeight(.semibold)
            }
            ForEach(morning) { step in
                routineRow(step)
            }
            Divider().padding(.vertical, 4)
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill").foregroundColor(.purple)
                Text("Night Routine")
                    .font(.headline).fontWeight(.semibold)
            }
            ForEach(evening) { step in
                routineRow(step)
            }
            if !weekly.isEmpty {
                Divider().padding(.vertical, 4)
                HStack(spacing: 8) {
                    Image(systemName: "calendar").foregroundColor(.orange)
                    Text("Weekly Treatments").font(.headline).fontWeight(.semibold)
                }
                ForEach(weekly) { step in
                    routineRow(step)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(18)
        .shadow(color: Color.blue.opacity(0.08), radius: 10, x: 0, y: 4)
        .onAppear {
            // trigger one-time spin animation for swap glyphs
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                animateOnce = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { animateOnce = false }
            }
        }
    }

    @ViewBuilder
    private func routineRow(_ step: SkincareStep) -> some View {
        HStack {
            ZStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(colorFor(step.category))
                    .font(.system(size: 18))
                // White border swap symbol centered; rotate once
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(animateOnce ? 360 : 0))
                    .animation(.easeOut(duration: 0.9), value: animateOnce)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onSwap?(step.stepTime, step.category)
            }
            Text(step.name).font(.body)
        }
    }

    private func colorFor(_ category: SkincareStep.StepCategory) -> Color {
        switch category {
        case .cleanser: return Color.blue.opacity(0.7)
        case .toner: return Color.cyan.opacity(0.7)
        case .serum: return Color.purple.opacity(0.7)
        case .moisturizer: return Color.green.opacity(0.7)
        case .sunscreen: return Color.yellow.opacity(0.8)
        case .treatment: return Color.orange.opacity(0.8)
        case .mask: return Color.orange.opacity(0.8)
        }
    }
}

// MARK: - Swap helpers
extension RoutineView {
    private func startSwap(_ time: SkincareStep.StepTime, _ category: SkincareStep.StepCategory) {
        swappingSlot = (time: time, category: category)
        showSwapSheet = true
    }
    private func performSwapSearch() async {
        let q = swapQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        let query = ProductSearchManager.ProductQuery(rawText: q, normalizedQuery: q, categoryHint: nil)
        let results = await ProductSearchManager.shared.searchProducts(query: query)
        swapResults = results
    }
    private func selectSwapProduct(_ p: ProductSearchResult) {
        guard let slot = swappingSlot else { return }
        routineOverrideManager.save(product: p, category: slot.category, stepTime: slot.time)
        // Reflect immediately by closing and clearing results
        swapResults = []
        swapQuery = ""
        showSwapSheet = false
    }
}

// Stat Bubble Floater
struct StatBubbleView: View {
    let title: String
    let value: String
    let icon: String
    let gradient: Gradient
    let cardBackground: Color
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.headline).fontWeight(.semibold)
                .foregroundColor(.primary)
            ZStack {
                Circle()
                    .strokeBorder(LinearGradient(gradient: gradient, startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 3)
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.primary)
            }
            Text(value)
                .font(.title3).fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(cardBackground)
        .cornerRadius(14)
        .shadow(color: Color.gray.opacity(0.08), radius: 6, x: 0, y: 2)
    }
} 