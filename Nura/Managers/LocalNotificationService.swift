import Foundation
import UserNotifications
import SwiftUI

// MARK: - Local Notification Service (Frugal Approach)

class LocalNotificationService: ObservableObject {
    static let shared = LocalNotificationService()
    
    @Published var isAuthorized = false
    @Published var localPreferences: LocalNotificationPreferences
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "local_notification_preferences"
    
    private init() {
        // Load saved preferences or create defaults
        if let data = userDefaults.data(forKey: preferencesKey),
           let savedPreferences = try? JSONDecoder().decode(LocalNotificationPreferences.self, from: data) {
            self.localPreferences = savedPreferences
        } else {
            self.localPreferences = LocalNotificationPreferences.default
        }
        
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            
            await MainActor.run {
                self.isAuthorized = granted
            }
            
            return granted
        } catch {
            print("❌ Failed to request notification authorization: \(error.localizedDescription)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
                print("🔔 Notification authorization status: \(settings.authorizationStatus.rawValue)")
                print("🔔 Alert setting: \(settings.alertSetting.rawValue)")
                print("🔔 Badge setting: \(settings.badgeSetting.rawValue)")
                print("🔔 Sound setting: \(settings.soundSetting.rawValue)")
                print("🔔 Notification center setting: \(settings.notificationCenterSetting.rawValue)")
                print("🔔 Lock screen setting: \(settings.lockScreenSetting.rawValue)")
            }
        }
    }
    
    // MARK: - Preferences Management
    
    func updatePreferences(_ preferences: LocalNotificationPreferences) {
        self.localPreferences = preferences
        savePreferences()
        scheduleNotifications()
    }
    
    private func savePreferences() {
        if let data = try? JSONEncoder().encode(localPreferences) {
            userDefaults.set(data, forKey: preferencesKey)
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleNotifications() {
        guard isAuthorized else { return }
        
        // Cancel existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Schedule based on preferences
        if localPreferences.dailyPhotoReminder.enabled {
            scheduleDailyPhotoReminder()
        }
        
        if localPreferences.routineReminder.enabled {
            scheduleRoutineReminder()
        }
        
        if localPreferences.progressReminder.enabled {
            scheduleProgressReminder()
        }
    }
    
    private func scheduleDailyPhotoReminder() {
        let content = UNMutableNotificationContent()
        content.title = "📸 Time for your daily skin check!"
        content.body = "Take a photo and track your skin's progress. Consistency is key to beautiful skin!"
        content.sound = .default
        content.categoryIdentifier = "reminder"
        
        // Schedule for user's preferred time
        let preferredTime = localPreferences.preferredTime
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.hour, .minute], from: preferredTime),
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "daily_photo_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule daily photo reminder: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled daily photo reminder")
            }
        }
    }
    
    private func scheduleRoutineReminder() {
        let content = UNMutableNotificationContent()
        content.title = "🌟 Don't forget your skincare routine!"
        content.body = "Your personalized routine is waiting. A few minutes now for glowing skin later!"
        content.sound = .default
        content.categoryIdentifier = "routine"
        
        // Schedule for evening (6 PM)
        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "routine_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule routine reminder: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled routine reminder")
            }
        }
    }
    
    private func scheduleProgressReminder() {
        let content = UNMutableNotificationContent()
        content.title = "📊 Weekly Progress Check-in"
        content.body = "Share your skin health progress and celebrate your journey!"
        content.sound = .default
        content.categoryIdentifier = "progress"
        
        // Schedule for weekly (Sunday at 10 AM)
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: "progress_reminder",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule progress reminder: \(error.localizedDescription)")
            } else {
                print("✅ Scheduled progress reminder")
            }
        }
    }
    
    // MARK: - Immediate Notifications
    
    func sendImmediateNotification(title: String, body: String, category: String = "general") {
        guard isAuthorized else { 
            print("❌ Notifications not authorized")
            return 
        }
        
        print("🔔 Attempting to send notification: \(title)")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category
        content.badge = 1
        
        // Add user info for debugging
        content.userInfo = [
            "timestamp": Date().timeIntervalSince1970,
            "category": category,
            "test": true
        ]
        
        // Use immediate trigger for testing
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "immediate_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Failed to send immediate notification: \(error.localizedDescription)")
            } else {
                print("✅ Sent immediate notification: \(title)")
                print("📱 Notification ID: \(request.identifier)")
                
                // For simulator testing, also show a local alert
                #if targetEnvironment(simulator)
                DispatchQueue.main.async {
                    print("📱 Simulator: Notification should appear in Notification Center")
                    print("📱 Check: Settings > Notifications > Nura > Allow Notifications")
                }
                #endif
            }
        }
        
        // Also check pending notifications
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.checkPendingNotifications()
        }
    }
    
    private func checkPendingNotifications() {
        notificationCenter.getPendingNotificationRequests { requests in
            print("📋 Pending notifications: \(requests.count)")
            for request in requests {
                print("📋 - \(request.identifier): \(request.content.title)")
            }
        }
        
        notificationCenter.getDeliveredNotifications { notifications in
            print("📱 Delivered notifications: \(notifications.count)")
            for notification in notifications {
                print("📱 - \(notification.request.identifier): \(notification.request.content.title)")
            }
        }
    }
    
    // MARK: - Smart Notifications
    
    func sendSkinAnalysisCompleteNotification() {
        sendImmediateNotification(
            title: "🔍 Your skin analysis is complete!",
            body: "New insights and recommendations are ready. Discover what your skin is telling you!",
            category: "analysis"
        )
    }
    
    func sendRoutineMissedNotification() {
        sendImmediateNotification(
            title: "⏰ Routine Reminder",
            body: "You haven't completed your skincare routine today. Don't forget to take care of your skin!",
            category: "routine"
        )
    }
    
    func sendProgressMilestoneNotification(score: Int) {
        sendImmediateNotification(
            title: "🎉 Congratulations!",
            body: "Your skin health score reached \(score)! Keep up the amazing work!",
            category: "achievement"
        )
    }
    
    // MARK: - Utility Methods
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("🗑️ Cancelled all pending notifications")
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
}

// MARK: - Local Data Models

struct LocalNotificationPreferences: Codable {
    var dailyPhotoReminder: NotificationSetting
    var routineReminder: NotificationSetting
    var progressReminder: NotificationSetting
    var preferredTime: Date
    
    static let `default` = LocalNotificationPreferences(
        dailyPhotoReminder: NotificationSetting(enabled: true, frequency: .daily),
        routineReminder: NotificationSetting(enabled: true, frequency: .daily),
        progressReminder: NotificationSetting(enabled: true, frequency: .weekly),
        preferredTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    )
}

struct NotificationSetting: Codable {
    var enabled: Bool
    var frequency: NotificationFrequency
    
    enum NotificationFrequency: String, Codable, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case never = "never"
    }
}

// MARK: - Usage Examples

extension LocalNotificationService {
    
    // Example usage methods
    func setupDefaultNotifications() {
        let defaultPreferences = LocalNotificationPreferences.default
        updatePreferences(defaultPreferences)
    }
    
    func toggleDailyReminder() {
        var updatedPreferences = localPreferences
        updatedPreferences.dailyPhotoReminder.enabled.toggle()
        updatePreferences(updatedPreferences)
    }
    
    func setPreferredTime(_ time: Date) {
        var updatedPreferences = localPreferences
        updatedPreferences.preferredTime = time
        updatePreferences(updatedPreferences)
    }
} 