import SwiftUI

struct RoutineSummaryCard: View {
    let morning: [String]
    let evening: [String]
    let weekly: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) { Image(systemName: "sun.max.fill").foregroundColor(.yellow); Text("Morning Routine").font(.headline) }
            ForEach(morning, id: \.self) { step in row(step, color: .blue) }
            Divider().padding(.vertical, 4)
            HStack(spacing: 8) { Image(systemName: "moon.stars.fill").foregroundColor(.purple); Text("Evening Routine").font(.headline) }
            ForEach(evening, id: \.self) { step in row(step, color: .purple) }
            if !weekly.isEmpty {
                Divider().padding(.vertical, 4)
                HStack(spacing: 8) { Image(systemName: "calendar").foregroundColor(.orange); Text("Weekly Treatments").font(.headline) }
                ForEach(weekly, id: \.self) { step in row(step, color: .orange) }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
    
    private func row(_ text: String, color: Color) -> some View {
        HStack { Image(systemName: "checkmark.circle.fill").foregroundColor(color.opacity(0.7)); Text(text).font(.body) }
    }
}

enum AIMessageParse {
    case plain(String)
    case routine(morning: [String], evening: [String], weekly: [String], restText: String?)
}

extension AIMessageParse {
    static func parseRoutines(from text: String) -> AIMessageParse {
        // Simple parser for patterns like "**Morning Routine:** Cleanser, Toner..."
        func extract(_ label: String) -> [String] {
            // Find line starting with label and collect until next ** or end
            let lines = text.components(separatedBy: "\n")
            var capture = false
            var items: [String] = []
            for line in lines {
                if line.lowercased().contains(label.lowercased()) { capture = true; continue }
                if capture && line.contains("**") { break }
                if capture {
                    let trimmed = line.replacingOccurrences(of: "- ", with: "").trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty { items.append(trimmed) }
                }
            }
            return items
        }
        let morning = extract("Morning Routine:")
        let evening = extract("Evening Routine:")
        let weekly = extract("Weekly Treatments:")
        if morning.isEmpty && evening.isEmpty && weekly.isEmpty { return .plain(text) }
        return .routine(morning: morning, evening: evening, weekly: weekly, restText: nil)
    }
}


