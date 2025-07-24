import SwiftUI

struct HelpAndFAQView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText: String = ""
    @State private var expandedIndex: Int? = nil
    @State private var showingContactSupport = false
    let faqs: [FAQ] = [
        FAQ(question: "How does Nura analyze my skin?", answer: "Nura uses advanced AI and computer vision to analyze your skin from a selfie, looking at hydration, texture, and more. Results are personalized and private."),
        FAQ(question: "Is my data private?", answer: "Absolutely. Your data is encrypted and never sold. You control what is shared and can delete your data anytime in settings."),
        FAQ(question: "How do I change my plan?", answer: "Go to App Preferences > Subscription. You can upgrade, downgrade, or cancel your plan at any time."),
        FAQ(question: "Why do I see different results each scan?", answer: "Skin can change due to lighting, hydration, and other factors. For best results, scan in similar lighting and keep your skin clean."),
        FAQ(question: "How do I cancel my subscription?", answer: "You can cancel anytime from the Subscription section. Your access will continue until the end of your billing period."),
        FAQ(question: "What payment methods are supported?", answer: "We accept Visa, Mastercard, AmEx, and Discover. More options coming soon!"),
        // Added FAQs for deeper product understanding and support
        FAQ(question: "What is Nura Pro?", answer: "Nura Pro unlocks advanced features, personalized routines, and premium support for your skincare journey."),
        FAQ(question: "How do I contact support?", answer: "Tap 'Contact Support' at the bottom of this page or in your Profile. Our team replies within 1 business day."),
        FAQ(question: "Can I use Nura if I have sensitive skin?", answer: "Yes! Nura is designed for all skin types. Our recommendations are always gentle and customizable."),
        FAQ(question: "Does Nura work offline?", answer: "Some features require internet for AI analysis, but you can view your routine and history offline."),
        FAQ(question: "How do I update my personal information?", answer: "Go to Profile > Personal Information to update your name, email, or phone number."),
        FAQ(question: "How do I delete my account?", answer: "You can permanently delete your account and all data in Profile > Privacy & Security. This action cannot be undone."),
        FAQ(question: "What happens to my data if I uninstall the app?", answer: "Your data remains securely stored. To delete it, use the in-app delete option before uninstalling."),
        FAQ(question: "How do I rate the app or leave feedback?", answer: "Go to Profile > Rate App to share your experience or suggestions. We love hearing from you!"),
        FAQ(question: "Can I export my skin analysis data?", answer: "Yes, request a data export in Profile > Privacy & Security. We'll email you a download link."),
        FAQ(question: "How do I enable dark mode?", answer: "Go to Profile > App Preferences and select your preferred appearance mode."),
        FAQ(question: "What is the 'skin-confidence guarantee'?", answer: "If you’re not satisfied with Nura Pro, you can cancel anytime during your free trial—no questions asked."),
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