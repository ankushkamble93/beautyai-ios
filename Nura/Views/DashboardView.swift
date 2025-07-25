import SwiftUI
import ConfettiSwiftUI
import Combine

struct DashboardView: View {
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @EnvironmentObject var appearanceManager: AppearanceManager
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
        insights: [
            Insight(
                id: UUID(),
                title: "Great Progress!",
                description: "Your skin health score improved by 15% this week",
                type: .improvement,
                date: Date()
            ),
            Insight(
                id: UUID(),
                title: "Weather Alert",
                description: "High UV index today - don't forget sunscreen!",
                type: .warning,
                date: Date()
            ),
            Insight(
                id: UUID(),
                title: "Hydration Tip",
                description: "Drink more water to improve skin hydration",
                type: .tip,
                date: Date()
            )
        ]
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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Custom large, centered title
                    HStack {
                        Spacer()
                        Text("Dashboard")
                            .font(.largeTitle).fontWeight(.bold)
                            .padding(.top, 8)
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                        Spacer()
                    }
                    // Welcome section
                    WelcomeSection(isDark: isDark)
                    
                    // Progress overview
                    ProgressOverviewCard(
                        progress: dashboardData.progress,
                        confettiCounter: $confettiCounter,
                        isDark: isDark
                    )
                    
                    // Current routine
                    if !dashboardData.currentRoutine.isEmpty {
                        CurrentRoutineCard(routine: dashboardData.currentRoutine, isDark: isDark)
                    }
                    
                    // Recent analysis
                    if let recentAnalysis = skinAnalysisManager.analysisResults {
                        RecentAnalysisCard(analysis: recentAnalysis, isDark: isDark)
                    }
                    
                    // Upcoming tasks (including weekly mask at the end)
                    UpcomingTasksCard(
                        tasks: dashboardData.upcomingTasks,
                        weeklyMaskCompletedAt: $weeklyMaskCompletedAt,
                        weeklyMaskTask: weeklyMaskTask,
                        isDark: isDark
                    )
                    
                    // Insights
                    InsightsCard(insights: dashboardData.insights, isDark: isDark)
                    
                    Spacer()
                }
                .padding()
                .onChange(of: Int(dashboardData.progress.skinHealthScore * 100)) { oldValue, newValue in
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
    }
    
    private func refreshDashboard() async {
        // Simulate API call to refresh dashboard data
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        // Update dashboard data here
    }
}

struct WelcomeSection: View {
    @EnvironmentObject var authManager: AuthenticationManager
    var isDark: Bool
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
                    NuraColors.cardDark
                } else {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
        )
        .cornerRadius(12)
    }
}

struct ProgressOverviewCard: View {
    let progress: ProgressMetrics
    @Binding var confettiCounter: Int
    var isDark: Bool

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

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center) {
                // Left half: Title and Improving Areas
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skin Health Score")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .underline()
                        .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                    if !progress.improvementAreas.isEmpty {
                        Text("Improving Areas:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                        ForEach(progress.improvementAreas, id: \.self) { area in
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(isDark ? NuraColors.successDark : Color(red: 0.11, green: 0.60, blue: 0.36))
                                    .font(.caption)
                                Text(area)
                                    .font(.caption)
                                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : .primary)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // Right half: Centered AnimatedRingView
                VStack {
                    Spacer()
                    AnimatedRingView(
                        progress: Double(progress.skinHealthScore),
                        ringColor: isDark ? NuraColors.successDark : ringColor(for: progress.skinHealthScore),
                        ringWidth: 16,
                        label: "\(Int(progress.skinHealthScore * 100))%"
                    )
                    .frame(width: 100, height: 100)
                    .confettiCannon(trigger: $confettiCounter, num: 40, colors: [.green, .blue, .purple])
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .center)
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

struct RecentAnalysisCard: View {
    let analysis: SkinAnalysisResult
    var isDark: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Recent Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(analysis.conditions.count) conditions detected")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Confidence: \(Int(analysis.confidence * 100))%")
                        .font(.caption)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
                }
                
                Spacer()
                
                Text(formatDate(analysis.analysisDate))
                    .font(.caption)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
            }
            
            if !analysis.conditions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(analysis.conditions.prefix(3)) { condition in
                            VStack(spacing: 4) {
                                Text(condition.name.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Text(condition.severity.rawValue.capitalized)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(severityColor(for: condition.severity).opacity(0.2))
                                    .foregroundColor(severityColor(for: condition.severity))
                                    .cornerRadius(6)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(isDark ? NuraColors.cardDark : NuraColors.card)
                            .cornerRadius(8)
                        }
                    }
                }
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func severityColor(for severity: SkinCondition.Severity) -> Color {
        switch severity {
        case .mild: return .green
        case .moderate: return .orange
        case .severe: return .red
        }
    }
}

struct UpcomingTasksCard: View {
    let tasks: [DashboardTask]
    @Binding var weeklyMaskCompletedAt: Date?
    let weeklyMaskTask: DashboardTask
    var isDark: Bool
    private let weekInterval: TimeInterval = 7 * 24 * 60 * 60
    @State private var maskPop: Bool = false
    @State private var taskPopIndex: Int? = nil
    @State private var expandedTaskIndex: Int? = nil
    @State private var checkedStates: [Bool] = [false, false, false] // For demo, up to 3 tasks
    @State private var lastCompletedDates: [Date?] = [nil, nil, nil] // For demo, up to 3 tasks
    @State private var now: Date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    // Placeholder routines for demo
    let routines: [[String]] = [
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
            Text("Today's Tasks")
                .font(.headline)
                .fontWeight(.semibold)
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
                            Text(task.description)
                                .font(.caption)
                                .foregroundColor(isDark ? Color.white.opacity(0.82) : Color.primary.opacity(0.75))
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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            expandedTaskIndex = (expandedTaskIndex == idx) ? nil : idx
                        }
                    }
                    if expandedTaskIndex == idx {
                        HStack(alignment: .top, spacing: 0) {
                            Spacer().frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(routineItems, id: \.self) { item in
                                    Text("• " + item)
                                        .font(.caption2)
                                        .foregroundColor(isDark ? Color.white.opacity(0.82) : Color(red: 0.13, green: 0.11, blue: 0.09))
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            // No background, just text on card
                            .frame(minWidth: 220, maxWidth: 320, alignment: .leading)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
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
                        Text(weeklyMaskTask.description)
                            .font(.caption)
                            .foregroundColor(isDark ? Color.white.opacity(0.82) : Color.primary.opacity(0.75))
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
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        expandedTaskIndex = (expandedTaskIndex == 9999) ? nil : 9999
                    }
                }
                if expandedTaskIndex == 9999 {
                    HStack(alignment: .top, spacing: 0) {
                        Spacer().frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(weeklyRoutine, id: \.self) { item in
                                Text("• " + item)
                                    .font(.caption2)
                                    .foregroundColor(isDark ? Color.white.opacity(0.82) : Color(red: 0.13, green: 0.11, blue: 0.09))
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        // No background, just text on card
                        .frame(minWidth: 220, maxWidth: 320, alignment: .leading)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
        .onReceive(timer) { input in
            now = input
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
}

struct InsightsCard: View {
    let insights: [Insight]
    var isDark: Bool
    
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
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.98, green: 0.78, blue: 0.60).opacity(0.2), lineWidth: 1.2) // #F9C89B 20%
                }
            }
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
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

#Preview {
    DashboardView()
        .environmentObject(SkinAnalysisManager())
} 