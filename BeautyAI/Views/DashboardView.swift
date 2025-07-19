import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
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
                title: "Morning Routine",
                description: "Complete your morning skincare routine",
                dueDate: Date(),
                priority: .high,
                isCompleted: false
            ),
            DashboardTask(
                title: "Evening Routine",
                description: "Complete your evening skincare routine",
                dueDate: Date().addingTimeInterval(43200), // 12 hours
                priority: .high,
                isCompleted: false
            ),
            DashboardTask(
                title: "Weekly Mask",
                description: "Apply your weekly treatment mask",
                dueDate: Date().addingTimeInterval(86400 * 3), // 3 days
                priority: .medium,
                isCompleted: false
            )
        ],
        insights: [
            Insight(
                title: "Great Progress!",
                description: "Your skin health score improved by 15% this week",
                type: .improvement,
                date: Date()
            ),
            Insight(
                title: "Weather Alert",
                description: "High UV index today - don't forget sunscreen!",
                type: .warning,
                date: Date()
            ),
            Insight(
                title: "Hydration Tip",
                description: "Drink more water to improve skin hydration",
                type: .tip,
                date: Date()
            )
        ]
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome section
                    WelcomeSection()
                    
                    // Progress overview
                    ProgressOverviewCard(progress: dashboardData.progress)
                    
                    // Current routine
                    if !dashboardData.currentRoutine.isEmpty {
                        CurrentRoutineCard(routine: dashboardData.currentRoutine)
                    }
                    
                    // Recent analysis
                    if let recentAnalysis = skinAnalysisManager.analysisResults {
                        RecentAnalysisCard(analysis: recentAnalysis)
                    }
                    
                    // Upcoming tasks
                    UpcomingTasksCard(tasks: dashboardData.upcomingTasks)
                    
                    // Insights
                    InsightsCard(insights: dashboardData.insights)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                // Refresh dashboard data
                await refreshDashboard()
            }
        }
    }
    
    private func refreshDashboard() async {
        // Simulate API call to refresh dashboard data
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        // Update dashboard data here
    }
}

struct WelcomeSection: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ready to take care of your skin today?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

struct ProgressOverviewCard: View {
    let progress: ProgressMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Skin Health Score")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Int(progress.skinHealthScore * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    Text("Overall Health")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                CircularProgressView(progress: progress.skinHealthScore)
                    .frame(width: 60, height: 60)
            }
            
            if !progress.improvementAreas.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Improving Areas:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(progress.improvementAreas, id: \.self) { area in
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text(area)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Routine")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(routine.prefix(3)) { step in
                HStack {
                    Image(systemName: stepIcon(for: step.category))
                        .foregroundColor(.purple)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(step.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(step.frequency.rawValue.replacingOccurrences(of: "_", with: " "))
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
            }
            
            if routine.count > 3 {
                Button("View Full Routine") {
                    // Navigate to full routine view
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
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
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(formatDate(analysis.analysisDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Today's Tasks")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(tasks.prefix(3)) { task in
                HStack {
                    Button(action: {
                        // Toggle task completion
                    }) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .green : .gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .strikethrough(task.isCompleted)
                        
                        Text(task.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(priorityIcon(for: task.priority))
                        .font(.caption)
                        .foregroundColor(priorityColor(for: task.priority))
                }
            }
            
            if tasks.count > 3 {
                Button("View All Tasks") {
                    // Navigate to tasks view
                }
                .font(.caption)
                .foregroundColor(.purple)
            }
        }
        .padding()
        .background(Color(.systemBackground))
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
}

struct InsightsCard: View {
    let insights: [Insight]
    
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
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
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