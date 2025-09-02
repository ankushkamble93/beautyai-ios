import SwiftUI

struct ViewProgressView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale
    @EnvironmentObject var skinDiaryManager: SkinDiaryManager
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @State private var selectedRange: DateRange = .oneMonth
    @State private var selectedLog: SkinLog? = nil
    @State private var showRangeAlert: Bool = false
    // Enhanced dummy data with optimal spacing for each time range
    var dummyLogsForRange: [SkinLog] {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        
        var logs: [SkinLog] = []
        
        switch selectedRange {
        case .oneMonth:
            // Generate data every 3 days for past month (10 points)
            for i in 0..<10 {
                let date = calendar.date(byAdding: .day, value: -(i * 3), to: now)!
                logs.append(SkinLog(
                    date: formatter.string(from: date),
                    percent: Int.random(in: 60...85),
                    mood: ["Clear", "Oily", "Dry", "Sensitive"].randomElement()!,
                    note: "Sample: \(["Good skin day", "Felt a bit oily", "Dry patches", "Clear and hydrated"].randomElement()!)"
                ))
            }
        case .threeMonths:
            // Generate data every week for past 3 months (12 points)
            for i in 0..<12 {
                let date = calendar.date(byAdding: .weekOfYear, value: -i, to: now)!
                logs.append(SkinLog(
                    date: formatter.string(from: date),
                    percent: Int.random(in: 55...90),
                    mood: ["Clear", "Oily", "Dry", "Sensitive", "Bumpy"].randomElement()!,
                    note: "Sample: \(["Weekly progress", "Routine working", "Need more hydration", "Skin improving"].randomElement()!)"
                ))
            }
        case .sixMonths:
            // Generate data every 20 days for past 6 months (9 points)
            for i in 0..<9 {
                let date = calendar.date(byAdding: .day, value: -(i * 20), to: now)!
                logs.append(SkinLog(
                    date: formatter.string(from: date),
                    percent: Int.random(in: 50...95),
                    mood: ["Clear", "Oily", "Dry", "Sensitive", "Bumpy"].randomElement()!,
                    note: "Sample: \(["Long-term progress", "Consistency pays off", "Seasonal changes", "Skin journey"].randomElement()!)"
                ))
            }
        case .all:
            // Generate data every month for past year (12 points)
            for i in 0..<12 {
                let date = calendar.date(byAdding: .month, value: -i, to: now)!
                logs.append(SkinLog(
                    date: formatter.string(from: date),
                    percent: Int.random(in: 45...100),
                    mood: ["Clear", "Oily", "Dry", "Sensitive", "Bumpy"].randomElement()!,
                    note: "Sample: \(["Monthly overview", "Year of progress", "All seasons tracked", "Complete timeline"].randomElement()!)"
                ))
            }
        }
        
        return logs.sorted { (a, b) in
            guard let dateA = formatter.date(from: a.date), let dateB = formatter.date(from: b.date) else { return false }
            return dateA < dateB
        }
    }
    
    var logsToUse: [SkinLog] {
        // Gate graph until the user has at least one analysis
        guard let analysisResults = skinAnalysisManager.getCachedAnalysisResults() else {
            return []
        }
        // When we do have analysis data, seed the latest point and add samples behind it
            // Prefer percent from recommendations.progressTracking.skinHealthScore if available
            let recommendedScore = skinAnalysisManager.recommendations?.progressTracking.skinHealthScore
            let percent = recommendedScore.map { Int($0 * 100) } ?? max(1, min(100, Int(analysisResults.confidence * 100)))
            let analysisLog = SkinLog(
                date: Self.dateFormatter(for: locale).string(from: analysisResults.analysisDate),
                percent: percent,
                mood: "Clear",
                note: "Analysis: \(analysisResults.conditions.count) conditions detected"
            )
            // Integrate smoothly with sample data by replacing the most recent sample point
            var combined = dummyLogsForRange
            if !combined.isEmpty {
                combined.removeLast()
            }
            combined.append(analysisLog)
            return combined
        
    }
    var displayedLogs: [SkinLog] {
        // Since logsToUse already handles the filtering logic, just return it
        return logsToUse
    }
    
    // Timeline entries - completely independent of graph filters, always shows recent diary entries
    var timelineEntries: [SkinLog] {
        if skinDiaryManager.hasRealData {
            // Show ALL recent diary entries (not filtered by graph selection)
            let calendar = Calendar.current
            let now = Date()
            let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
            
            let recentEntries = skinDiaryManager.diaryEntries.filter { entry in
                entry.date >= oneMonthAgo
            }.sorted { $0.date > $1.date } // Most recent first
            
            return recentEntries.map { entry in
                SkinLog(
                    date: skinDiaryManager.formatDateForSkinLog(entry.date),
                    percent: entry.skinHealthPercent,
                    mood: entry.primaryMood,
                    note: entry.note.isEmpty ? entry.combinedStatesText : entry.note
                )
            }
        } else {
            // Show fixed dummy timeline data (independent of graph filters)
            let calendar = Calendar.current
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd"
            
            return [
                SkinLog(date: formatter.string(from: now), percent: 78, mood: "Clear", note: "Sample: Great skin day"),
                SkinLog(date: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!), percent: 65, mood: "Oily", note: "Sample: A bit oily"),
                SkinLog(date: formatter.string(from: calendar.date(byAdding: .day, value: -3, to: now)!), percent: 72, mood: "Dry", note: "Sample: Needed more moisture"),
                SkinLog(date: formatter.string(from: calendar.date(byAdding: .day, value: -5, to: now)!), percent: 80, mood: "Clear", note: "Sample: Routine working well"),
                SkinLog(date: formatter.string(from: calendar.date(byAdding: .day, value: -7, to: now)!), percent: 60, mood: "Sensitive", note: "Sample: Skin felt reactive"),
                SkinLog(date: formatter.string(from: calendar.date(byAdding: .day, value: -10, to: now)!), percent: 75, mood: "Clear", note: "Sample: Good progress"),
                SkinLog(date: formatter.string(from: calendar.date(byAdding: .day, value: -14, to: now)!), percent: 68, mood: "Bumpy", note: "Sample: Few breakouts")
            ]
        }
    }
    
    var isEmpty: Bool { 
        // Only consider empty if we have no real data and no cached analysis data
        return !skinDiaryManager.hasRealData && (skinAnalysisManager.getCachedAnalysisResults()?.conditions.isEmpty ?? true)
    }
    
    var graphDataDescription: String {
        if skinDiaryManager.hasRealData {
            switch selectedRange {
            case .oneMonth: return "Data points every 3 days"
            case .threeMonths: return "Data points weekly"
            case .sixMonths: return "Data points every 20 days"
            case .all: return "Data points monthly"
            }
        } else {
            switch selectedRange {
            case .oneMonth: return "Sample: every 3 days"
            case .threeMonths: return "Sample: weekly intervals"
            case .sixMonths: return "Sample: 20-day intervals"
            case .all: return "Sample: monthly overview"
            }
        }
    }
    var canShowThreeMonths: Bool { true }
    var canShowSixMonths: Bool { true }
    var canShowAll: Bool { true }
    static func dateFormatter(for locale: Locale) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        if locale.identifier.starts(with: "en_US") {
            f.dateFormat = "M/d"
        } else {
            f.dateFormat = "d/M"
        }
        return f
    }
    var body: some View {
        let dateFormatter = Self.dateFormatter(for: locale)
        NavigationView {
            ZStack {
                // Subtle, fun, but not flashy background
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? [Color(red:0.13,green:0.12,blue:0.11), Color(red:0.18,green:0.16,blue:0.13), Color(red:0.10,green:0.09,blue:0.08)] : [Color(red:0.98,green:0.96,blue:0.93), Color(red:1.0,green:0.98,blue:0.93), Color(red:0.93,green:0.95,blue:0.93)]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Title
                        Text("View Insights")
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundColor(primaryText)
                            .padding(.top, 8)
                        // Line Graph Section
                        ZStack(alignment: .topLeading) {
                            VStack(spacing: 0) {
                                LineGraphView(logs: displayedLogs, colorScheme: colorScheme)
                                    .frame(height: 220)
                                    .padding(.top, 14)
                                    .padding(.horizontal, 8)
                                // Range toggles
                                HStack(spacing: 12) {
                                    ToggleButton(title: "1 Month", selected: selectedRange == .oneMonth, enabled: true, width: .infinity, colorScheme: colorScheme) { selectedRange = .oneMonth }
                                    ToggleButton(title: "3 Months", selected: selectedRange == .threeMonths, enabled: true, width: .infinity, colorScheme: colorScheme) { selectedRange = .threeMonths }
                                    ToggleButton(title: "6 Months", selected: selectedRange == .sixMonths, enabled: true, width: .infinity, colorScheme: colorScheme) { selectedRange = .sixMonths }
                                    ToggleButton(title: "All", selected: selectedRange == .all, enabled: true, width: .infinity, colorScheme: colorScheme) { selectedRange = .all }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 10)
                                .padding(.leading, 8)
                            }
                            // Enhanced graph labels (tighter, not clipped)
                            VStack(alignment: .leading, spacing: -2) {
                                Text("Skin Clarity %")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                Text(graphDataDescription)
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                            .padding(.leading, 8)
                            .padding(.top, 0)
                            .background(Color.clear)
                        }
                        .padding(.bottom, 8)
                        .background(cardBG)
                        .cornerRadius(22)
                        .shadow(color: shadowColor, radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 2)
                        // Logged Feelings Timeline (most recent to oldest)
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Recent Skin Diary")
                                        .font(.title2).fontWeight(.bold)
                                        .foregroundColor(primaryText)
                                    Text("Your latest logged skin feelings")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                // Timeline count indicator
                                if skinDiaryManager.hasRealData {
                                    Text("\(timelineEntries.count) entries")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .foregroundColor(.green)
                                        .cornerRadius(8)
                                } else {
                                    Text("Sample data")
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.1))
                                        .foregroundColor(.orange)
                                        .cornerRadius(8)
                                }
                            }
                            Rectangle()
                                .fill(Color.secondary.opacity(0.10))
                                .frame(height: 1)
                                .padding(.bottom, 10)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(timelineEntries.sorted(by: { a, b in
                                        guard let da = Self.dateFormatter(for: locale).date(from: a.date), let db = Self.dateFormatter(for: locale).date(from: b.date) else { return false }
                                        return da > db
                                    })) { log in
                                        VStack(spacing: 8) {
                                            Text(dateFormatter.string(from: dateFormatter.date(from: log.date) ?? Date()))
                                                .font(.caption)
                                                .foregroundColor(secondaryText)
                                            Text(log.mood)
                                                .font(.title3).fontWeight(.semibold)
                                                .foregroundColor(colorForMood(log.mood, colorScheme: colorScheme))
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(cardBG)
                                        .cornerRadius(14)
                                        .shadow(color: shadowColor, radius: 3, x: 0, y: 1)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                        .padding(.horizontal, 2)
                        .background(cardBG)
                        .cornerRadius(18)
                        .shadow(color: shadowColor, radius: 6, x: 0, y: 2)
                        // Tips Section
                        VStack(spacing: 10) {
                            Text("Stay committed to your skincare journey!")
                                .font(.headline)
                                .foregroundColor(primaryText)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("• Consistency is key: log your skin daily for best insights.")
                                Text("• Celebrate small wins and progress.")
                                Text("• Try to log at the same time each day.")
                                Text("• Use your diary to note products, weather, or habits.")
                                Text("• Your skin’s story is unique—track it with care!")
                            }
                            .font(.subheadline)
                            .foregroundColor(secondaryText)
                        }
                        .padding()
                        .background(cardBG)
                        .cornerRadius(18)
                        .shadow(color: shadowColor, radius: 6, x: 0, y: 2)
                        // Data Status Information
                        VStack(spacing: 16) {
                            if skinDiaryManager.hasRealData {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Showing your personal skin diary data")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.green)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green.opacity(0.1))
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                            } else if skinAnalysisManager.getCachedAnalysisResults() != nil {
                                HStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.blue)
                                    Text("Combined with your skin analysis data")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.1))
                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            } else {
                                VStack(spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "chart.line.uptrend.xyaxis")
                                            .foregroundColor(.orange)
                                        Text("Sample data for \(selectedRange.rawValue.lowercased())")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.orange)
                                    }
                                    
                                    Text("Start logging your skin diary (6 PM - midnight) or take a skin analysis to see your personal data here!")
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.orange.opacity(0.1))
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .sheet(item: $selectedLog) { log in
                LogNoteModal(log: log)
            }
            .alert(isPresented: $showRangeAlert) {
                Alert(title: Text("Not enough data"), message: Text("You need to log more days to view this range. Start logging your skin to unlock longer-term insights!"), dismissButton: .default(Text("OK")))
            }
        }
    }
    // MARK: - Colors
    private var bg: Color {
        colorScheme == .dark ? Color(red: 0.10, green: 0.09, blue: 0.08) : Color(red: 0.98, green: 0.96, blue: 0.93)
    }
    private var cardBG: Color {
        colorScheme == .dark ? Color(red: 0.18, green: 0.16, blue: 0.13) : Color(red: 1.0, green: 0.98, blue: 0.93)
    }
    private var primaryText: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    private var secondaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.7) : Color.gray
    }
    private var accent: Color {
        colorScheme == .dark ? Color.purple : Color.blue
    }
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.18) : Color.gray.opacity(0.10)
    }
    private func colorForMood(_ mood: String, colorScheme: ColorScheme) -> Color {
        switch mood.lowercased() {
        case "clear": return colorScheme == .dark ? Color.green.opacity(0.85) : Color.green
        case "dry": return colorScheme == .dark ? Color.orange.opacity(0.85) : Color.orange
        case "oily": return colorScheme == .dark ? Color.blue.opacity(0.85) : Color.blue
        default: return colorScheme == .dark ? Color.gray.opacity(0.85) : Color.gray
        }
    }
}

// MARK: - Line Graph View
struct LineGraphView: View {
    let logs: [SkinLog]
    var colorScheme: ColorScheme
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let points = logs.enumerated().map { (i, log) in
                CGPoint(
                    x: width * CGFloat(i) / CGFloat(max(logs.count - 1, 1)),
                    y: height * (1 - CGFloat(log.percent) / 100)
                )
            }
            ZStack {
                // Y-Axis (0-100%)
                VStack(spacing: 0) {
                    HStack(alignment: .bottom, spacing: 0) {
                        VStack(spacing: 0) {
                            ForEach([100, 75, 50, 25, 0], id: \ .self) { y in
                                Spacer()
                                Text("\(y)%")
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                                    .frame(width: 32, alignment: .trailing)
                            }
                        }
                        Rectangle()
                            .fill(Color.secondary.opacity(0.13))
                            .frame(width: 1, height: height - 20)
                        ZStack {
                            // Sharp polyline through each point (no smoothing)
                            if points.count > 1 {
                                Path { path in
                                    path.move(to: points[0])
                                    for i in 1..<points.count {
                                        path.addLine(to: points[i])
                                    }
                                }
                                .stroke(Color.green.opacity(0.78), lineWidth: 2.2)
                                .shadow(color: Color.green.opacity(0.12), radius: 1, x: 0, y: 1)
                            }
                            // Points (not tappable)
                            ForEach(Array(logs.enumerated()), id: \.offset) { idx, log in
                                let pt = points[idx]
                                Circle()
                                    .fill(Color.green.opacity(0.7))
                                    .frame(width: 5, height: 5)
                                    .position(x: pt.x + (idx == 0 ? 8 : 0), y: pt.y)
                                    .shadow(color: Color.green.opacity(0.13), radius: 1, x: 0, y: 1)
                            }
                        }
                    }
                    .frame(height: height - 20)
                    // X-Axis
                    HStack(spacing: 0) {
                        Spacer().frame(width: 32)
                        ForEach(logs) { log in
                            Text({
                                let f = DateFormatter()
                                f.locale = Locale.current
                                if f.locale.identifier.starts(with: "en_US") {
                                    f.dateFormat = "M/d"
                                } else {
                                    f.dateFormat = "d/M"
                                }
                                return f.string(from: f.date(from: log.date) ?? Date())
                            }())
                                .font(.caption2)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 20)
                }
            }
        }
    }
}

// MARK: - Toggle Button

// Updated ToggleButton to support disabled state
struct ToggleButton: View {
    let title: String
    let selected: Bool
    var enabled: Bool = true
    var width: CGFloat? = nil
    var colorScheme: ColorScheme = .light
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: width)
                .padding(.vertical, 8)
                .background(selected ? (colorScheme == .dark ? Color.purple.opacity(0.25) : Color.blue.opacity(0.18)) : Color.clear)
                .foregroundColor(selected ? (colorScheme == .dark ? .white : .blue) : .secondary)
                .opacity(enabled ? 1.0 : 0.4)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!enabled)
    }
}

// MARK: - Log Note Modal
struct LogNoteModal: View {
    let log: SkinLog
    var body: some View {
        VStack(spacing: 18) {
            Text("\(log.date) – \(log.percent)%")
                .font(.title2).fontWeight(.bold)
            Text("Feeling: \(log.mood)")
                .font(.headline)
            Text(log.note)
                .font(.body)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
        .frame(maxWidth: 340)
    }
}

#Preview {
    ViewProgressView()
} 