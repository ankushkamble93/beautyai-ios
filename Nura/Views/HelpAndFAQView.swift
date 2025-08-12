import SwiftUI

struct HelpAndFAQView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText: String = ""
    @State private var expandedIndex: Int? = nil
    @State private var showingContactSupport = false
    let faqs: [FAQ] = [
        // Core Features
        FAQ(question: "How does Nura analyze my skin?", answer: "Nura uses advanced AI and computer vision to analyze your skin from photos, tracking hydration, texture, and skin concerns. Our AI provides personalized insights and recommendations based on your unique skin profile."),
        FAQ(question: "What are the different subscription plans?", answer: "Nura offers three plans: Free (basic tracking), Nura Pro ($7.99/month or $59.99/year), and Nura Pro Unlimited ($9.99/month or $79.99/year). Yearly plans save up to 35% compared to monthly billing."),
        FAQ(question: "What features are included in each plan?", answer: "Free: 1 scan per day, basic dashboard. Nura Pro: 3 scans per day, AI chat support, dark mode, Apple Health integration, product matchmaking. Nura Pro Unlimited: Unlimited scans, expert consultations, custom formulations, exclusive products."),
        
        // Payment & Billing
        FAQ(question: "What payment methods are supported?", answer: "We accept Apple Pay for quick, secure payments, plus all major credit cards including Visa, Mastercard, American Express, and Discover. You can also save cards for future payments."),
        FAQ(question: "How do I change my subscription plan?", answer: "Go to Profile > Subscription to upgrade, downgrade, or switch between monthly and yearly billing. Changes take effect at your next billing cycle."),
        FAQ(question: "How do I cancel my subscription?", answer: "You can cancel anytime from Profile > Subscription. Your access continues until the end of your current billing period. No cancellation fees apply."),
        FAQ(question: "Where can I view my billing history?", answer: "Access your complete billing history in Profile > Billing History. Download invoices, view payment status, and filter by date ranges."),
        FAQ(question: "What is the skin-confidence guarantee?", answer: "Try Nura Pro risk-free with our 7-day free trial. Cancel anytime during the trial period—no questions asked. We're confident you'll love the results."),
        
        // Privacy & Data
        FAQ(question: "Is my data private and secure?", answer: "Absolutely. Your data is encrypted, never sold to third parties, and stored securely. You control what's shared and can delete your data anytime in Profile > Privacy & Security."),
        FAQ(question: "Can I export my skin analysis data?", answer: "Yes, request a complete data export in Profile > Privacy & Security. We'll email you a secure download link with all your skin analysis history and personal data."),
        FAQ(question: "What happens to my data if I delete my account?", answer: "When you delete your account, all personal data, skin analysis history, and preferences are permanently removed from our servers. This action cannot be undone."),
        
        // App Features
        FAQ(question: "How do I use the skin diary feature?", answer: "Track your skin journey daily with photos, notes, and mood tracking. The diary helps identify patterns and track progress over time. Available in all plans."),
        FAQ(question: "What is the AI chat support?", answer: "Get instant answers from our AI skin expert. Ask about ingredients, routines, or skin concerns. Available 24/7 for Pro and Pro Unlimited users."),
        FAQ(question: "How does the routine feature work?", answer: "Get personalized daily routines based on your skin analysis. Sync with Apple Health for seamless tracking. Routines adapt based on your skin changes and preferences."),
        FAQ(question: "Can I use Nura with sensitive skin?", answer: "Yes! Nura is designed for all skin types, including sensitive skin. Our AI provides gentle recommendations and you can customize routines to avoid irritants."),
        FAQ(question: "How do I enable dark mode?", answer: "Go to Profile > App Preferences and select your preferred appearance. Choose between light, dark, or automatic mode that follows your device settings."),
        
        // Technical Support
        FAQ(question: "Does Nura work offline?", answer: "Core features like viewing your routine, diary entries, and saved data work offline. AI analysis and chat support require an internet connection for real-time processing."),
        FAQ(question: "How do I update my personal information?", answer: "Go to Profile > Personal Information to update your name, email, phone number, or profile photo. Changes are saved automatically."),
        FAQ(question: "How do I contact support?", answer: "Tap 'Contact Support' at the bottom of this page or in your Profile. Our team responds within 1 business day. Pro users get priority support."),
        FAQ(question: "How do I rate the app or leave feedback?", answer: "Go to Profile > Rate App to share your experience, suggestions, or report issues. We love hearing from our community and use feedback to improve Nura."),
        
        // Troubleshooting
        FAQ(question: "Why do I see different results each scan?", answer: "Skin appearance can vary due to lighting, hydration, time of day, and other factors. For consistent results, scan in similar lighting conditions and keep your skin clean."),
        FAQ(question: "What if my payment fails?", answer: "If a payment fails, we'll notify you and retry within 24 hours. You can update your payment method in Profile > Subscription. Your access continues during this period."),
        FAQ(question: "How do I switch between monthly and yearly billing?", answer: "Go to Profile > Subscription and select your preferred billing cycle. Yearly plans offer significant savings and you can switch anytime."),
    ]
    var filteredFAQs: [FAQ] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty { return faqs }
        return faqs.filter { $0.question.localizedCaseInsensitiveContains(searchText) || $0.answer.localizedCaseInsensitiveContains(searchText) }
    }
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.white]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            // Faint oversized SF Symbol in background
            VStack {
                Spacer()
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320, height: 320)
                    .foregroundColor(Color.purple.opacity(0.07))
                    .blur(radius: 0.5)
                    .offset(y: 80)
            }
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Help & FAQs")
                            .font(.largeTitle).fontWeight(.bold)
                            .padding(.top, 18)
                        // Colored underline accent
                        Rectangle()
                            .fill(Color.purple)
                            .frame(width: 56, height: 4)
                            .cornerRadius(2)
                            .opacity(0.18)
                            .padding(.bottom, 2)
                        Text("How can we support you today?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Search FAQs", text: $searchText)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        .padding(12)
                        .background(cardBackground)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                        .padding(.top, 8)
                        .padding(.horizontal, 8)
                    }
                    .padding(.bottom, 18)
                    // FAQ List
                    if filteredFAQs.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.gray.opacity(0.3))
                            Text("No results found. Try a different keyword or contact support.")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 60)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(filteredFAQs.indices, id: \ .self) { idx in
                                FAQAccordion(
                                    faq: filteredFAQs[idx],
                                    expanded: expandedIndex == idx,
                                    onTap: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                            expandedIndex = expandedIndex == idx ? nil : idx
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 24)
                    }
                    // Support Section
                    VStack(spacing: 12) {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Still need help?")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Our team usually replies within 1 business day.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(cardBackground)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                        Button(action: {
                            showingContactSupport = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.headline)
                                Text("Contact Support")
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.purple.opacity(0.22), radius: 6, x: 0, y: 2)
                        }
                        .padding(.top, 2)
                        .sheet(isPresented: $showingContactSupport) {
                            ContactSupportView()
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

struct FAQAccordion: View {
    @Environment(\.colorScheme) private var colorScheme
    let faq: FAQ
    let expanded: Bool
    let onTap: () -> Void
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.accentColor)
                    Text(faq.question)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .foregroundColor(.gray)
                        .animation(.easeInOut(duration: 0.22), value: expanded)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    Text(faq.answer)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 2)
                }
                .padding(.horizontal, 16)
                .background(cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.purple.opacity(0.12), lineWidth: 1)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.purple.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.purple.opacity(0.04), radius: 2, x: 0, y: 1)
        .animation(.easeInOut(duration: 0.22), value: expanded)
    }
}

struct FAQ {
    let question: String
    let answer: String
}

#Preview {
    HelpAndFAQView()
} 