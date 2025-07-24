import SwiftUI

struct NuraProView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedPro: Bool = true
    @State private var expandedFree: Bool = false
    @State private var billingCycle: BillingCycle = .monthly
    @State private var showAllPro: Bool = false
    @Namespace private var toggleNS
    @State private var yearlyPulse: Bool = false
    private var secondaryTextColor: Color {
        colorScheme == .dark ? NuraColors.textSecondaryDark : .secondary
    }
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.white]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                // Floating Title/Header (no background)
                VStack(spacing: 4) {
                    Text("Compare Plans")
                        .font(.largeTitle).fontWeight(.bold)
                        .padding(.top, 24)
                    Text("Choose the best Nura experience for you")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                        .padding(.bottom, 18)
                }
                // Both cards always visible, with partial expansion
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        CompareContactCard(
                            plan: .pro,
                            expanded: expandedPro,
                            onTap: { withAnimation(.spring()) {
                                expandedPro = !expandedPro
                                if expandedPro { expandedFree = false }
                            } },
                            billingCycle: $billingCycle,
                            highlight: true,
                            comparison: true,
                            otherExpanded: expandedFree,
                            features: CompareFeature.proFeatures,
                            showAll: $showAllPro,
                            showMoreLimit: 4,
                            commentFont: .footnote,
                            commentLineLimit: 2,
                            tight: true,
                            showMoreEnabled: true
                        )
                        .padding(.horizontal, 16)
                        .zIndex(expandedPro ? 2 : 1)
                        CompareContactCard(
                            plan: .free,
                            expanded: expandedFree,
                            onTap: { withAnimation(.spring()) {
                                expandedFree = !expandedFree
                                if expandedFree { expandedPro = false }
                            } },
                            billingCycle: .constant(.monthly),
                            highlight: false,
                            comparison: true,
                            otherExpanded: expandedPro,
                            features: CompareFeature.freeFeatures,
                            showAll: .constant(true),
                            showMoreLimit: CompareFeature.freeFeatures.count,
                            commentFont: .footnote,
                            commentLineLimit: 2,
                            tight: true,
                            showMoreEnabled: false
                        )
                        .padding(.horizontal, 16)
                        .zIndex(expandedFree ? 2 : 1)
                        // Only one background icon/text, centered between cards and pricing
                        if !expandedPro && !expandedFree {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.purple.opacity(0.10))
                                        .frame(width: 120, height: 120)
                                        .blur(radius: 0.5)
                                    Image(systemName: "rectangle.3.offgrid.bubble.left")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(Color.purple.opacity(0.25))
                                }
                                Text("Compare plans and unlock your best skin")
                                    .font(.subheadline)
                                    .foregroundColor(secondaryTextColor)
                            }
                            .frame(maxWidth: .infinity)
                            .offset(y: 40) // Move the SF Symbol chunk lower
                        }
                        Spacer(minLength: 120) // More space for floater
                    }
                    .padding(.bottom, 8)
                }
                // Remove the pricing row from here
            }
            // Floating Pricing Row Overlay
            VStack(spacing: 4) {
                HStack(spacing: 12) {
                    ZStack {
                        if billingCycle == .monthly {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue.opacity(0.13))
                                .shadow(color: Color.blue.opacity(0.10), radius: 4, x: 0, y: 1)
                                .frame(height: 32)
                                .transition(.opacity)
                        }
                        Text("Monthly")
                            .fontWeight(.semibold)
                            .foregroundColor(billingCycle == .monthly ? .accentColor : secondaryTextColor)
                            .frame(minWidth: 80)
                            .frame(height: 32)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    billingCycle = .monthly
                                }
                            }
                    }
                    ZStack {
                        if billingCycle == .yearly {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.blue.opacity(0.13))
                                .shadow(color: Color.blue.opacity(0.10), radius: 4, x: 0, y: 1)
                                .frame(height: 32)
                                .scaleEffect(yearlyPulse ? 1.08 : 1.0)
                                .opacity(yearlyPulse ? 1.0 : 0.92)
                                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: yearlyPulse)
                                .transition(.opacity)
                        }
                        Text("Yearly")
                            .fontWeight(.semibold)
                            .foregroundColor(billingCycle == .yearly ? .accentColor : secondaryTextColor)
                            .frame(minWidth: 80)
                            .frame(height: 32)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    billingCycle = .yearly
                                }
                            }
                    }
                }
                .frame(height: 32)
                .padding(.horizontal, 24)
                .padding(.top, 2)
                ZStack {
                    if billingCycle == .monthly {
                        Text("$7.99/mo")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                            .id("monthly")
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        HStack(spacing: 8) {
                            Text("$59.99/year")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.accentColor)
                            Text("Save 35%")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 8)
                                .background(Color.green)
                                .cornerRadius(8)
                                .shadow(color: Color.green.opacity(0.18), radius: 3, x: 0, y: 1)
                        }
                        .id("yearly")
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.13), Color.blue.opacity(0.13)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(12)
                .shadow(color: Color.purple.opacity(0.08), radius: 6, x: 0, y: 2)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: billingCycle)
                Button(action: {
                    // Upgrade logic here
                }) {
                    HStack {
                        Spacer()
                        Text("Go Pro")
                            .fontWeight(.bold)
                            .font(.title3)
                            .padding(.vertical, 10)
                        Spacer()
                    }
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: Color.purple.opacity(0.18), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
                // Add the two Text views here, below the button
                Text("7-day free trial. Cancel anytime.")
                    .font(.footnote)
                    .foregroundColor(secondaryTextColor)
                Text("100% skin-confidence guarantee.")
                    .font(.caption2)
                    .foregroundColor(secondaryTextColor)
            }
            .background(BlurView(style: .systemMaterial).opacity(0.98))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: 400)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                yearlyPulse = true
            }
        }
    }
}

enum ComparePlan { case free, pro }

struct CompareContactCard: View {
    let plan: ComparePlan
    let expanded: Bool
    let onTap: () -> Void
    @Binding var billingCycle: BillingCycle
    let highlight: Bool
    let comparison: Bool
    let otherExpanded: Bool
    let features: [CompareFeature]
    @Binding var showAll: Bool
    let showMoreLimit: Int
    let commentFont: Font
    let commentLineLimit: Int
    let tight: Bool
    let showMoreEnabled: Bool
    @Environment(\.colorScheme) private var colorScheme
    private var cardBackground: Color {
        colorScheme == .dark ? NuraColors.cardDark : .white
    }
    private var titleTextColor: Color {
        colorScheme == .dark ? NuraColors.textPrimaryDark : .primary
    }
    private var secondaryTextColor: Color {
        colorScheme == .dark ? NuraColors.textSecondaryDark : .secondary
    }
    private var freeCardBackground: Color {
        colorScheme == .dark ? Color(red: 0.22, green: 0.25, blue: 0.22) : Color(red: 0.93, green: 0.95, blue: 0.93)
    }
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: plan == .pro ? "star.fill" : "person.crop.circle")
                        .font(.title)
                        .foregroundColor(plan == .pro ? .yellow : .gray)
                        .shadow(color: plan == .pro ? .yellow.opacity(0.3) : .clear, radius: 6, x: 0, y: 0)
                    Text(plan == .pro ? "Nura Pro" : "Free")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(titleTextColor)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.22), value: expanded)
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 18)
                .background(plan == .free ? freeCardBackground : (highlight ? Color.purple.opacity(0.07) : Color.gray.opacity(0.07)))
                .cornerRadius(18)
                .shadow(color: highlight ? Color.purple.opacity(0.08) : Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            if expanded {
                VStack(spacing: tight ? 0 : 4) {
                    let displayFeatures = showAll ? features : Array(features.prefix(showMoreLimit))
                    ForEach(displayFeatures, id: \ .title) { feature in
                        HStack(alignment: .center, spacing: 0) {
                            feature.icon(for: plan)
                                .frame(width: 38, alignment: .center)
                                .padding(.trailing, 12)
                            VStack(alignment: .leading, spacing: tight ? 0 : 2) {
                                Text(feature.title(for: plan))
                                    .font(.headline)
                                    .foregroundColor(titleTextColor)
                                Text(feature.description(for: plan))
                                    .font(commentFont)
                                    .foregroundColor(secondaryTextColor)
                                    .lineLimit(commentLineLimit)
                                    .truncationMode(.tail)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, tight ? 8 : 12)
                        .padding(.horizontal, 16)
                        if feature.title != displayFeatures.last?.title {
                            Divider().padding(.horizontal, 8)
                        }
                    }
                    if showMoreEnabled && features.count > showMoreLimit {
                        Button(action: { withAnimation(.spring()) { showAll.toggle() } }) {
                            Text(showAll ? "Show less" : "Show more")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.accentColor)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                        }
                        .background(Color.clear)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(cardBackground)
                .cornerRadius(18)
                .shadow(color: plan == .free ? Color.black.opacity(0.01) : Color.black.opacity(0.04), radius: plan == .free ? 2 : 6, x: 0, y: 1)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: 340)
        .padding(.vertical, 6)
    }
}

struct CompareFeature {
    let proTitle: String
    let proDescription: String
    let proIcon: String
    let proIconColor: Color
    let freeTitle: String
    let freeDescription: String
    let freeIcon: String
    let freeIconColor: Color
    let title: String // for ForEach id only
    static let proFeatures: [CompareFeature] = [
        .init(
            proTitle: "Unlimited face scans",
            proDescription: "Scan as often as you want, every day.",
            proIcon: "face.smiling", proIconColor: .blue,
            freeTitle: "", freeDescription: "", freeIcon: "", freeIconColor: .clear,
            title: "Face Scans"
        ),
        .init(
            proTitle: "AI chat support",
            proDescription: "Instant answers from Nura's AI skin expert.",
            proIcon: "bubble.left.and.bubble.right.fill", proIconColor: .purple,
            freeTitle: "", freeDescription: "", freeIcon: "", freeIconColor: .clear,
            title: "AI Chat"
        ),
        .init(
            proTitle: "Dark mode",
            proDescription: "Beautiful, eye-friendly dark theme.",
            proIcon: "moon.fill", proIconColor: .indigo,
            freeTitle: "", freeDescription: "", freeIcon: "", freeIconColor: .clear,
            title: "Dark Mode"
        ),
        .init(
            proTitle: "Daily routine (Apple Health)",
            proDescription: "Personalized routines with Apple Health sync.",
            proIcon: "heart.text.square.fill", proIconColor: .red,
            freeTitle: "", freeDescription: "", freeIcon: "", freeIconColor: .clear,
            title: "Routine"
        ),
        .init(
            proTitle: "Product matchmaking URLs",
            proDescription: "Direct links to best-matched products.",
            proIcon: "link.circle.fill", proIconColor: .green,
            freeTitle: "", freeDescription: "", freeIcon: "", freeIconColor: .clear,
            title: "Product Matchmaking"
        ),
        .init(
            proTitle: "Premium chat support",
            proDescription: "Priority help from our team.",
            proIcon: "message.fill", proIconColor: .blue,
            freeTitle: "", freeDescription: "", freeIcon: "", freeIconColor: .clear,
            title: "Support"
        )
    ]
    static let freeFeatures: [CompareFeature] = [
        .init(
            proTitle: "", proDescription: "", proIcon: "", proIconColor: .clear,
            freeTitle: "3 scans per day",
            freeDescription: "Track your skin with up to 3 scans daily.",
            freeIcon: "face.smiling", freeIconColor: .gray,
            title: "Face Scans"
        ),
        .init(
            proTitle: "", proDescription: "", proIcon: "", proIconColor: .clear,
            freeTitle: "Dashboard access",
            freeDescription: "View your skin history and trends.",
            freeIcon: "chart.bar.xaxis", freeIconColor: .gray,
            title: "Dashboard"
        )
    ]
    func title(for plan: ComparePlan) -> String {
        plan == .pro ? proTitle : freeTitle
    }
    func description(for plan: ComparePlan) -> String {
        plan == .pro ? proDescription : freeDescription
    }
    func icon(for plan: ComparePlan) -> some View {
        let name = plan == .pro ? proIcon : freeIcon
        let color = plan == .pro ? proIconColor : freeIconColor
        if name.isEmpty { return AnyView(EmptyView()) }
        return AnyView(
            Image(systemName: name)
                .font(.title3)
                .foregroundColor(color)
                .padding(8)
                .background(color.opacity(0.09))
                .clipShape(Circle())
        )
    }
}

enum BillingCycle {
    case monthly, yearly
}

// MARK: - Glow Modifier
extension View {
    func glow(color: Color, radius: CGFloat = 20) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.4), radius: radius / 2)
            .shadow(color: color.opacity(0.2), radius: radius)
    }
}

#Preview {
    NuraProView()
} 

// MARK: - BlurView for background blur effect
import UIKit
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
} 