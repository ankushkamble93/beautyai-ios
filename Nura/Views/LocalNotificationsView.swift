import SwiftUI
import UserNotifications

struct LocalNotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var localNotificationService = LocalNotificationService.shared
    
    @State private var showAuthorizationAlert = false
    @State private var showSuccessBanner = false
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [NuraColors.sand, NuraColors.primary.opacity(0.18), NuraColors.secondary.opacity(0.12)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .center, spacing: 28) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Notifications")
                                .font(.title)
                                .fontWeight(.bold)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text("Stay updated with your skin journey")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        
                        // Notification Channels
                        VStack(spacing: 18) {
                            // Push Notifications
                            NotificationChannelRow(
                                title: "Push Notifications",
                                subtitle: localNotificationService.isAuthorized ? "Notifications enabled" : "Get alerts on your device",
                                isOn: Binding(
                                    get: { localNotificationService.isAuthorized },
                                    set: { _ in 
                                        if localNotificationService.isAuthorized {
                                            // If already authorized, open settings
                                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                                UIApplication.shared.open(settingsUrl)
                                            }
                                        } else {
                                            // If not authorized, request permission
                                            requestAuthorization()
                                        }
                                    }
                                ),
                                systemImage: "bell.fill",
                                iconColor: NuraColors.secondary,
                                isEnabled: true,
                                comingSoon: false
                            )
                            
                            // Email Notifications
                            NotificationChannelRow(
                                title: "Email Notifications",
                                subtitle: "Receive updates via email",
                                isOn: .constant(false),
                                systemImage: "envelope.fill",
                                iconColor: NuraColors.secondary,
                                isEnabled: false,
                                comingSoon: true
                            )
                            
                            // SMS Notifications
                            NotificationChannelRow(
                                title: "SMS Notifications",
                                subtitle: "Text message alerts",
                                isOn: .constant(false),
                                systemImage: "message.fill",
                                iconColor: NuraColors.secondary,
                                isEnabled: false,
                                comingSoon: true
                            )
                        }
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                        
                        // Help text for notification permissions
                        if localNotificationService.isAuthorized {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text("Tap the toggle to open iOS Settings and manage notification permissions")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Notification Types
                        VStack(spacing: 16) {
                            Text("Notification Types")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                NotificationTypeRow(
                                    title: "Daily Photo Reminder",
                                    subtitle: "Remind me to take daily skin photos",
                                    isOn: Binding(
                                        get: { localNotificationService.localPreferences.dailyPhotoReminder.enabled },
                                        set: { newValue in
                                            toggleNotificationType(.dailyPhotoReminder, enabled: newValue)
                                        }
                                    ),
                                    icon: "camera.fill",
                                    frequency: localNotificationService.localPreferences.dailyPhotoReminder.frequency
                                )
                                
                                NotificationTypeRow(
                                    title: "Routine Reminder",
                                    subtitle: "Remind me to follow my skincare routine",
                                    isOn: Binding(
                                        get: { localNotificationService.localPreferences.routineReminder.enabled },
                                        set: { newValue in
                                            toggleNotificationType(.routineReminder, enabled: newValue)
                                        }
                                    ),
                                    icon: "heart.fill",
                                    frequency: localNotificationService.localPreferences.routineReminder.frequency
                                )
                                
                                NotificationTypeRow(
                                    title: "Progress Check-in",
                                    subtitle: "Weekly progress reminders",
                                    isOn: Binding(
                                        get: { localNotificationService.localPreferences.progressReminder.enabled },
                                        set: { newValue in
                                            toggleNotificationType(.progressReminder, enabled: newValue)
                                        }
                                    ),
                                    icon: "chart.line.uptrend.xyaxis",
                                    frequency: localNotificationService.localPreferences.progressReminder.frequency
                                )
                            }
                        }
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                        

                        
                        // Coming Soon Banner
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(NuraColors.primary)
                                Text("More Features Coming Soon!")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(NuraColors.primary)
                            }
                            
                            Text("Email and SMS notifications are in development. You'll be able to receive updates across all your devices and channels.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(NuraColors.primary.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(NuraColors.primary.opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        // Test Notifications
                        VStack(spacing: 16) {
                            Text("Test Notifications")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 8) {
                                Button("Test Daily Reminder") {
                                    testNotification(type: "daily")
                                }
                                .buttonStyle(TestButtonStyle())
                                
                                Button("Test Routine Reminder") {
                                    testNotification(type: "routine")
                                }
                                .buttonStyle(TestButtonStyle())
                                
                                Button("Test Progress Reminder") {
                                    testNotification(type: "progress")
                                }
                                .buttonStyle(TestButtonStyle())
                                
                                Button("Debug Notification Settings") {
                                    debugNotificationSettings()
                                }
                                .buttonStyle(TestButtonStyle())
                            }
                        }
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .alert("Enable Notifications", isPresented: $showAuthorizationAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to receive updates about your skin journey.")
            }
        }
        .overlay(
            // Success Banner
            VStack {
                if showSuccessBanner {
                    SuccessBanner(message: "Test notification sent!")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showSuccessBanner)
    }
    
    // MARK: - Helper Methods
    
    private func requestAuthorization() {
        Task {
            let granted = await localNotificationService.requestAuthorization()
            if !granted {
                await MainActor.run {
                    showAuthorizationAlert = true
                }
            }
        }
    }
    
    private func toggleNotificationType(_ type: NotificationType, enabled: Bool) {
        var updatedPreferences = localNotificationService.localPreferences
        
        switch type {
        case .dailyPhotoReminder:
            updatedPreferences.dailyPhotoReminder.enabled = enabled
        case .routineReminder:
            updatedPreferences.routineReminder.enabled = enabled
        case .progressReminder:
            updatedPreferences.progressReminder.enabled = enabled
        }
        
        localNotificationService.updatePreferences(updatedPreferences)
    }
    
    private func testNotification(type: String) {
        // First check if notifications are authorized
        guard localNotificationService.isAuthorized else {
            showAuthorizationAlert = true
            return
        }
        
        // Send the appropriate test notification
        switch type {
        case "daily":
            localNotificationService.sendImmediateNotification(
                title: "📸 Time for your daily skin check!",
                body: "Take a photo and track your skin's progress. Consistency is key to beautiful skin!",
                category: "reminder"
            )
        case "routine":
            localNotificationService.sendImmediateNotification(
                title: "🌟 Don't forget your skincare routine!",
                body: "Your personalized routine is waiting. A few minutes now for glowing skin later!",
                category: "routine"
            )
        case "progress":
            localNotificationService.sendImmediateNotification(
                title: "📊 Weekly Progress Check-in",
                body: "Share your skin health progress and celebrate your journey!",
                category: "progress"
            )
        default:
            break
        }
        
        // Show success feedback
        showSuccessBanner = true
        
        // Auto-hide success banner after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSuccessBanner = false
        }
    }
    
    private func debugNotificationSettings() {
        print("🔍 === NOTIFICATION DEBUG INFO ===")
        print("🔍 Is Authorized: \(localNotificationService.isAuthorized)")
        
        // Check notification settings
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("🔍 Authorization Status: \(settings.authorizationStatus.rawValue)")
            print("🔍 Alert Setting: \(settings.alertSetting.rawValue)")
            print("🔍 Badge Setting: \(settings.badgeSetting.rawValue)")
            print("🔍 Sound Setting: \(settings.soundSetting.rawValue)")
            print("🔍 Notification Center: \(settings.notificationCenterSetting.rawValue)")
            print("🔍 Lock Screen: \(settings.lockScreenSetting.rawValue)")
            
            // Check pending notifications
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                print("🔍 Pending Notifications: \(requests.count)")
                for request in requests {
                    print("🔍 - \(request.identifier): \(request.content.title)")
                }
            }
            
            // Check delivered notifications
            UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
                print("🔍 Delivered Notifications: \(notifications.count)")
                for notification in notifications {
                    print("🔍 - \(notification.request.identifier): \(notification.request.content.title)")
                }
            }
        }
        
        showSuccessBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSuccessBanner = false
        }
    }
}

// MARK: - Supporting Types

enum NotificationType {
    case dailyPhotoReminder
    case routineReminder
    case progressReminder
}

struct NotificationChannelRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let systemImage: String
    let iconColor: Color
    let isEnabled: Bool
    let comingSoon: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if comingSoon {
                        Text("Coming Soon")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(NuraColors.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(NuraColors.primary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75))
            }
            
            Spacer()
            
            if comingSoon {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: NuraColors.primary))
                    .disabled(!isEnabled)
            }
        }
        .padding(.vertical, 8)
        .opacity(isEnabled ? 1.0 : 0.6)
    }
}

 