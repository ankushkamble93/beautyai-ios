# Nura iOS App

A comprehensive skincare analysis and routine management app built with SwiftUI.

## Features

- **Skin Analysis**: AI-powered skin condition detection and analysis
- **Personalized Routines**: Custom skincare recommendations based on analysis results
- **Progress Tracking**: Monitor your skin health journey over time
- **Smart Notifications**: Intelligent reminders and updates
- **User Management**: Secure authentication and profile management

## Notification System

The app includes a comprehensive notification system that supports multiple channels and smart timing.

### Features

- **Multi-Channel Support**: Push notifications, email, and SMS
- **Smart Scheduling**: Intelligent timing based on user behavior
- **Granular Control**: Users can customize notification types and frequencies
- **Analytics Tracking**: Monitor notification engagement and effectiveness

### Notification Types

1. **Daily Photo Reminder** 📸
   - Reminds users to take daily skin photos
   - Default: Daily at user's preferred time
   - Channels: Push notifications

2. **Dashboard Score Share** 📊
   - Encourages sharing progress with friends
   - Default: Weekly
   - Channels: Push notifications, email

3. **Routine Follow-up** 🌟
   - Reminds users to follow their skincare routine
   - Default: Daily at 6 PM
   - Channels: Push notifications

4. **Skin Analysis Complete** 🔍
   - Sent when analysis results are ready
   - Triggered automatically
   - Channels: Based on user preferences

### Integration Examples

#### Sending Smart Notifications

```swift
// When skin analysis is complete
await NotificationManager.shared.sendSmartNotification(for: .skinAnalysisComplete)

// When user misses a routine
await NotificationManager.shared.sendSmartNotification(for: .routineMissed)

// When user reaches a milestone
await NotificationManager.shared.sendSmartNotification(for: .progressMilestone(score: 85))
```

#### Scheduling Custom Notifications

```swift
let customTemplate = NotificationTemplate(
    id: "custom_reminder",
    type: .routineReminder,
    title: "Custom Reminder",
    body: "Your custom message here",
    icon: "star.fill",
    actionURL: "nura://custom-action",
    category: .reminder
)

await NotificationManager.shared.scheduleNotification(for: customTemplate, at: Date())
```

### User Preferences

Users can customize their notification experience through the NotificationsView:

- Enable/disable different notification types
- Set preferred delivery times
- Choose notification channels (push, email, SMS)
- Configure frequency settings

### Database Schema

The notification system uses the following Supabase tables:

- `notification_preferences`: User notification settings
- `scheduled_notifications`: Pending notification queue
- `notification_analytics`: Engagement tracking

### Email/SMS Integration

The system integrates with Supabase Edge Functions for email and SMS delivery:

- Email notifications via `send-email-notification` function
- SMS notifications via `send-sms-notification` function

## Setup

1. Clone the repository
2. Install dependencies
3. Configure Supabase credentials
4. Set up notification permissions
5. Build and run

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **Supabase**: Backend-as-a-Service for data and authentication
- **UserNotifications**: Native iOS notification framework
- **Combine**: Reactive programming for state management

## Contributing

Please read our contributing guidelines before submitting pull requests.

## License

This project is licensed under the MIT License. 