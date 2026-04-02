import SwiftUI
import UserNotifications

struct LocalNotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var localNotificationService = LocalNotificationService.shared
    @StateObject private var workoutNotificationManager = WorkoutNotificationManager.shared
    
    @State private var showAuthorizationAlert = false
    @State private var isRequestingHealth = false
    
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
                                
                                // Apple Watch / Fitness workout congrats
                                NotificationTypeRow(
                                    title: "Workout congratulations",
                                    subtitle: "After a workout, get a reminder to scan your face",
                                    isOn: Binding(
                                        get: { workoutNotificationManager.workoutNotificationsEnabled },
                                        set: { newValue in
                                            toggleWorkoutNotifications(enabled: newValue)
                                        }
                                    ),
                                    icon: "figure.run",
                                    frequency: .daily
                                )
                            }
                        }
                        .padding()
                        .background(cardBackground)
                        .cornerRadius(14)
                        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
                        
                        if !workoutNotificationManager.isHealthDataAvailable {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("Workout notifications require a real device with Apple Watch or Fitness data.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        
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
    
    private func toggleWorkoutNotifications(enabled: Bool) {
        if enabled {
            guard workoutNotificationManager.isHealthDataAvailable else { return }
            if !localNotificationService.isAuthorized {
                showAuthorizationAlert = true
                return
            }
            isRequestingHealth = true
            Task {
                let granted = await workoutNotificationManager.requestAuthorization()
                await MainActor.run {
                    isRequestingHealth = false
                    if granted {
                        workoutNotificationManager.workoutNotificationsEnabled = true
                    }
                }
            }
        } else {
            workoutNotificationManager.workoutNotificationsEnabled = false
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

 