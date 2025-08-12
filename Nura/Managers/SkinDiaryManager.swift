import SwiftUI
import Foundation

// MARK: - Shared Data Models

struct SkinLog: Identifiable, Equatable {
    let id = UUID()
    let date: String
    let percent: Int
    let mood: String
    let note: String
}

enum DateRange: String, CaseIterable {
    case oneMonth = "1 Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case all = "All"
}

class SkinDiaryManager: ObservableObject {
    @Published var diaryEntries: [SkinDiaryEntry] = []
    @Published var canLogToday: Bool = false
    @Published var timeUntilNextLog: TimeInterval = 0
    
    private let userDefaults = UserDefaults.standard
    private let entriesKey = "skin_diary_entries"
    private var timer: Timer?
    
    init() {
        loadEntries()
        startTimer()
        updateLogStatus()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Time Restrictions
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            self.updateLogStatus()
        }
    }
    
    private func updateLogStatus() {
        let now = Date()
        let calendar = Calendar.current
        
            // Check if user already logged today
    let hasLoggedToday = diaryEntries.contains { entry in
        calendar.isDate(entry.date, inSameDayAs: now)
    }
        
        if hasLoggedToday {
            canLogToday = false
            // Calculate time until next available log (6 PM tomorrow)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            let tomorrowSixPM = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: tomorrow)!
            timeUntilNextLog = tomorrowSixPM.timeIntervalSince(now)
        } else {
            // Check if it's between 6 PM and midnight
            let hour = calendar.component(.hour, from: now)
            canLogToday = hour >= 18 // 6 PM to midnight (before next day starts)
            
            if !canLogToday {
                // Calculate time until 6 PM today or tomorrow
                if hour < 18 {
                    // Before 6 PM today
                    let todaySixPM = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
                    timeUntilNextLog = todaySixPM.timeIntervalSince(now)
                } else {
                    // After midnight, wait until 6 PM today
                    let todaySixPM = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
                    timeUntilNextLog = todaySixPM.timeIntervalSince(now)
                }
            }
        }
    }
    
    func formatTimeUntilNextLog() -> String {
        let hours = Int(timeUntilNextLog) / 3600
        let minutes = (Int(timeUntilNextLog) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Data Management
    
    private func loadEntries() {
        if let data = userDefaults.data(forKey: entriesKey),
           let entries = try? JSONDecoder().decode([SkinDiaryEntry].self, from: data) {
            self.diaryEntries = entries.sorted { $0.date > $1.date }
        }
    }
    
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(diaryEntries) {
            userDefaults.set(data, forKey: entriesKey)
        }
    }
    
    func addEntry(states: Set<String>, otherText: String, note: String) -> Bool {
        guard canLogToday else { return false }
        
        let entry = SkinDiaryEntry(
            date: Date(),
            selectedStates: Array(states),
            otherText: otherText,
            note: note,
            skinHealthPercent: calculateSkinHealthPercent(from: states)
        )
        
        diaryEntries.insert(entry, at: 0) // Add to beginning (most recent first)
        saveEntries()
        updateLogStatus() // Update can log status
        
        return true
    }
    
    private func calculateSkinHealthPercent(from states: Set<String>) -> Int {
        // Calculate a skin health percentage based on logged states
        var baseScore = 70
        
        for state in states {
            switch state.lowercased() {
            case "clear":
                baseScore += 15
            case "dry":
                baseScore -= 5
            case "oily":
                baseScore -= 8
            case "sensitive":
                baseScore -= 12
            case "bumpy":
                baseScore -= 15
            case "other":
                baseScore -= 3
            default:
                break
            }
        }
        
        // Add some randomness for realism (±5)
        baseScore += Int.random(in: -5...5)
        
        return max(20, min(100, baseScore)) // Keep between 20-100
    }
    
    // MARK: - Data Access for ViewProgressView
    
    func getTodayEntry() -> SkinDiaryEntry? {
        let calendar = Calendar.current
        let now = Date()
        
        return diaryEntries.first { entry in
            calendar.isDate(entry.date, inSameDayAs: now)
        }
    }
    
    func isNewDaySinceLastLog() -> Bool {
        guard let lastEntry = diaryEntries.first else { return true }
        
        let calendar = Calendar.current
        let now = Date()
        
        return !calendar.isDate(lastEntry.date, inSameDayAs: now)
    }
    
    func getEntriesForDateRange(_ range: DateRange) -> [SkinLog] {
        let calendar = Calendar.current
        let now = Date()
        
        // First filter by date range
        let filteredEntries = diaryEntries.filter { entry in
            switch range {
            case .oneMonth:
                return entry.date >= calendar.date(byAdding: .month, value: -1, to: now)!
            case .threeMonths:
                return entry.date >= calendar.date(byAdding: .month, value: -3, to: now)!
            case .sixMonths:
                return entry.date >= calendar.date(byAdding: .month, value: -6, to: now)!
            case .all:
                return true
            }
        }
        
        // Then apply spacing optimization for graph clarity
        let spacedEntries = applySpacingOptimization(entries: filteredEntries, for: range)
        
        return spacedEntries.map { entry in
            SkinLog(
                date: formatDateForSkinLog(entry.date),
                percent: entry.skinHealthPercent,
                mood: entry.primaryMood,
                note: entry.note.isEmpty ? entry.combinedStatesText : entry.note
            )
        }
    }
    
    private func applySpacingOptimization(entries: [SkinDiaryEntry], for range: DateRange) -> [SkinDiaryEntry] {
        let calendar = Calendar.current
        let sortedEntries = entries.sorted { $0.date > $1.date } // Most recent first
        
        var optimizedEntries: [SkinDiaryEntry] = []
        var lastAddedDate: Date?
        
        let minInterval: TimeInterval
        
        switch range {
        case .oneMonth:
            minInterval = 3 * 24 * 60 * 60 // 3 days
        case .threeMonths:
            minInterval = 7 * 24 * 60 * 60 // 1 week
        case .sixMonths:
            minInterval = 20 * 24 * 60 * 60 // 20 days
        case .all:
            minInterval = 30 * 24 * 60 * 60 // 1 month
        }
        
        for entry in sortedEntries {
            if let lastDate = lastAddedDate {
                if entry.date.timeIntervalSince(lastDate) >= minInterval {
                    optimizedEntries.append(entry)
                    lastAddedDate = entry.date
                }
            } else {
                // Always include the first (most recent) entry
                optimizedEntries.append(entry)
                lastAddedDate = entry.date
            }
        }
        
        return optimizedEntries.reversed() // Return in chronological order for graph
    }
    
    func formatDateForSkinLog(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
    
    var hasRealData: Bool {
        return !diaryEntries.isEmpty
    }
}

// MARK: - Data Models

struct SkinDiaryEntry: Codable, Identifiable {
    let id: UUID = UUID()
    let date: Date
    let selectedStates: [String]
    let otherText: String
    let note: String
    let skinHealthPercent: Int
    
    var primaryMood: String {
        if selectedStates.contains("Clear") { return "Clear" }
        if selectedStates.contains("Oily") { return "Oily" }
        if selectedStates.contains("Dry") { return "Dry" }
        if selectedStates.contains("Sensitive") { return "Sensitive" }
        if selectedStates.contains("Bumpy") { return "Bumpy" }
        return selectedStates.first ?? "Other"
    }
    
    var combinedStatesText: String {
        var states = selectedStates
        if !otherText.isEmpty {
            states.append(otherText)
        }
        return states.joined(separator: ", ")
    }
} 