import SwiftUI

struct SkinLog: Identifiable, Equatable {
    let id = UUID()
    let date: String
    let percent: Int
    let mood: String
    let note: String
}

struct ViewProgressView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.locale) private var locale
    @State private var selectedRange: DataRange = .oneMonth
    @State private var selectedLog: SkinLog? = nil
    @State private var showRangeAlert: Bool = false
    // Dummy data for now
    let skinLogs: [SkinLog] = [
        .init(date: "Jul 16", percent: 62, mood: "Oily", note: "Felt greasy, humid day"),
        .init(date: "Jul 17", percent: 68, mood: "Dry", note: "A bit flaky, forgot moisturizer"),
        .init(date: "Jul 18", percent: 70, mood: "Clear", note: "Skin felt good!"),
        .init(date: "Jul 19", percent: 74, mood: "Clear", note: "Routine on track"),
        .init(date: "Jul 20", percent: 65, mood: "Oily", note: "Late night, more oil"),
        .init(date: "Jul 21", percent: 72, mood: "Clear", note: "Skin felt great!"),
        .init(date: "Jul 22", percent: 78, mood: "Clear", note: "Best day yet!"),
        .init(date: "Jul 23", percent: 80, mood: "Clear", note: "Glowing, hydrated"),
        .init(date: "Jul 24", percent: 76, mood: "Dry", note: "Slight dryness, AC on"),
        .init(date: "Jul 25", percent: 82, mood: "Clear", note: "Excellent clarity")
    ]
    let dummyLogs: [SkinLog] = [
        .init(date: "Jul 01", percent: 60, mood: "Oily", note: "Sample: Felt greasy, humid day"),
        .init(date: "Jul 05", percent: 68, mood: "Dry", note: "Sample: A bit flaky, forgot moisturizer"),
        .init(date: "Jul 10", percent: 70, mood: "Clear", note: "Sample: Skin felt good!"),
        .init(date: "Jul 13", percent: 74, mood: "Clear", note: "Sample: Routine on track"),
        .init(date: "Jul 16", percent: 65, mood: "Oily", note: "Sample: Late night, more oil"),
        .init(date: "Jul 19", percent: 72, mood: "Clear", note: "Sample: Skin felt great!"),
        .init(date: "Jul 22", percent: 78, mood: "Clear", note: "Sample: Best day yet!"),
        .init(date: "Jul 25", percent: 80, mood: "Clear", note: "Sample: Glowing, hydrated"),
        .init(date: "Jul 28", percent: 76, mood: "Dry", note: "Sample: Slight dryness, AC on"),
        .init(date: "Jul 31", percent: 82, mood: "Clear", note: "Sample: Excellent clarity")
    ]
    var logsToUse: [SkinLog] { skinLogs.isEmpty ? dummyLogs : skinLogs }
    var displayedLogs: [SkinLog] {
        let now = Date()
        let calendar = Calendar.current
        let filtered: [SkinLog] = logsToUse.filter { log in
            guard let logDate = Self.dateFormatter(for: locale).date(from: log.date) else { return false }
            switch selectedRange {
            case .oneMonth:
                return logDate >= calendar.date(byAdding: .month, value: -1, to: now)!
            case .threeMonths:
                return logDate >= calendar.date(byAdding: .month, value: -3, to: now)!
            case .sixMonths:
                return logDate >= calendar.date(byAdding: .month, value: -6, to: now)!
            case .all:
                return true
            }
        }
        return filtered.sorted { (a, b) in
            guard let da = Self.dateFormatter(for: locale).date(from: a.date), let db = Self.dateFormatter(for: locale).date(from: b.date) else { return false }
            return da < db
        }
    }
    var isEmpty: Bool { skinLogs.isEmpty }
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
                                LineGraphView(logs: displayedLogs.isEmpty ? dummyLogs : displayedLogs, colorScheme: colorScheme)
                                    .frame(height: 220)
                                    .padding(.top, 8)
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
                            // Floater for y-axis label
                            Text("Skin Clarity %")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                                .padding(.top, 2)
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
                                Spacer()
                                Text("Logged Feelings Timeline")
                                    .font(.title2).fontWeight(.bold)
                                    .padding(.bottom, 2)
                                    .foregroundColor(primaryText)
                                Spacer()
                            }
                            Rectangle()
                                .fill(Color.secondary.opacity(0.10))
                                .frame(height: 1)
                                .padding(.bottom, 10)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach((displayedLogs.isEmpty ? dummyLogs : displayedLogs).sorted(by: { a, b in
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
                        // Empty State
                        if isEmpty {
                            VStack(spacing: 16) {
                                Text("You're viewing sample data.")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("As you start logging your skin, your own data will replace this sample data. After your first log, you'll see your own insights here!")
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 40)
                        }
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
                            // Shadow
                            if points.count > 1 {
                                Path { path in
                                    path.move(to: points[0])
                                    for i in 1..<points.count {
                                        let prev = points[i-1]
                                        let curr = points[i]
                                        let mid = CGPoint(x: (prev.x + curr.x)/2, y: (prev.y + curr.y)/2)
                                        path.addQuadCurve(to: mid, control: prev)
                                    }
                                    path.addLine(to: points.last!)
                                }
                                .stroke(Color.green.opacity(0.7), lineWidth: 2)
                                .shadow(color: Color.green.opacity(0.13), radius: 2, x: 0, y: 1)
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
enum DataRange: String, CaseIterable {
    case oneMonth = "1 Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case all = "All"
}

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