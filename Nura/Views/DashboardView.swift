import SwiftUI
import ConfettiSwiftUI
import Combine

struct DashboardView: View {
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var shareManager: ShareManager
    @EnvironmentObject var userTierManager: UserTierManager
    
    init() {
        print("🔍 DashboardView: Initialized")
    }
    @State private var dashboardData = DashboardData(
        currentRoutine: [],
        progress: ProgressMetrics(
            skinHealthScore: 0.75,
            improvementAreas: ["Acne reduction", "Hydration"],
            nextCheckIn: Date().addingTimeInterval(86400 * 7), // 7 days
            goals: ["Clear skin", "Even skin tone"]
        ),
        recentAnalysis: nil,
        upcomingTasks: [
            DashboardTask(
                id: UUID(),
                title: "Morning Routine",
                description: "Complete your morning skincare routine",
                dueDate: Date(),
                priority: .high,
                isCompleted: false
            ),
            DashboardTask(
                id: UUID(),
                title: "Evening Routine",
                description: "Complete your evening skincare routine",
                dueDate: Date().addingTimeInterval(43200), // 12 hours
                priority: .high,
                isCompleted: false
            ),
            // Weekly Mask will be handled in the tasks list below
        ],
        insights: []
    )
    
    @State private var confettiCounter = 0
    @State private var lastMilestone: Int = 0
    // Weekly Mask state
    @State private var weeklyMaskCompletedAt: Date? = nil
    private let weeklyMaskTask = DashboardTask(
        id: UUID(),
        title: "Weekly Mask",
        description: "Apply your weekly treatment mask",
        dueDate: Date().addingTimeInterval(86400 * 3), // 3 days
        priority: .medium,
        isCompleted: false
    )
    // Computed property for dark mode
    private var isDark: Bool {
        appearanceManager.colorSchemePreference == "dark" ||
        (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark)
    }

    // Computed property for real skin health score
    private var realSkinHealthScore: Double {
        if let analysisResults = skinAnalysisManager.getCachedAnalysisResults() {
            return Double(analysisResults.skinHealthScore) / 100.0
        }
        return 0.78 // Appealing sample score of 78% - shows room for improvement but positive
    }
    
    // Computed property for real skin conditions with affected areas
    private var realSkinConditions: [(name: String, areas: [String], severity: String)] {
        if let analysisResults = skinAnalysisManager.getCachedAnalysisResults() {
            return analysisResults.conditions.compactMap { condition -> (name: String, areas: [String], severity: String)? in
                // Filter out invalid or empty conditions
                guard !condition.name.isEmpty, !condition.affectedAreas.isEmpty else { return nil }
                
                let cleanName = condition.name.trimmingCharacters(in: .whitespacesAndNewlines)
                let cleanAreas = condition.affectedAreas.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let severity = condition.severity.rawValue.capitalized
                
                return (name: cleanName, areas: cleanAreas, severity: severity)
            }
        }
        return [] // Return empty array if no analysis results
    }
    
    // Computed property for average confidence
    private var averageConfidence: Double {
        if let analysisResults = skinAnalysisManager.getCachedAnalysisResults() {
            return analysisResults.confidence
        }
        return 0.0
    }

    // Computed property for AI-generated tasks from recommendations
    private var aiGeneratedTasks: [DashboardTask] {
        guard let recommendations = skinAnalysisManager.recommendations else {
            // Return default sample tasks when no AI recommendations available
            return [
                DashboardTask(
                    id: UUID(),
                    title: "Morning Routine",
                    description: "Complete your morning skincare routine",
                    dueDate: Date(),
                    priority: .high,
                    isCompleted: false
                ),
                DashboardTask(
                    id: UUID(),
                    title: "Evening Routine",
                    description: "Complete your evening skincare routine",
                    dueDate: Date().addingTimeInterval(43200), // 12 hours
                    priority: .high,
                    isCompleted: false
                )
            ]
        }
        
        // Generate tasks from AI recommendations
        var tasks: [DashboardTask] = []
        
        // Morning routine task from AI recommendations
        if !recommendations.morningRoutine.isEmpty {
            let morningSteps = recommendations.morningRoutine.map { $0.name }.joined(separator: ", ")
            tasks.append(DashboardTask(
                id: UUID(),
                title: "Morning Routine",
                description: "\(morningSteps)",
                dueDate: Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 7, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents) ?? Date(),
                priority: .high,
                isCompleted: false
            ))
        }
        
        // Evening routine task from AI recommendations
        if !recommendations.eveningRoutine.isEmpty {
            let eveningSteps = recommendations.eveningRoutine.map { $0.name }.joined(separator: ", ")
            tasks.append(DashboardTask(
                id: UUID(),
                title: "Evening Routine", 
                description: "\(eveningSteps)",
                dueDate: Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 19, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents) ?? Date(),
                priority: .high,
                isCompleted: false
            ))
        }
        
        return tasks
    }
    
    // Computed property for AI-generated weekly tasks
    private var aiGeneratedWeeklyTask: DashboardTask {
        guard let recommendations = skinAnalysisManager.recommendations,
              !recommendations.weeklyTreatments.isEmpty else {
            // Return default weekly task when no AI recommendations available
            return DashboardTask(
                id: UUID(),
                title: "Weekly Mask",
                description: "Apply your weekly treatment mask",
                dueDate: Date().addingTimeInterval(86400 * 3), // 3 days
                priority: .medium,
                isCompleted: false
            )
        }
        
        // Generate weekly task from AI recommendations
        let weeklyTreatments = recommendations.weeklyTreatments.map { $0.name }.joined(separator: ", ")
        return DashboardTask(
            id: UUID(),
            title: "Weekly Routine",
            description: "\(weeklyTreatments)",
            dueDate: Date().addingTimeInterval(86400 * 3), // 3 days
            priority: .medium,
            isCompleted: false
        )
    }
    
    // Computed property for tier-based reload availability
    private var canReloadTasks: Bool {
        switch userTierManager.tier {
        case .free:
            // Free users can reload once per week
            return true // TODO: Implement weekly cooldown tracking
        case .pro:
            // Pro users can reload once per day
            return true // TODO: Implement daily cooldown tracking
        case .proUnlimited:
            // Pro Unlimited users can reload anytime
            return true
        }
    }
    
    // Computed property for reload button text
    private var reloadButtonText: String {
        switch userTierManager.tier {
        case .free:
            return "Reload Tasks (Weekly)"
        case .pro:
            return "Reload Tasks (Daily)"
        case .proUnlimited:
            return "Reload Tasks"
        }
    }

    // MARK: - Insights
    private func updateInsights() {
        let profile = authManager.getOnboardingAnswers()
        let analysis = skinAnalysisManager.getCachedAnalysisResults()
        let recs = skinAnalysisManager.recommendations
        let weekly = weeklyMaskTask
        let generated = InsightEngine.generate(
            profile: profile,
            analysis: analysis,
            recommendations: recs,
            tasks: [],
            weeklyTask: weekly,
            lastUpdated: nil
        )
        dashboardData = DashboardData(
            currentRoutine: dashboardData.currentRoutine,
            progress: dashboardData.progress,
            recentAnalysis: dashboardData.recentAnalysis,
            upcomingTasks: dashboardData.upcomingTasks,
            insights: generated
        )
    }

    // Computed property for AI-powered routines to pass to UpcomingTasksCard
    private var aiGeneratedRoutines: [[String]] {
        // Try to get AI recommendations first
        if let recommendations = skinAnalysisManager.recommendations {
            var aiRoutines: [[String]] = []
            
            // Morning routine from AI
            if !recommendations.morningRoutine.isEmpty {
                aiRoutines.append(recommendations.morningRoutine.map { "\($0.category.rawValue.capitalized): \($0.name)" })
            }
            
            // Evening routine from AI  
            if !recommendations.eveningRoutine.isEmpty {
                aiRoutines.append(recommendations.eveningRoutine.map { "\($0.category.rawValue.capitalized): \($0.name)" })
            }
            
            // Weekly treatments from AI
            if !recommendations.weeklyTreatments.isEmpty {
                aiRoutines.append(recommendations.weeklyTreatments.map { "\($0.category.rawValue.capitalized): \($0.name)" })
            }
            
            // Ensure we have at least 3 routines for display
            while aiRoutines.count < 3 {
                aiRoutines.append(["Sample routine step"])
            }
            
            return aiRoutines
        }
        
        // Fallback to placeholder routines
        return [
            [
                "Cleanser: CeraVe Gentle Cleanser",
                "Serum: The Ordinary Niacinamide", 
                "Moisturizer: Neutrogena Hydro Boost",
                "Sunscreen: La Roche-Posay Anthelios"
            ],
            [
                "Cleanser: Vanicream Gentle Cleanser",
                "Toner: Paula's Choice BHA",
                "Night Cream: CeraVe PM Lotion"
            ],
            [
                "Exfoliating Mask: The Ordinary AHA 30%",
                "Hydrating Mask: Laneige Water Sleeping Mask"
            ]
        ]
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Custom large, centered title with PRO badge for premium users
                    HStack(alignment: .top, spacing: 8) {
                        Spacer()
                        HStack(alignment: .top, spacing: 6) {
                            Text("Dashboard")
                                .font(.largeTitle).fontWeight(.bold)
                                .padding(.top, 8)
                                .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                            
                            // Pro badge positioned right after title
                            if userTierManager.isPremium {
                                WaxStampBadge()
                                    .rotationEffect(.degrees(15)) // Slight exponential growth angle
                                    .offset(x: 4, y: 2)
                            }
                        }
                        Spacer()
                    }
                    // Welcome section with premium styling for pro users
                    WelcomeSection(isDark: isDark, isPremium: userTierManager.isPremium)
                        .padding(.bottom, 8)
                    
                    // Progress overview with premium styling for pro users
                    ProgressOverviewCard(
                        progress: dashboardData.progress,
                        confettiCounter: $confettiCounter,
                        isDark: isDark,
                        isPremium: userTierManager.isPremium,
                        realSkinHealthScore: realSkinHealthScore,
                        realSkinConditions: realSkinConditions,
                        averageConfidence: averageConfidence,
                        analysisDate: skinAnalysisManager.getCachedAnalysisResults()?.analysisDate
                    )
                        .padding(.bottom, 8)
                    
                    // Current routine
                    if !dashboardData.currentRoutine.isEmpty {
                        CurrentRoutineCard(routine: dashboardData.currentRoutine, isDark: isDark)
                            .padding(.bottom, 8)
                    }
                    
                    // Upcoming tasks (AI-powered, including weekly treatment)
                    UpcomingTasksCard(
                        tasks: aiGeneratedTasks,
                        weeklyMaskCompletedAt: $weeklyMaskCompletedAt,
                        weeklyMaskTask: aiGeneratedWeeklyTask,
                        isDark: isDark,
                        canReloadTasks: canReloadTasks,
                        reloadButtonText: reloadButtonText,
                        onReloadTasks: reloadTasksAction,
                        routines: aiGeneratedRoutines,
                        isReloading: skinAnalysisManager.isReloading,
                        lastUpdated: skinAnalysisManager.recommendationsUpdatedAt
                    )
                        .padding(.bottom, 8)
                    
                    // Insights with premium styling for pro users
                    InsightsCard(insights: dashboardData.insights, isDark: isDark, isPremium: userTierManager.isPremium)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .onChange(of: Int(realSkinHealthScore * 100)) { oldValue, newValue in
                    let milestones: [Int] = [75, 80, 85, 90, 100]
                    if let milestone = milestones.first(where: { $0 > lastMilestone && newValue >= $0 }) {
                        confettiCounter += 1
                        lastMilestone = milestone
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .refreshable {
                // Refresh dashboard data
                await refreshDashboard()
            }
        }
        .id(appearanceManager.colorSchemePreference)
        .onAppear {
            print("🔍 DashboardView: Appeared")
            print("🔍 DashboardView: User profile - onboarding_complete = \(authManager.userProfile?.onboarding_complete ?? false)")
            // Load cached AI recommendations once per app launch
            skinAnalysisManager.loadCachedRecommendations()
            updateInsights()
        }
        .onReceive(skinAnalysisManager.$recommendations) { _ in
            updateInsights()
        }
    }
    
    private func refreshDashboard() async {
        // Simulate API call to refresh dashboard data
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        // Update dashboard data here
    }

    // Action to reload tasks (triggers new AI recommendations)
    private func reloadTasksAction() {
        Task {
            await skinAnalysisManager.regenerateRecommendations()
        }
    }
}

struct WelcomeSection: View {
    @EnvironmentObject var authManager: AuthenticationManager
    var isDark: Bool
    var isPremium: Bool = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back! ✨")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
            Text("Ready to take care of your skin today?")
                .font(.subheadline)
                .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            ZStack {
                if isDark {
                    // Unify dark-mode card color with Today's Tasks card
                    NuraColors.cardDark
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Premium light mode styling
                    if isPremium {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.12),
                                Color.yellow.opacity(0.08),
                                Color.purple.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: isPremium)
                    }
                }
            }
        )
        .cornerRadius(12)
        .scaleEffect(isPremium ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isPremium)
    }
}

struct ProgressOverviewCard: View {
    let progress: ProgressMetrics
    @Binding var confettiCounter: Int
    var isDark: Bool
    var isPremium: Bool = false
    let realSkinHealthScore: Double
    let realSkinConditions: [(name: String, areas: [String], severity: String)]
    let averageConfidence: Double
    let analysisDate: Date?

    private func ringColor(for score: Double) -> Color {
        let percent = score * 100
        if percent < 60 {
            return .gray
        } else if percent < 75 {
            return .orange
        } else {
            // Green that gets darker as score approaches 100
            let darkness = (percent - 75) / 25 // 0 to 1
            // Start with .green, blend towards .black
            let base = Color.green
            let darken = Color.black.opacity(darkness * 0.5)
            return base.blend(with: darken, fraction: darkness)
        }
    }
    
    // Helper function for severity colors
    private func severityColor(for severity: String) -> Color {
        switch severity.lowercased() {
        case "excellent", "good", "mild": return .green
        case "monitor", "moderate": return .orange
        case "severe": return .red
        default: return .gray
        }
    }
    
    // Helper function for severity icons (supports both real and sample severities)
    private func severityIconName(for severity: String) -> String {
        switch severity.lowercased() {
        case "excellent": return "arrow.up.circle.fill"
        case "good", "mild": return "checkmark.seal.fill"
        case "monitor", "moderate": return "exclamationmark.circle.fill"
        case "severe": return "exclamationmark.triangle.fill"
        default: return "circle.fill"
        }
    }
    
    // Helper function for confidence colors
    private func confidenceColor(for confidence: Double) -> Color {
        switch confidence {
        case 0.85...1.0: return isDark ? Color.green : Color.green
        case 0.7..<0.85: return .orange
        default: return .red
        }
    }
    
    // Helper function for formatting dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    // Computed properties to break up complex expressions
    private var ctaBackgroundFill: Color {
        isDark ? Color.purple.opacity(0.08) : Color.purple.opacity(0.05)
    }
    
    private var ctaGradientColors: [Color] {
        [
            isDark ? Color.purple.opacity(0.25) : Color.purple.opacity(0.2),
            isDark ? Color.blue.opacity(0.2) : Color.blue.opacity(0.15)
        ]
    }
    
    private var ctaGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: ctaGradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Split subviews to help type-checker
    @ViewBuilder private var headerSection: some View {
        HStack(alignment: .lastTextBaseline, spacing: 8) {
            Text("Skin Health Score")
                .font(.title3)
                .fontWeight(.bold)
                .underline()
                .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                .fixedSize()
            Spacer(minLength: 0)
            Text("Your journey to healthier skin")
                .font(.caption)
                .italic()
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .offset(y: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, -10)
    }

    @ViewBuilder private var scoreBubble: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(isDark ? 0.05 : 0.3))
                .frame(width: 100, height: 100)
            AnimatedRingView(
                progress: realSkinHealthScore,
                ringColor: isDark ? NuraColors.successDark : ringColor(for: realSkinHealthScore),
                ringWidth: isPremium ? 16 : 14,
                label: "\(Int(realSkinHealthScore * 100))%"
            )
            .frame(width: isPremium ? 95 : 90, height: isPremium ? 95 : 90)
            .scaleEffect(isPremium ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.5), value: isPremium)
        }
        .confettiCannon(trigger: $confettiCounter, num: 40, colors: [.green, .blue, .purple])
    }

    @ViewBuilder private var ctaOrSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            if realSkinConditions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isDark ? Color.purple.opacity(0.8) : Color.purple)
                        Text("Ready for Your Analysis?")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                    }
                    Text("Upload photos to unlock personalized insights!")
                        .font(.caption2)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .frame(minWidth: 190, minHeight: 110)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ctaBackgroundFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ctaGradient, lineWidth: 1)
                        )
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Upload photos to get your personalized skin analysis")
                .accessibilityHint("Tap the camera tab to start your skin analysis")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(realSkinConditions.count) conditions detected")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                    if let analysisDate = analysisDate {
                        Text("Analysis Date: \(formatDate(analysisDate))")
                            .font(.caption2)
                            .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.6))
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .frame(minWidth: 190, minHeight: 110)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isDark ? Color.green.opacity(0.05) : Color.green.opacity(0.03))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var realAnalysisNotes: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(realSkinConditions.enumerated()).filter { _, c in c.name.lowercased() != "analysis completed" }, id: \.offset) { index, condition in
                HStack(alignment: .top, spacing: 6) {
                    Text(condition.name)
                        .font(.caption)
                        .fontWeight(index == 0 ? .semibold : .medium)
                        .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: severityIconName(for: condition.severity))
                        .font(.caption)
                        .foregroundColor(severityColor(for: condition.severity))
                    if !condition.areas.isEmpty {
                        Text("Areas: \(condition.areas.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
            HStack(spacing: 6) {
                Text("Analysis Confidence")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(isDark ? Color.blue.opacity(0.7) : Color.blue)
                    .font(.caption)
                Text("\(Int(averageConfidence * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(confidenceColor(for: averageConfidence))
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder private var sampleAnalysisNotes: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Healthy Glow – Excellent
            HStack(spacing: 6) {
                Text("Healthy Glow")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                    .lineLimit(1)
                Image(systemName: severityIconName(for: "excellent"))
                    .font(.caption)
                    .foregroundColor(severityColor(for: "excellent"))
                Text("Areas: Forehead, cheeks, chin")
                    .font(.caption2)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            // Even Tone – Good
            HStack(spacing: 6) {
                Text("Even Tone")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                    .lineLimit(1)
                Image(systemName: severityIconName(for: "good"))
                    .font(.caption)
                    .foregroundColor(severityColor(for: "good"))
                Text("Areas: Face, neck")
                    .font(.caption2)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            // Hydration Needs – Monitor
            HStack(spacing: 6) {
                Text("Hydration Needs")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                    .lineLimit(1)
                Image(systemName: severityIconName(for: "monitor"))
                    .font(.caption)
                    .foregroundColor(severityColor(for: "monitor"))
                Text("Areas: T-zone, around eyes")
                    .font(.caption2)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            // Confidence line
            HStack(spacing: 6) {
                Text("Analysis Confidence")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(isDark ? Color.blue.opacity(0.7) : Color.blue)
                    .font(.caption)
                Text("95%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(NuraColors.success)
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("Analysis Notes:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                Spacer()
                // Inline share button on the same row as the title
                HStack(spacing: 6) {
                    SkinScoreShareButton(skinScore: realSkinHealthScore, isDark: isDark)
                    Text("Share")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.6))
                }
            }
            if !realSkinConditions.isEmpty {
                realAnalysisNotes
            } else {
                sampleAnalysisNotes
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.12), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var backgroundLayer: some View {
        ZStack {
            if isDark {
                NuraColors.cardDark
            } else {
                Color(red: 1.0, green: 0.913, blue: 0.839)
                LinearGradient(
                    gradient: Gradient(colors: [Color.white.opacity(0.08), Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                if isPremium {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.purple.opacity(0.08),
                            Color.yellow.opacity(0.05),
                            Color.purple.opacity(0.03)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isPremium)
                }
                if isPremium {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple.opacity(0.4), Color.yellow.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.0
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.98, green: 0.839, blue: 0.706).opacity(0.2), lineWidth: 1.2)
                }
            }
        }
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 20) {
                // Header with title and subtitle
                headerSection
                
                // 4-Rectangle Layout: Top Row = Score + CTA, Bottom Row = Analysis Notes (spans full width)
                VStack(spacing: 16) {
                    // Top Row: Rectangle 1 (Score) + Rectangle 2 (CTA)
                    HStack(alignment: .top, spacing: 16) {
                        // Rectangle 1: Score Progress View (Top Left)
                        scoreBubble
                        .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Rectangle 2: Ready for Analysis CTA (Top Right)
                        ctaOrSummary
                    }
                    
                    // Bottom Row: Rectangles 3&4 Merged - Analysis Notes (Full Width)
                    notesSection
                }
            }
        }
        .padding()
        .background(
            backgroundLayer
        )
        .cornerRadius(12)
        .shadow(
            color: isPremium ? Color.purple.opacity(0.2) : .black.opacity(0.1),
            radius: isPremium ? 8 : 5,
            x: 0,
            y: isPremium ? 3 : 2
        )
        .scaleEffect(isPremium ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isPremium)
        // Removed old outer share overlay; moved inline with Analysis Notes
    }
}

// Helper extension for color blending
extension Color {
    func blend(with color: Color, fraction: Double) -> Color {
        let ui1 = UIColor(self)
        let ui2 = UIColor(color)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        ui1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        ui2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let r = r1 + (r2 - r1) * CGFloat(fraction)
        let g = g1 + (g2 - g1) * CGFloat(fraction)
        let b = b1 + (b2 - b1) * CGFloat(fraction)
        let a = a1 + (a2 - a1) * CGFloat(fraction)
        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.purple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
        }
    }
}

struct CurrentRoutineCard: View {
    let routine: [SkincareStep]
    var isDark: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Routine")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(routine.prefix(3)) { step in
                HStack {
                    Image(systemName: stepIcon(for: step.category))
                        .foregroundColor(NuraColors.primary)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(step.description)
                            .font(.caption)
                            .foregroundColor(isDark ? Color.white.opacity(0.82) : Color.primary.opacity(0.75))
                    }
                    
                    Spacer()
                    
                    Text(step.frequency.rawValue.replacingOccurrences(of: "_", with: " "))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(NuraColors.primary)
                        .cornerRadius(8)
                }
            }
            
            if routine.count > 3 {
                Button("View Full Routine") {
                    // Navigate to full routine view
                }
                .font(.caption)
                .foregroundColor(NuraColors.primary)
            }
        }
        .padding()
        .background(
            ZStack {
                if isDark {
                    NuraColors.cardDark
                } else {
                    Color(red: 1.0, green: 0.913, blue: 0.839) // #FFE9D6
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.08), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.98, green: 0.839, blue: 0.706).opacity(0.2), lineWidth: 1.2) // #FAD6B4 20%
                }
            }
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func stepIcon(for category: SkincareStep.StepCategory) -> String {
        switch category {
        case .cleanser: return "drop.fill"
        case .toner: return "sparkles"
        case .serum: return "pills.fill"
        case .moisturizer: return "leaf.fill"
        case .sunscreen: return "sun.max.fill"
        case .treatment: return "cross.fill"
        case .mask: return "face.smiling"
        }
    }
}

struct UpcomingTasksCard: View {
    let tasks: [DashboardTask]
    @Binding var weeklyMaskCompletedAt: Date?
    let weeklyMaskTask: DashboardTask
    var isDark: Bool
    var canReloadTasks: Bool = true
    var reloadButtonText: String = "Reload Tasks"
    var onReloadTasks: (() -> Void)? = nil
    var routines: [[String]] = [["Sample routine"]]
    var isReloading: Bool = false
    var lastUpdated: Date? = nil
    @State private var showToast: Bool = false
    private let weekInterval: TimeInterval = 7 * 24 * 60 * 60
    @State private var maskPop: Bool = false
    @State private var taskPopIndex: Int? = nil
    @State private var expandedTaskIndex: Int? = nil
    @State private var checkedStates: [Bool] = [false, false, false] // For demo, up to 3 tasks
    @State private var lastCompletedDates: [Date?] = [nil, nil, nil] // For demo, up to 3 tasks
    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Header (split out to help type-checker)
    @ViewBuilder private var headerRow: some View {
        HStack {
            Text("Today's Tasks")
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            if canReloadTasks, let onReloadTasks = onReloadTasks {
                HStack(spacing: 6) {
                    if isReloading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Button(action: {
                        onReloadTasks()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                            Text("Reload")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(isDark ? Color.purple.opacity(0.8) : Color.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isDark ? Color.purple.opacity(0.1) : Color.purple.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .disabled(isReloading)
                    .accessibilityLabel(reloadButtonText)
                    .accessibilityHint("Generates new AI-powered task recommendations")
                }
            }
        }
    }

    var nextAvailableDateForTask: [Date?] {
        [
            lastCompletedDates[0].flatMap { date in Calendar.current.nextDate(after: date, matching: DateComponents(hour: 5, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents) }, // Morning: next 5am
            lastCompletedDates[1].flatMap { date in Calendar.current.nextDate(after: date, matching: DateComponents(hour: 18, minute: 0), matchingPolicy: .nextTimePreservingSmallerComponents) }, // Evening: next 6pm
            nil
        ]
    }
    var timeRemainingForTask: [TimeInterval?] {
        nextAvailableDateForTask.enumerated().map { idx, date in
            date.map { max($0.timeIntervalSince(now), 0) }
        }
    }
    var canCompleteTask: [Bool] {
        lastCompletedDates.enumerated().map { idx, lastDate in
            guard let _ = lastDate, let time = timeRemainingForTask[idx] else { return true }
            return time <= 0
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Header with reload button
            headerRow
            if let lastUpdated = lastUpdated {
                Text("Updated: \(relativeDate(lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            ForEach(Array(tasks.prefix(3).enumerated()), id: \.offset) { idx, task in
                let routineItems = routines.indices.contains(idx) ? routines[idx] : ["Step 1", "Step 2"]
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        Button(action: {
                            if checkedStates[idx] {
                                checkedStates[idx] = false
                                lastCompletedDates[idx] = nil
                            } else if canCompleteTask[idx] {
                                checkedStates[idx] = true
                                lastCompletedDates[idx] = now
                                taskPopIndex = idx
                                let generator = UINotificationFeedbackGenerator()
                                generator.notificationOccurred(.success)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    taskPopIndex = nil
                                }
                            }
                        }) {
                            Image(systemName: checkedStates[idx] ? "checkmark.circle.fill" : "circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(checkedStates[idx] ? Color(red: 0.11, green: 0.60, blue: 0.36) : (isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75)))
                                .frame(width: 20, height: 20)
                                .scaleEffect(taskPopIndex == idx ? 1.2 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: taskPopIndex == idx)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .strikethrough(checkedStates[idx])
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(bulletItems(from: task.description), id: \.self) { item in
                                    Text("• \(item)")
                                        .font(.caption2)
                                        .foregroundColor(isDark ? Color.white.opacity(0.82) : Color.primary.opacity(0.75))
                                }
                            }
                            if checkedStates[idx], let time = timeRemainingForTask[idx], !canCompleteTask[idx] {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .foregroundColor(.blue)
                                    Text("Next available in \(formatTime(time))")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        Spacer()
                        Text("\(routineItems.count) things")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.0)) // Deep orange
                    }
                    
                }
            }
            // Weekly Mask row at the end
            Divider()
                .background(Color.black)
            let weeklyRoutine = routines.indices.contains(2) ? routines[2] : ["Step 1", "Step 2"]
            VStack(alignment: .leading, spacing: 0) {
                // Local computed properties for weekly mask
                let nextAvailableDate: Date? = weeklyMaskCompletedAt.flatMap { date in date.addingTimeInterval(weekInterval) }
                let timeRemaining: TimeInterval? = nextAvailableDate.map { max($0.timeIntervalSince(now), 0) }
                let canComplete: Bool = timeRemaining == nil || (timeRemaining ?? 0) <= 0
                HStack(alignment: .top) {
                    Button(action: {
                        if weeklyMaskCompletedAt != nil {
                            // Uncheck at any time
                            weeklyMaskCompletedAt = nil
                        } else if canComplete {
                            weeklyMaskCompletedAt = Date()
                            maskPop = true
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                maskPop = false
                            }
                        }
                    }) {
                        ZStack {
                            if (weeklyMaskCompletedAt != nil && !canComplete) {
                                LinearGradient(
                                    gradient: Gradient(colors: [.orange, .yellow, .pink, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .mask(
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                )
                            } else {
                                Image(systemName: "circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
                            }
                        }
                        .frame(width: 20, height: 20)
                        .scaleEffect(maskPop ? 1.2 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: maskPop)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(weeklyMaskTask.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .strikethrough(weeklyMaskCompletedAt != nil && !canComplete)
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(bulletItems(from: weeklyMaskTask.description), id: \.self) { item in
                                Text("• \(item)")
                                    .font(.caption2)
                                    .foregroundColor(isDark ? Color.white.opacity(0.82) : Color.primary.opacity(0.75))
                            }
                        }
                        if !canComplete, let time = timeRemaining {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .foregroundColor(.blue)
                                Text("Next available in \(formatTime(time))")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    Spacer()
                    Text("\(weeklyRoutine.count) things")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.85, green: 0.4, blue: 0.0)) // Deep orange
                }
                
            }
        }
        .onReceive(timer) { input in
            now = input
        }
        .onChange(of: isReloading) { oldValue, newValue in
            if oldValue == true && newValue == false {
                withAnimation { showToast = true }
            }
        }
        .padding()
        .background(
            ZStack {
                if isDark {
                    NuraColors.cardDark
                } else {
                    Color(red: 1.0, green: 0.882, blue: 0.765) // #FFE1C3
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.08), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.98, green: 0.82, blue: 0.67).opacity(0.2), lineWidth: 1.2) // #FAD1A9 20%
                }
            }
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        // Mini toast
        .overlay(alignment: .top) {
            if showToast {
                HStack { Spacer() 
                    Text("Routines refreshed")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(.regularMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    Spacer() }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation { showToast = false } } }
                .padding(.top, 6)
            }
        }
    }
    private func priorityIcon(for priority: DashboardTask.Priority) -> String {
        switch priority {
        case .low: return "1.circle"
        case .medium: return "2.circle"
        case .high: return "3.circle"
        }
    }
    private func priorityColor(for priority: DashboardTask.Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    private func formatTime(_ interval: TimeInterval) -> String {
        let days = Int(interval) / 86400
        let hours = (Int(interval) % 86400) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
    private func bulletItems(from description: String) -> [String] {
        let separators = CharacterSet(charactersIn: ".,;\n")
        return description
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

struct InsightsCard: View {
    let insights: [Insight]
    var isDark: Bool
    var isPremium: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(insights.prefix(3)) { insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: insightIcon(for: insight.type))
                        .foregroundColor(insightColor(for: insight.type))
                        .font(.caption)
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(insight.description)
                            .font(.caption)
                            .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            ZStack {
                if isDark {
                    NuraColors.cardDark
                } else {
                    Color(red: 1.0, green: 0.847, blue: 0.729) // #FFD8BA
                    LinearGradient(
                        gradient: Gradient(colors: [Color.white.opacity(0.08), Color.clear]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // Premium light mode styling
                    if isPremium {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.06),
                                Color.yellow.opacity(0.04),
                                Color.purple.opacity(0.02)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true), value: isPremium)
                    }
                    
                    // Premium border
                    if isPremium {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.yellow.opacity(0.2)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.8
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.98, green: 0.78, blue: 0.60).opacity(0.2), lineWidth: 1.2)
                    }
                }
            }
        )
        .cornerRadius(12)
        .shadow(
            color: isPremium ? Color.purple.opacity(0.15) : .black.opacity(0.1),
            radius: isPremium ? 6 : 5,
            x: 0,
            y: isPremium ? 2.5 : 2
        )
        .scaleEffect(isPremium ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isPremium)
    }
    
    private func insightIcon(for type: Insight.InsightType) -> String {
        switch type {
        case .improvement: return "arrow.up.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .tip: return "lightbulb.fill"
        case .achievement: return "star.fill"
        }
    }
    
    private func insightColor(for type: Insight.InsightType) -> Color {
        switch type {
        case .improvement: return .green
        case .warning: return .orange
        case .tip: return .yellow
        case .achievement: return .purple
        }
    }
}

// MARK: - Skin Score Share Button

struct SkinScoreShareButton: View {
    let skinScore: Double
    let isDark: Bool
    @StateObject private var shareManager = ShareManager()
    @State private var showShareOptions = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showShareOptions = true
            }
        }) {
            Image(systemName: "arrowshape.turn.up.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.gray.opacity(0.7))
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(isDark ? NuraColors.cardDark : Color(red: 1.0, green: 0.913, blue: 0.839))
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
        .sheet(isPresented: $showShareOptions) {
            ShareOptionsView(
                analysis: createMockAnalysis(),
                skinScore: skinScore * 10, // Convert to 0-10 scale
                shareManager: shareManager,
                isPresented: $showShareOptions
            )
        }
    }
    
    private func createMockAnalysis() -> SkinAnalysisResult {
        // Create a mock analysis for sharing purposes
        let mockConditions = [
            SkinCondition(
                id: UUID(),
                name: "healthy skin",
                severity: .mild,
                confidence: 0.95,
                description: "Your skin looks great!",
                affectedAreas: ["face"]
            )
        ]
        
        return SkinAnalysisResult(
            conditions: mockConditions,
            confidence: 0.95,
            analysisDate: Date(),
            recommendations: ["Maintain your current skincare routine"],
            skinHealthScore: 87,
            analysisVersion: "1.0",
            routineGenerationTimestamp: nil,
            analysisProvider: .mock,
            imageCount: 1
        )
    }
}

// MARK: - Wax Stamp Badge (Reusable Component)

struct WaxStampBadge: View {
    var text: String = "PRO"
    var size: CGFloat = 38
    var shouldAnimate: Bool = true
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Wax stamp base with realistic red wax appearance
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.8, green: 0.2, blue: 0.2), // Bright red center
                            Color(red: 0.6, green: 0.1, blue: 0.1), // Darker red middle
                            Color(red: 0.4, green: 0.05, blue: 0.05) // Deep red edge
                        ]),
                        center: .topLeading,
                        startRadius: 5,
                        endRadius: size * 0.7
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    // Wax texture highlight
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.4),
                                    Color.clear,
                                    Color.black.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .padding(2)
                )
                .overlay(
                    // Irregular wax edge effect
                    Circle()
                        .stroke(
                            Color(red: 0.3, green: 0.05, blue: 0.05).opacity(0.8),
                            lineWidth: 1.2
                        )
                )
                // Wax stamp shadows for authentic depth
                .shadow(color: Color.black.opacity(0.5), radius: 8, x: 3, y: 5)
                .shadow(color: Color.red.opacity(0.3), radius: 4, x: 1, y: 2)
                .shadow(color: Color.black.opacity(0.2), radius: 15, x: 5, y: 10)
                .scaleEffect(shouldAnimate && isAnimating ? 1.03 : 1.0)
                .animation(
                    shouldAnimate ? .easeInOut(duration: 3).repeatForever(autoreverses: true) : .linear(duration: 0),
                    value: isAnimating
                )
            
            // Embossed text effect like pressed wax
            Text(text)
                .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
                .shadow(color: .red.opacity(0.5), radius: 2, x: 1, y: 1)
                .overlay(
                    // Embossed highlight
                    Text(text)
                        .font(.system(size: size * 0.28, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.2))
                        .offset(x: -0.5, y: -0.5)
                )
        }
        .onAppear {
            if shouldAnimate {
                isAnimating = true
            }
        }
    }
}

// MARK: - Legacy Pro Badge View (Deprecated - Use WaxStampBadge instead)

struct ProBadgeView: View {
    var body: some View {
        WaxStampBadge()
    }
}

#Preview {
    DashboardView()
        .environmentObject(SkinAnalysisManager(userTierManager: UserTierManager(authManager: AuthenticationManager.shared)))
        .environmentObject(ShareManager())
        .environmentObject(UserTierManager(authManager: AuthenticationManager.shared))
} 