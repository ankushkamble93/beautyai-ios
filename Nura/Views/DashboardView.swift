import SwiftUI
import ConfettiSwiftUI
import Combine

// Shared style helpers to avoid repeating complex ternaries and reduce type-checking load
private enum DashboardStyle {
    static func primaryText(isDark: Bool) -> Color {
        isDark ? NuraColors.textPrimaryDark : .primary
    }

    static func secondaryText(isDark: Bool) -> Color {
        isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75)
    }

    static func secondaryTextLight(isDark: Bool) -> Color {
        isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7)
    }

    static func secondaryTextLighter(isDark: Bool) -> Color {
        isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.6)
    }

    static func secondaryTextMedium(isDark: Bool) -> Color {
        isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.8)
    }

    static func whiteText(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.82) : Color.primary.opacity(0.75)
    }

    static func backgroundOrange(isDark: Bool) -> Color {
        isDark ? Color.orange.opacity(0.18) : Color.orange.opacity(0.12)
    }

    static func whiteCircle(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.06) : Color.white.opacity(0.25)
    }

    static func scoreBubble(isDark: Bool) -> Color {
        isDark ? Color.white.opacity(0.05) : Color.white.opacity(0.3)
    }

    static func greenBackground(isDark: Bool) -> Color {
        isDark ? Color.green.opacity(0.05) : Color.green.opacity(0.03)
    }

    static func greenStroke() -> Color {
        Color.green.opacity(0.2)
    }
}

struct DashboardView: View {
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var shareManager: ShareManager
    @EnvironmentObject var userTierManager: UserTierManager
    @EnvironmentObject var routineOverrideManager: RoutineOverrideManager
    @ObservedObject private var streakManager = StreakManager.shared
    
    @State private var navigateToAnalysis: Bool = false
    @State private var showAnalyzeBanner: Bool = false
    @State private var showWelcomeCard: Bool = true
    @State private var welcomeCardOffset: CGFloat = 0
    @State private var welcomeCardOpacity: Double = 1
    
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
    @State private var showRoutineManager: Bool = false
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
        return 0.85 // Default confidence
    }
    
    // MARK: - Replace in-body color vars with centralized helpers (see DashboardStyle)

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
        let recsWithOverrides: SkincareRecommendations = routineOverrideManager.applyOverrides(to: recommendations)
        if !recsWithOverrides.morningRoutine.isEmpty {
            let morningSteps = recsWithOverrides.morningRoutine.map { $0.name }.joined(separator: ", ")
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
        if !recsWithOverrides.eveningRoutine.isEmpty {
            let eveningSteps = recsWithOverrides.eveningRoutine.map { $0.name }.joined(separator: ", ")
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Custom large, centered title with PRO badge for premium users
                    HStack(alignment: .top, spacing: 8) {
                        Spacer()
                        HStack(alignment: .top, spacing: 6) {
                            Text("Dashboard")
                                .font(.largeTitle).fontWeight(.bold)
                                .padding(.top, 8)
                                .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
                            
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
                    if showWelcomeCard {
                        WelcomeSection(
                            isDark: isDark, 
                            isPremium: userTierManager.isPremium,
                            onDismiss: {
                                dismissWelcomeCard()
                            }
                        )
                        .padding(.bottom, 8)
                        .offset(y: welcomeCardOffset)
                        .opacity(welcomeCardOpacity)
                        .scaleEffect(welcomeCardOpacity == 1 ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.8), value: welcomeCardOffset)
                        .animation(.easeInOut(duration: 0.6), value: welcomeCardOpacity)
                        .animation(.easeOut(duration: 0.4), value: welcomeCardOpacity == 1)
                    }

                    // Streak Card
                    StreakCard(
                        currentStreak: streakManager.currentStreak,
                        longestStreak: streakManager.longestStreak,
                        nextMilestoneDays: streakManager.nextMilestone(),
                        daysToNextMilestone: streakManager.daysToNextMilestone(),
                        pendingReward: streakManager.pendingReward,
                        onClaimReward: {
                            streakManager.redeemFreeProMonth(using: userTierManager)
                        },
                        isDark: isDark,
                        showAnalyzeCTA: {
                            if let res = skinAnalysisManager.getCachedAnalysisResults() {
                                return !Calendar.current.isDate(res.analysisDate, inSameDayAs: Date())
                            }
                            return true
                        }(),
                        onAnalyze: {
                            navigateToAnalysis = true
                        }
                    )
                    .onAppear {
                        if let res = skinAnalysisManager.getCachedAnalysisResults() {
                            showAnalyzeBanner = !Calendar.current.isDate(res.analysisDate, inSameDayAs: Date())
                        } else { showAnalyzeBanner = true }
                    }
                    .padding(.bottom, 4)
                    // Hidden navigation trigger to analysis - using modern NavigationLink
                    NavigationLink(value: "analysis") {
                        EmptyView()
                    }
                    .navigationDestination(for: String.self) { destination in
                        if destination == "analysis" {
                            SkinAnalysisView()
                                .environmentObject(skinAnalysisManager)
                                .environmentObject(appearanceManager)
                                .environmentObject(userTierManager)
                        } else if destination == "routine" {
                            RoutineView()
                                .environmentObject(authManager)
                                .environmentObject(appearanceManager)
                                .environmentObject(userTierManager)
                                .environmentObject(routineOverrideManager)
                        }
                    }
                    
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
                        onManageRoutines: { showRoutineManager = true },
                        routines: aiGeneratedRoutines,
                        isReloading: skinAnalysisManager.isReloading,
                        reloadElapsedTime: skinAnalysisManager.reloadElapsedTime,
                        reloadCountdownTime: skinAnalysisManager.reloadCountdownTime,
                        lastUpdated: skinAnalysisManager.recommendationsUpdatedAt
                    )
                        .padding(.bottom, 8)
                        .sheet(isPresented: $showRoutineManager) {
                            RoutineView()
                                .environmentObject(authManager)
                                .environmentObject(appearanceManager)
                                .environmentObject(userTierManager)
                                .environmentObject(routineOverrideManager)
                        }
                    
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
            
            // Welcome card auto-dismiss logic
            if showWelcomeCard {
                // Start the dismissal timer
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        welcomeCardOffset = -200 // Swipe up animation
                        welcomeCardOpacity = 0
                    }
                    
                    // Hide the card completely after animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showWelcomeCard = false
                    }
                }
            }
        }
        .onReceive(skinAnalysisManager.$recommendations) { _ in
            updateInsights()
        }
        .onChange(of: streakManager.pendingReward) { oldValue, newValue in
            guard oldValue != newValue, let reward = newValue else { return }
            if case .celebration = reward { confettiCounter += 1 }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Reset welcome card when app becomes active
            resetWelcomeCard()
        }
                       .onAppear {
                   // Dashboard loaded
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
    
    // Reset welcome card state when app becomes active
    private func resetWelcomeCard() {
        showWelcomeCard = true
        welcomeCardOffset = 0
        welcomeCardOpacity = 1
    }
    
    // Dismiss welcome card with animation
    private func dismissWelcomeCard() {
        withAnimation(.easeInOut(duration: 0.8)) {
            welcomeCardOffset = -200 // Swipe up animation
            welcomeCardOpacity = 0
        }
        
        // Hide the card completely after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showWelcomeCard = false
        }
    }
}

// MARK: - Body sections extracted for compiler performance
private extension StreakCard {
    var streakHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                Text("Daily Streak")
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            Button(action: {
                showStreakInfo = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    showStreakInfo = false
                }
            }) {
                Image(systemName: "info.circle")
                    .font(.subheadline)
                    .foregroundColor(.orange.opacity(0.8))
            }
            Spacer()
            Text(subtitleText)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(DashboardStyle.secondaryTextMedium(isDark: isDark))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .multilineTextAlignment(.trailing)
        }
        .padding(.bottom, 12)
    }

    var streakMiddleRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "target")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    Text("Next")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Text("\(displayedNext)d")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .padding(.trailing, 6)

            StreakAnimatedTrackerView(
                isDark: isDark,
                startBreathing: startBreathing,
                ringRotationDegrees: ringRotationDegrees,
                sparkleOpacity: sparkleOpacity,
                progressToNext: progressToNext,
                currentStreak: currentStreak
            )
            .frame(maxWidth: .infinity)
            .padding(.top, showStreakInfo ? 10 : -10)

            VStack(alignment: .center, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Best")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                    Image(systemName: "trophy.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                Text("\(displayedBest)d")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 6)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder var analyzeOrProgressRow: some View {
        if showAnalyzeCTA {
            HStack(spacing: 8) {
                Image(systemName: "camera.circle.fill")
                    .foregroundColor(.purple)
                Text("Keep your streak alive — your skin deserves daily care.")
                    .font(.caption)
                    .foregroundColor(DashboardStyle.secondaryTextMedium(isDark: isDark))
                Spacer()
                if let onAnalyze = onAnalyze {
                    Button(action: {
                        NotificationCenter.default.post(name: .nuraSwitchTab, object: 1)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onAnalyze()
                    }) {
                        Text("Analyze")
                            .font(.caption2).fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.purple)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.purple.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.top, 16)
        } else if let daysLeft = daysToNextMilestone, daysLeft > 0, let next = nextMilestoneDays {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.purple)
                    Text("\(daysLeft) to \(next)d • \(Int(progressToNext * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                    Spacer()
                }
                HStack(spacing: 8) {
                    ProgressView(value: progressToNext)
                        .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                        .scaleEffect(y: 1.5)
                    Text("\(Int(progressToNext * 100))%")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                        .frame(minWidth: 30, alignment: .trailing)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.top, 16)
        }
    }

    @ViewBuilder var rewardBannerRow: some View {
        if let reward = pendingReward {
            VStack(alignment: .leading, spacing: 8) {
                switch reward {
                case .celebration(let days):
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.yellow)
                        Text("Milestone reached: \(days) days! 🎉")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                case .freeProMonth:
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: "gift.fill").foregroundColor(.pink)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reward unlocked")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Claim 1 free month of Pro")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button(action: onClaimReward) {
                            Text("Claim")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.pink)
                                .cornerRadius(8)
                        }
                    }
                    .padding(10)
                    .background((isDark ? Color.pink.opacity(0.15) : Color.pink.opacity(0.08)))
                    .cornerRadius(10)
                }
            }
        }
    }
}

// MARK: - Extracted subview for the animated streak tracker
private struct StreakAnimatedTrackerView: View {
    let isDark: Bool
    let startBreathing: Bool
    let ringRotationDegrees: Double
    let sparkleOpacity: Double
    let progressToNext: Double
    let currentStreak: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(DashboardStyle.backgroundOrange(isDark: isDark))
                .frame(width: 92, height: 92)
                .blur(radius: 0.5)
                .scaleEffect(startBreathing ? 1.03 : 0.97)
                .animation(.easeInOut(duration: 1.2).repeatCount(3, autoreverses: true), value: startBreathing)

            let innerShadowGradient = LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.12), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )

            let maskGradient = LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(DashboardStyle.whiteCircle(isDark: isDark))
                .frame(width: 82, height: 82)
                .overlay(
                    Circle()
                        .stroke(innerShadowGradient, lineWidth: 2)
                        .blur(radius: 0.6)
                        .mask(Circle().fill(maskGradient))
                )

            let ringGradient = AngularGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.00, green: 0.72, blue: 0.42),
                    Color(red: 1.00, green: 0.53, blue: 0.36),
                    Color(red: 1.00, green: 0.72, blue: 0.42)
                ]),
                center: .center
            )

            Circle()
                .stroke(ringGradient, lineWidth: 4)
                .frame(width: 78, height: 78)
                .rotationEffect(.degrees(ringRotationDegrees))
                .animation(.linear(duration: 1.8), value: ringRotationDegrees)

            let dotCount = 4
            ForEach(0..<dotCount, id: \.self) { idx in
                let angle = Double(idx) / Double(dotCount) * 360.0
                let complete = (Double(idx + 1) / Double(dotCount)) <= progressToNext
                Circle()
                    .fill(complete ? Color.orange : Color.orange.opacity(0.25))
                    .frame(width: 5, height: 5)
                    .offset(y: -46)
                    .rotationEffect(.degrees(angle))
            }

            Text("\(currentStreak)d")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
                .shadow(color: Color.orange.opacity(0.35), radius: 2, x: 0, y: 1)

            Image(systemName: "flame.fill")
                .font(.system(size: 11))
                .foregroundColor(.orange)
                .offset(y: -44)
                .rotationEffect(.degrees(ringRotationDegrees))
                .animation(.linear(duration: 1.8), value: ringRotationDegrees)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 9))
                        .foregroundColor(.yellow)
                        .opacity(sparkleOpacity)
                        .offset(x: 10, y: -6)
                )
        }
    }
}

struct WelcomeSection: View {
    @EnvironmentObject var authManager: AuthenticationManager
    var isDark: Bool
    var isPremium: Bool = false
    var onDismiss: (() -> Void)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome back! ✨")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
                    Text("Ready to take care of your skin today?")
                        .font(.subheadline)
                        .foregroundColor(DashboardStyle.secondaryText(isDark: isDark))

                }
                
                Spacer()
                
                // Dismiss button
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            ZStack {
                if isDark {
                    // Unify dark-mode card color with Today's Tasks card
                    NuraColors.cardDark
                } else {
                    // Extract gradient colors to reduce complexity
                    let baseGradientColors = [Color.purple.opacity(0.1), Color.pink.opacity(0.1)]
                    
                    LinearGradient(
                        gradient: Gradient(colors: baseGradientColors),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Premium light mode styling
                    if isPremium {
                        let premiumGradientColors = [
                            Color.purple.opacity(0.12),
                            Color.yellow.opacity(0.08),
                            Color.purple.opacity(0.05)
                        ]
                        
                        LinearGradient(
                            gradient: Gradient(colors: premiumGradientColors),
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
            let darkenOpacity = darkness * 0.5
            let darken = Color.black.opacity(darkenOpacity)
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
                .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
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
                .fill(DashboardStyle.scoreBubble(isDark: isDark))
                .frame(width: 100, height: 100)
            // Extract ring color to reduce complexity
            let currentRingColor = isDark ? NuraColors.successDark : ringColor(for: realSkinHealthScore)
            
            AnimatedRingView(
                progress: realSkinHealthScore,
                ringColor: currentRingColor,
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
                        // Extract camera icon color to reduce complexity
                        let cameraIconColor = isDark ? Color.purple.opacity(0.8) : Color.purple
                        
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(cameraIconColor)
                        Text("Ready for Your Analysis?")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
                    }
                    Text("Upload photos to unlock personalized insights!")
                        .font(.caption2)
                        .foregroundColor(DashboardStyle.secondaryTextLight(isDark: isDark))
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
                        .foregroundColor(DashboardStyle.secondaryTextLight(isDark: isDark))
                    if let analysisDate = analysisDate {
                        Text("Analysis Date: \(formatDate(analysisDate))")
                            .font(.caption2)
                            .foregroundColor(DashboardStyle.secondaryTextLighter(isDark: isDark))
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .frame(minWidth: 190, minHeight: 110)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(DashboardStyle.greenBackground(isDark: isDark))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DashboardStyle.greenStroke(), lineWidth: 1)
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
                        .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: severityIconName(for: condition.severity))
                        .font(.caption)
                        .foregroundColor(severityColor(for: condition.severity))
                    if !condition.areas.isEmpty {
                        Text("Areas: \(condition.areas.joined(separator: ", "))")
                            .font(.caption2)
                            .foregroundColor(DashboardStyle.secondaryTextLight(isDark: isDark))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
            HStack(spacing: 6) {
                Text("Analysis Confidence")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
                // Extract chart icon color to reduce complexity
                let chartIconColor = isDark ? Color.blue.opacity(0.7) : Color.blue
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(chartIconColor)
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
                    .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
                    .lineLimit(1)
                Image(systemName: severityIconName(for: "excellent"))
                    .font(.caption)
                    .foregroundColor(severityColor(for: "excellent"))
                Text("Areas: Forehead, cheeks, chin")
                    .font(.caption2)
                    .foregroundColor(DashboardStyle.secondaryTextLight(isDark: isDark))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            // Even Tone – Good
            HStack(spacing: 6) {
                Text("Even Tone")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
                    .lineLimit(1)
                Image(systemName: severityIconName(for: "good"))
                    .font(.caption)
                    .foregroundColor(severityColor(for: "good"))
                Text("Areas: Face, neck")
                    .font(.caption2)
                    .foregroundColor(DashboardStyle.secondaryTextLight(isDark: isDark))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            // Hydration Needs – Monitor
            HStack(spacing: 6) {
                Text("Hydration Needs")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
                    .lineLimit(1)
                Image(systemName: severityIconName(for: "monitor"))
                    .font(.caption)
                    .foregroundColor(severityColor(for: "monitor"))
                Text("Areas: T-zone, around eyes")
                    .font(.caption2)
                    .foregroundColor(DashboardStyle.secondaryTextLight(isDark: isDark))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            // Confidence line
            HStack(spacing: 6) {
                Text("Analysis Confidence")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
                // Extract chart icon color to reduce complexity
                let chartIconColor = isDark ? Color.blue.opacity(0.7) : Color.blue
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(chartIconColor)
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
                    .foregroundColor(DashboardStyle.primaryText(isDark: isDark))
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
            VStack(alignment: .leading, spacing: 16) {
                // Header with title and subtitle
                headerSection
                
                // 4-Rectangle Layout: Top Row = Score + CTA, Bottom Row = Analysis Notes (spans full width)
                VStack(spacing: 12) {
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
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
                            .foregroundColor(DashboardStyle.whiteText(isDark: isDark))
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
    var onManageRoutines: (() -> Void)? = nil
    var routines: [[String]] = [["Sample routine"]]
    var isReloading: Bool = false
    var reloadElapsedTime: TimeInterval = 0
    var reloadCountdownTime: TimeInterval = 0
    var lastUpdated: Date? = nil
    @State private var showToast: Bool = false
    private let weekInterval: TimeInterval = 7 * 24 * 60 * 60
    @State private var maskPop: Bool = false
    
    // Simple timer for UI updates
    @State private var timerTick = 0
    private let uiTimer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    

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
                HStack(spacing: 4) {
                    Button(action: {
                        onReloadTasks()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                                .rotationEffect(.degrees(isReloading ? Double(timerTick) * 36.0 : 0))
                            Text(isReloading ? "Reloading" : "Reload")
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        // Extract purple colors to reduce complexity
                        .foregroundColor(isDark ? Color.purple.opacity(0.8) : Color.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        // Extract purple background colors to reduce complexity
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isDark ? Color.purple.opacity(0.1) : Color.purple.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .frame(width: 86) // slightly tighter width
                    }
                    .disabled(isReloading)
                    .accessibilityLabel(reloadButtonText)
                    .accessibilityHint("Generates new AI-powered task recommendations")
                }
            }
            if let onManage = onManageRoutines {
                Button(action: { onManage() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.caption)
                        Text("Manage")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(isDark ? Color.blue.opacity(0.85) : .blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isDark ? Color.blue.opacity(0.12) : Color.blue.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.blue.opacity(0.28), lineWidth: 1)
                            )
                    )
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
            if hasCustomizations {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill").foregroundColor(.blue)
                    Text("Your changes are preserved when reloading recommendations.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
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
                                .foregroundColor(checkedStates[idx] ? Color(red: 0.11, green: 0.60, blue: 0.36) : DashboardStyle.secondaryText(isDark: isDark))
                                .frame(width: 20, height: 20)
                                .scaleEffect(taskPopIndex == idx ? 1.2 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.5), value: taskPopIndex == idx)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .strikethrough(checkedStates[idx])
                            if isCustomized(index: idx) {
                                Text("Customized")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .cornerRadius(6)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(bulletItems(from: task.description), id: \.self) { item in
                                    Text("• \(item)")
                                        .font(.caption2)
                                        .foregroundColor(DashboardStyle.whiteText(isDark: isDark))
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
                                    .foregroundColor(DashboardStyle.secondaryText(isDark: isDark))
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
                                    .foregroundColor(DashboardStyle.whiteText(isDark: isDark))
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
        .onReceive(uiTimer) { _ in
            // Update UI every 0.1 seconds when reloading
            if isReloading { timerTick = (timerTick + 1) % 30 }
        }
        .onChange(of: isReloading) { oldValue, newValue in
            // Reset timer when reloading starts
            if newValue == true {
                timerTick = 0
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
    // MARK: - Customization helpers
    private var hasCustomizations: Bool {
        // Heuristic: when any routine item contains a well-known brand keyword, assume user override present
        let allItems = routines.flatMap { $0 }.joined(separator: " ").lowercased()
        let brands = ["la roche", "cerave", "supergoop", "neutrogena", "tatcha", "the ordinary"]
        return brands.contains { allItems.contains($0) }
    }
    private func isCustomized(index: Int) -> Bool {
        guard routines.indices.contains(index) else { return false }
        let joined = routines[index].joined(separator: " ").lowercased()
        let brands = ["la roche", "cerave", "supergoop", "neutrogena", "tatcha", "the ordinary"]
        return brands.contains { joined.contains($0) }
    }
    private func cyclingEllipsis(base: String) -> String {
        let phase = (timerTick / 10) % 4 // 0..3
        let dots = String(repeating: ".", count: phase)
        return base + dots
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
    
    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let seconds = Int(timeInterval)
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 100)
        
        if seconds < 60 {
            return String(format: "%d.%02ds", seconds, milliseconds)
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return String(format: "%dm %02ds", minutes, remainingSeconds)
        }
    }
    
    private func formatCountdownTime(_ timeInterval: TimeInterval) -> String {
        let seconds = Int(timeInterval)
        let tenths = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 10)
        
        if seconds < 60 {
            return String(format: "%d.%ds", seconds, tenths)
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return String(format: "%dm %ds", minutes, remainingSeconds)
        }
    }
}

struct InsightsCard: View {
    let insights: [Insight]
    var isDark: Bool
    var isPremium: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.bottom, 2)
            
            ForEach(Array(insights.prefix(3).enumerated()), id: \.offset) { index, insight in
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: insightIcon(for: insight.type))
                        .foregroundColor(insightColor(for: insight.type))
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 22, height: 22)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(insight.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(insight.description)
                            .font(.caption)
                            .foregroundColor(DashboardStyle.secondaryText(isDark: isDark))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                }
                .padding(.vertical, 6)
                if index < min(2, insights.count - 1) {
                    Divider()
                        .background(Color.black)
                        .padding(.vertical, 6)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
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

// MARK: - Streak Card

struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let nextMilestoneDays: Int?
    let daysToNextMilestone: Int?
    let pendingReward: StreakManager.StreakReward?
    let onClaimReward: () -> Void
    var isDark: Bool
    var showAnalyzeCTA: Bool = false
    var onAnalyze: (() -> Void)? = nil

    @State private var ringRotationDegrees: Double = 0
    @State private var pulse: Bool = false
    @State private var startBreathing: Bool = false
    @State private var sparkleOpacity: Double = 0
    @State private var showCardGlow: Bool = false
    @State private var animatedNextProgress: Double = 0
    @State private var animatedBestProgress: Double = 0
    @State private var showStreakInfo: Bool = false
    @State private var showDismissOverlay: Bool = false

    private var progressToNext: Double {
        guard let next = nextMilestoneDays, next > 0 else { return 1.0 }
        let value = Double(currentStreak) / Double(next)
        return max(0.0, min(1.0, value))
    }

    private var subtitleText: String {
        if currentStreak <= 0 { return "Start your streak today!" }
        if let left = daysToNextMilestone, left > 0 {
            if left <= 2 { return "Day \(currentStreak) • Almost there!" }
            return "Day \(currentStreak) • \(left) more to go!"
        }
        return "Day \(currentStreak) • Building momentum!"
    }

    private var displayedNext: Int {
        let target = max(0, nextMilestoneDays ?? 0)
        return min(target, Int(round(animatedNextProgress * Double(target))))
    }

    private var displayedBest: Int {
        let target = max(0, longestStreak)
        return min(target, Int(round(animatedBestProgress * Double(target))))
    }

    private var cardBackground: some View {
        Group {
            if isDark {
                NuraColors.cardDark
            } else {
                // Extract gradient colors to reduce complexity
                let gradientStartColor = Color(red: 1.0, green: 0.93, blue: 0.86)
                let gradientEndColor = Color.white
                let gradientColors = [gradientStartColor, gradientEndColor]
                
                LinearGradient(
                    gradient: Gradient(colors: gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            streakHeader
            streakMiddleRow
            analyzeOrProgressRow
            rewardBannerRow
        }
        .padding()
        .background(
            ZStack {
                cardBackground
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDark ? Color.orange.opacity(0.25) : Color.orange.opacity(0.25), lineWidth: 1)
            }
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 5, x: 0, y: 2)
        .shadow(color: Color.orange.opacity(showCardGlow ? 0.15 : 0.0), radius: 18, x: 0, y: 6)
        .animation(.easeOut(duration: 1.2), value: showCardGlow)
        .onAppear {
            // One-time premium interactions
            ringRotationDegrees = 360
            startBreathing = true
            withAnimation(.easeOut(duration: 0.9)) { sparkleOpacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.6)) { sparkleOpacity = 0 }
            }
            // Card glow pulse once
            showCardGlow = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { showCardGlow = false }
            // Count-up numbers
            withAnimation(.easeOut(duration: 0.8)) { animatedNextProgress = 1 }
            withAnimation(.easeOut(duration: 0.8).delay(0.05)) { animatedBestProgress = 1 }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Daily streak card. Current: \(currentStreak) days. Longest: \(longestStreak) days.")
        .overlay(
            // Dismiss overlay - covers the entire screen to detect taps
            Group {
                if showStreakInfo {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showStreakInfo = false
                            }
                        }
                }
            }
        )
        .overlay(
            // WhatsApp-style message bubble overlay
            Group {
                if showStreakInfo {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            // Message bubble
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                    Text("Why streaks matter")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                }
                                
                                Text("Daily check-ins build consistent habits which lead to clearer, healthier skin. Hit milestones to unlock rewards.")
                                    .font(.subheadline)
                                    .foregroundColor(.black.opacity(0.85))
                                    .multilineTextAlignment(.leading)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("Tip: Even a quick analysis counts toward your streak.")
                                        .font(.caption)
                                        .foregroundColor(.black.opacity(0.75))
                                }
                            }
                            .padding(16)
                            .background(
                                // Washed blue gradient background from top-left to bottom-right
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.7, green: 0.85, blue: 0.95), // Light washed blue
                                        Color(red: 0.5, green: 0.7, blue: 0.85)  // Darker washed blue
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                // White border
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                            .overlay(
                                // Message tail with matching gradient
                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: 20))
                                    path.addLine(to: CGPoint(x: -8, y: 25))
                                    path.addLine(to: CGPoint(x: 0, y: 30))
                                }
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.7, green: 0.85, blue: 0.95),
                                            Color(red: 0.5, green: 0.7, blue: 0.85)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .offset(x: -8, y: 0)
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                                removal: .scale(scale: 0.9).combined(with: .opacity).combined(with: .move(edge: .bottom))
                            ))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showStreakInfo)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        )
    }
}

#Preview {
    DashboardView()
        .environmentObject(SkinAnalysisManager(userTierManager: UserTierManager(authManager: AuthenticationManager.shared)))
        .environmentObject(ShareManager())
} 