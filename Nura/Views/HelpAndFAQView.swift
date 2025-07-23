import SwiftUI

struct HelpAndFAQView: View {
    @State private var searchText: String = ""
    @State private var expandedIndex: Int? = nil
    let faqs: [FAQ] = [
        FAQ(question: "How does Nura analyze my skin?", answer: "Nura uses advanced AI and computer vision to analyze your skin from a selfie, looking at hydration, texture, and more. Results are personalized and private."),
        FAQ(question: "Is my data private?", answer: "Absolutely. Your data is encrypted and never sold. You control what is shared and can delete your data anytime in settings."),
        FAQ(question: "How do I change my plan?", answer: "Go to App Preferences > Subscription. You can upgrade, downgrade, or cancel your plan at any time."),
        FAQ(question: "Why do I see different results each scan?", answer: "Skin can change due to lighting, hydration, and other factors. For best results, scan in similar lighting and keep your skin clean."),
        FAQ(question: "How do I cancel my subscription?", answer: "You can cancel anytime from the Subscription section. Your access will continue until the end of your billing period."),
        FAQ(question: "What payment methods are supported?", answer: "We accept Visa, Mastercard, AmEx, and Discover. More options coming soon!")
    ]
    var filteredFAQs: [FAQ] {
        if searchText.trimmingCharacters(in: .whitespaces).isEmpty { return faqs }
        return faqs.filter { $0.question.localizedCaseInsensitiveContains(searchText) || $0.answer.localizedCaseInsensitiveContains(searchText) }
    }
    var body: some View {
        ZStack {
            Color(UIColor { $0.userInterfaceStyle == .dark ? .systemGray6 : UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1) }).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Help & FAQs")
                            .font(.largeTitle).fontWeight(.bold)
                            .padding(.top, 18)
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
                        .background(Color.white)
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
                        VStack(spacing: 14) {
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
                                Text("Our team usually replies within 1 business day.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 1)
                        Button(action: {
                            // Contact support action
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.headline)
                                Text("Contact Support")
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 24)
                            .background(
                                LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.purple.opacity(0.13), radius: 4, x: 0, y: 1)
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

struct FAQAccordion: View {
    let faq: FAQ
    let expanded: Bool
    let onTap: () -> Void
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
                .background(Color.white)
                .cornerRadius(14)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
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