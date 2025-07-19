import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSubscription = false
    @State private var showingSettings = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    ProfileHeaderView()
                    
                    // Quick actions
                    QuickActionsView()
                    
                    // Settings sections
                    SettingsSectionView()
                    
                    // Subscription section
                    SubscriptionSectionView()
                    
                    // Support section
                    SupportSectionView()
                    
                    // Sign out button
                    SignOutButton()
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingHelp) {
                HelpView()
            }
        }
    }
}

struct ProfileHeaderView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 15) {
            // Profile image
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.pink]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
            
            // User info
            VStack(spacing: 5) {
                Text(authManager.currentUser?.displayName ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(authManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Member since
            Text("Member since \(formatDate(authManager.currentUser?.metadata.creationDate ?? Date()))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct QuickActionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionCard(
                    title: "New Analysis",
                    subtitle: "Upload photos",
                    icon: "camera.fill",
                    color: .purple
                ) {
                    // Navigate to analysis
                }
                
                QuickActionCard(
                    title: "Chat with AI",
                    subtitle: "Get advice",
                    icon: "message.fill",
                    color: .blue
                ) {
                    // Navigate to chat
                }
                
                QuickActionCard(
                    title: "View Progress",
                    subtitle: "Track results",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .green
                ) {
                    // Navigate to progress
                }
                
                QuickActionCard(
                    title: "Routine",
                    subtitle: "Daily steps",
                    icon: "list.bullet",
                    color: .orange
                ) {
                    // Navigate to routine
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsSectionView: View {
    @State private var showingSettings = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Personal Information",
                    subtitle: "Update your profile",
                    icon: "person.circle.fill",
                    color: .blue
                ) {
                    showingSettings = true
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Notifications",
                    subtitle: "Manage alerts",
                    icon: "bell.fill",
                    color: .orange
                ) {
                    // Navigate to notifications
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Privacy & Security",
                    subtitle: "Data and privacy settings",
                    icon: "lock.fill",
                    color: .green
                ) {
                    // Navigate to privacy
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "App Preferences",
                    subtitle: "Customize your experience",
                    icon: "gearshape.fill",
                    color: .gray
                ) {
                    // Navigate to preferences
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

struct SettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubscriptionSectionView: View {
    @State private var showingSubscription = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Subscription")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "BeautyAI Premium",
                    subtitle: "Unlock advanced features",
                    icon: "crown.fill",
                    color: .yellow
                ) {
                    showingSubscription = true
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Payment Methods",
                    subtitle: "Manage billing",
                    icon: "creditcard.fill",
                    color: .purple
                ) {
                    // Navigate to payment methods
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Billing History",
                    subtitle: "View past invoices",
                    icon: "doc.text.fill",
                    color: .blue
                ) {
                    // Navigate to billing history
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
    }
}

struct SupportSectionView: View {
    @State private var showingHelp = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Support")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Help & FAQ",
                    subtitle: "Find answers",
                    icon: "questionmark.circle.fill",
                    color: .blue
                ) {
                    showingHelp = true
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Contact Support",
                    subtitle: "Get in touch",
                    icon: "envelope.fill",
                    color: .green
                ) {
                    // Open email or contact form
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "Rate App",
                    subtitle: "Share your feedback",
                    icon: "star.fill",
                    color: .yellow
                ) {
                    // Open App Store rating
                }
                
                Divider()
                    .padding(.leading, 50)
                
                SettingsRow(
                    title: "About",
                    subtitle: "Version 1.0.0",
                    icon: "info.circle.fill",
                    color: .gray
                ) {
                    // Show about page
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }
}

struct SignOutButton: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        Button(action: {
            authManager.signOut()
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .foregroundColor(.red)
            .cornerRadius(12)
        }
    }
}

// Placeholder views for sheets
struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("BeautyAI Premium")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Unlock advanced features and personalized recommendations")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Customize your BeautyAI experience")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Help & FAQ")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Find answers to common questions")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
} 