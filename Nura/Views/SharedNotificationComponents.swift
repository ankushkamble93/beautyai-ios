import SwiftUI

// MARK: - Shared Notification Components

struct NotificationTypeRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    let icon: String
    let frequency: NotificationSetting.NotificationFrequency
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(NuraColors.secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(frequency.displayText)
                    .font(.caption2)
                    .foregroundColor(NuraColors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(NuraColors.primary.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: NuraColors.primary))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            isOn.toggle()
        }
    }
}

struct TimePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedTime: Date
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose your preferred time for daily reminders")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding()
                
                DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
                
                Spacer()
            }
            .navigationTitle("Set Time")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    onSave()
                    dismiss()
                }
            )
        }
    }
}

struct SuccessBanner: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct TestButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(NuraColors.primary)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(NuraColors.primary.opacity(0.1))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension NotificationSetting.NotificationFrequency {
    var displayText: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .never: return "Never"
        }
    }
} 