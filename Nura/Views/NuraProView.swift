import SwiftUI

struct NuraProView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var expandedPro: Bool = true
    @State private var expandedProUnlimited: Bool = false
    @State private var expandedFree: Bool = false
    @State private var billingCycle: BillingCycle = .monthly
    @State private var showAllPro: Bool = false
    @Namespace private var toggleNS
    @State private var yearlyPulse: Bool = false
    @State private var selectedPlan: ComparePlan = .proUnlimited
    @State private var currentIndex: Int = 0
    @State private var navigateToPayment: Bool = false

    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? NuraColors.textSecondaryDark : .secondary
    }
    
    // Dropdown label for the currently selected plan
    private var selectedPlanLabel: Text {
        switch selectedPlan {
        case .proUnlimited:
            return Text("Nura Pro ") + Text("Unlimited").italic()
        case .pro:
            return Text("Nura Pro")
        case .free:
            return Text("Free")
        }
    }
    
    // Features to show for the selected plan
    private var featuresForSelectedPlan: [CompareFeature] {
        switch selectedPlan {
        case .proUnlimited:
            // Pro Unlimited = Pro features + Unlimited Scans
            return [CompareFeature.unlimitedScansOnlyFeature] + CompareFeature.proFeatures
        case .pro:
            return CompareFeature.proFeatures
        case .free:
            return CompareFeature.freeFeatures
        }
    }
    
    var body: some View {
        ZStack {
            ZStack {
                // Animated radial vignette behind the header
                RadialGradient(gradient: Gradient(colors: [Color.purple.opacity(0.22), Color.clear]), center: .top, startRadius: 60, endRadius: 420)
                    .opacity(0.85)
                    .scaleEffect(1.02)
                    .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: yearlyPulse)
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.10), Color.white]), startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            .ignoresSafeArea()
            VStack(spacing: 0) {
                // Ensure header sits above content
                Color.clear.frame(height: 0).zIndex(30)
                // Floating Title/Header (no background)
                VStack(spacing: 8) {
                    Text("Compare Plans")
                        .font(.largeTitle).fontWeight(.bold)
                        .padding(.top, 24)
                    Text("Choose the best Nura experience for you")
                        .font(.subheadline)
                        .foregroundColor(secondaryTextColor)
                        .padding(.bottom, 16)
                    // Card-based tier selector with swipe
                    TierCardCarousel(selectedPlan: $selectedPlan, currentIndex: $currentIndex)
                        .frame(height: 120)
                        .padding(.bottom, 8)
                    
                    // Catalog page indicators - positioned between tier carousel and description
                    HStack(spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.accentColor : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                        }
                    }
                    .padding(.bottom, 16)
                }
                // Interactive bullet point list for selected plan
                GeometryReader { geometry in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            InteractivePlanCard(selectedPlan: selectedPlan)
                                .padding(.horizontal, 16)
                        }
                        .padding(.bottom, 8)
                    }
                    .frame(maxHeight: geometry.size.height > 200 ? geometry.size.height - 200 : geometry.size.height) // Virtual boundary - 200pt from bottom (brought down)
                    .clipped()
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                let threshold: CGFloat = 50
                                let velocity = value.predictedEndTranslation.width - value.translation.width
                                
                                if abs(value.translation.width) > threshold || abs(velocity) > 100 {
                                    let direction = value.translation.width > 0 ? -1 : 1
                                    let newIndex = max(0, min(2, currentIndex + direction))
                                    let plans: [ComparePlan] = [.proUnlimited, .pro, .free]
                                    let newPlan = plans[newIndex]
                                    
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                        selectedPlan = newPlan
                                        currentIndex = newIndex
                                    }
                                }
                            }
                    )
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
                // Dynamic price based on active plan
                let activePlan: ComparePlan = selectedPlan
                ZStack {
                    if billingCycle == .monthly {
                        Text(activePlan == .free ? "Free" : (activePlan == .proUnlimited ? "$9.99/mo" : "$7.99/mo"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.accentColor)
                            .id("monthly")
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        if activePlan == .free {
                            Text("Free")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.accentColor)
                                .id("yearly-free")
                                .transition(.opacity.combined(with: .scale))
                        } else if activePlan == .proUnlimited {
                            HStack(spacing: 8) {
                                Text("$79.99/year")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.accentColor)
                                Text("Save 33%")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                    .shadow(color: Color.green.opacity(0.18), radius: 3, x: 0, y: 1)
                            }
                            .id("yearly-plus")
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
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.13), Color.blue.opacity(0.13)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .cornerRadius(12)
                .shadow(color: Color.purple.opacity(0.08), radius: 6, x: 0, y: 2)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: billingCycle)
                if selectedPlan != .free {
                    Button(action: {
                        navigateToPayment = true
                    }) {
                        HStack {
                            Spacer()
                            Text(selectedPlan == .proUnlimited ? "Go Pro Unlimited" : "Go Pro")
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
                }
                
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
            .sheet(isPresented: $navigateToPayment) {
                let paymentPlan: SubscriptionPlan? = {
                    switch selectedPlan {
                    case .pro:
                        return SubscriptionPlan.allPlans.first { $0.name == "Nura Pro" }
                    case .proUnlimited:
                        return SubscriptionPlan.allPlans.first { $0.name == "Nura Pro Unlimited" }
                    case .free:
                        return nil
                    }
                }()
                
                PaymentMethodsView(initialPlan: paymentPlan, initialBillingCycle: billingCycle)
            }

        }
    }
}

enum ComparePlan { case free, pro, proUnlimited }

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
                    Image(systemName: plan == .free ? "person.crop.circle" : "star.fill")
                        .font(.title)
                        .foregroundColor(plan == .free ? .gray : .yellow)
                        .shadow(color: plan == .free ? .clear : .yellow.opacity(0.3), radius: 6, x: 0, y: 0)
                    // Title with italics for "Unlimited"
                    let titleText: Text = {
                        switch plan {
                        case .pro: return Text("Nura Pro")
                        case .proUnlimited: return Text("Nura Pro ") + Text("Unlimited").italic()
                        case .free: return Text("Free")
                        }
                    }()
                    titleText
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
                    ForEach(displayFeatures, id: \.title) { feature in
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
            proTitle: "3 face scans per day",
            proDescription: "Scan up to three times daily.",
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
            freeTitle: "1 scan per day",
            freeDescription: "Track your skin with one scan daily.",
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
    static let proUnlimitedFeatures: [CompareFeature] = [
        .init(
            proTitle: "Unlimited face scans",
            proDescription: "Scan as often as you want, every day.",
            proIcon: "infinity.circle.fill", proIconColor: .pink,
            freeTitle: "", freeDescription: "", freeIcon: "", freeIconColor: .clear,
            title: "Unlimited Scans"
        ),
        .init(
            proTitle: "Unlimited skin analysis",
            proDescription: "Get full analysis on every scan, anytime.",
            proIcon: "waveform.path.ecg.rectangle", proIconColor: .purple,
            freeTitle: "", freeDescription: "", freeIcon: "", freeIconColor: .clear,
            title: "Unlimited Analysis"
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
        )
    ]
    // Single feature for Unlimited Scans to compose Pro Unlimited = Pro + this
    static let unlimitedScansOnlyFeature: CompareFeature = .init(
        proTitle: "Unlimited face scans",
        proDescription: "Scan as often as you want, every day.",
        proIcon: "infinity.circle.fill", proIconColor: .pink,
        freeTitle: "", freeDescription: "", freeIcon: "", freeIconColor: .clear,
        title: "Unlimited Scans"
    )
    func title(for plan: ComparePlan) -> String {
        (plan == .pro || plan == .proUnlimited) ? proTitle : freeTitle
    }
    func description(for plan: ComparePlan) -> String {
        (plan == .pro || plan == .proUnlimited) ? proDescription : freeDescription
    }
    func icon(for plan: ComparePlan) -> some View {
        let proLike = (plan == .pro || plan == .proUnlimited)
        let name = proLike ? proIcon : freeIcon
        let color = proLike ? proIconColor : freeIconColor
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

// MARK: - Card-Based Tier Carousel
struct TierCardCarousel: View {
    @Binding var selectedPlan: ComparePlan
    @Binding var currentIndex: Int
    @Environment(\.colorScheme) private var colorScheme
    
    private let plans: [ComparePlan] = [.proUnlimited, .pro, .free]
    
    var body: some View {
        GeometryReader { geometry in
            TabView(selection: $selectedPlan) {
                ForEach(plans, id: \.self) { plan in
                    TierCard(
                        plan: plan,
                        isSelected: plan == selectedPlan,
                        width: geometry.size.width * 0.85
                    )
                    .tag(plan)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            selectedPlan = plan
                            if let index = plans.firstIndex(of: plan) {
                                currentIndex = index
                            }
                        }
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 120)
            .onChange(of: selectedPlan) { oldValue, newValue in
                if let index = plans.firstIndex(of: newValue) {
                    currentIndex = index
                }
            }
        }
        .onAppear {
            currentIndex = plans.firstIndex(of: selectedPlan) ?? 0
        }
    }
}

// MARK: - Individual Tier Card
struct TierCard: View {
    let plan: ComparePlan
    let isSelected: Bool
    let width: CGFloat
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardColor: Color {
        switch plan {
        case .proUnlimited:
            return colorScheme == .dark ? Color(red: 0.12, green: 0.08, blue: 0.15) : Color(red: 0.98, green: 0.96, blue: 1.0)
        case .pro:
            return colorScheme == .dark ? Color(red: 0.15, green: 0.12, blue: 0.18) : Color(red: 0.96, green: 0.94, blue: 0.98)
        case .free:
            return colorScheme == .dark ? Color(red: 0.18, green: 0.16, blue: 0.20) : Color(red: 0.94, green: 0.92, blue: 0.96)
        }
    }
    
    private var accentColor: Color {
        switch plan {
        case .proUnlimited: return .purple
        case .pro: return .blue
        case .free: return .gray
        }
    }
    
    private var tierIcon: String {
        switch plan {
        case .proUnlimited: return "crown.fill"
        case .pro: return "star.fill"
        case .free: return "person.crop.circle"
        }
    }
    
    private var tierTitle: Text {
        switch plan {
        case .proUnlimited: 
            return Text("NURA PRO ") + Text("UNLIMITED").italic()
        case .pro: 
            return Text("NURA PRO")
        case .free: 
            return Text("FREE")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with icon and title
            VStack(spacing: 12) {
                Image(systemName: tierIcon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(accentColor)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
                
                tierTitle
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .frame(width: width, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardColor)
                .shadow(
                    color: Color.black.opacity(isSelected ? 0.15 : 0.08),
                    radius: isSelected ? 12 : 6,
                    x: 0,
                    y: isSelected ? 8 : 4
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    isSelected ? accentColor.opacity(0.3) : Color.gray.opacity(0.1),
                    lineWidth: isSelected ? 2 : 0.5
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Interactive Plan Card
struct InteractivePlanCard: View {
    let selectedPlan: ComparePlan
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedFeatures: Set<String> = []
    
    private var features: [(title: String, description: String, icon: String, color: Color)] {
        switch selectedPlan {
        case .free:
            return [
                ("1 scan per day", "Track your skin with one daily scan", "face.smiling", .blue),
                ("Dashboard access", "View your skin history and trends", "chart.bar.xaxis", .purple)
            ]
        case .pro:
            return [
                ("3 face scans per day", "Scan up to three times daily", "face.smiling", .blue),
                ("AI chat support", "Instant answers from Nura's AI skin expert", "bubble.left.and.bubble.right.fill", .purple),
                ("Dark mode", "Beautiful, eye-friendly dark theme", "moon.fill", .indigo),
                ("Daily routine (Apple Health)", "Personalized routines with Apple Health sync", "heart.text.square.fill", .red),
                ("Product matchmaking URLs", "Direct links to best-matched products", "link.circle.fill", .green),
                ("Premium chat support", "Priority help from our team", "message.fill", .orange)
            ]
        case .proUnlimited:
            return [
                ("Unlimited face scans", "Scan as often as you want, every day", "infinity.circle.fill", .pink),
                ("Everything Pro has", "All Pro features included", "checkmark.circle.fill", .green)
            ]
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(colorScheme == .dark ? Color.black.opacity(0.2) : Color.white.opacity(0.95))
            .background(BlurView(style: .systemThinMaterial))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.1) : Color.gray.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Interactive features list only (no header)
            featuresList
        }
        .background(cardBackground)
        .onAppear {
            startStaggeredAnimations()
        }
        .onChange(of: selectedPlan) { oldValue, newValue in
            resetAndRestartAnimations()
        }
    }
    
    private var planIcon: some View {
                               Image(systemName: selectedPlan == .free ? "person.crop.circle" : "star.fill")
                           .font(.title)
                           .foregroundColor(selectedPlan == .free ? .gray : .black)
                           .shadow(color: selectedPlan == .free ? .clear : .black.opacity(0.2), radius: 6, x: 0, y: 0)
    }
    
    private var planTitle: some View {
        Group {
            switch selectedPlan {
            case .pro:
                Text("Nura Pro")
            case .proUnlimited:
                Text("Nura Pro ") + Text("Unlimited").italic()
            case .free:
                Text("Free")
            }
        }
        .font(.title2).fontWeight(.bold)
        .foregroundColor(colorScheme == .dark ? NuraColors.textPrimaryDark : .primary)
    }
            
    private var featuresList: some View {
        VStack(spacing: 8) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                featureRow(feature, index: index)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
    }
    
    private func featureRow(_ feature: (title: String, description: String, icon: String, color: Color), index: Int) -> some View {
        let isAnimated = animatedFeatures.contains(feature.title)
        
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                featureIcon(feature, isAnimated: isAnimated)
                featureText(feature)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(featureBackground(feature, isAnimated: isAnimated))
            .contentShape(Rectangle())
            .onTapGesture {
                handleFeatureTap(feature)
            }
            
            if index < features.count - 1 {
                Divider()
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private func featureIcon(_ feature: (title: String, description: String, icon: String, color: Color), isAnimated: Bool) -> some View {
        Image(systemName: feature.icon)
            .font(.title3)
            .foregroundColor(feature.color)
            .frame(width: 32)
            .scaleEffect(isAnimated ? 1.1 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isAnimated)
    }
    
    private func featureText(_ feature: (title: String, description: String, icon: String, color: Color)) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(feature.title)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? NuraColors.textPrimaryDark : .primary)
            Text(feature.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func featureBackground(_ feature: (title: String, description: String, icon: String, color: Color), isAnimated: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isAnimated ? feature.color.opacity(0.08) : Color.clear)
            .animation(.easeInOut(duration: 0.3), value: isAnimated)
    }
    
    private func handleFeatureTap(_ feature: (title: String, description: String, icon: String, color: Color)) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        if animatedFeatures.contains(feature.title) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                _ = animatedFeatures.remove(feature.title)
            }
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                _ = animatedFeatures.insert(feature.title)
            }
        }
        
        // Auto-dismiss after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                _ = animatedFeatures.remove(feature.title)
            }
        }
    }
    
    private func startStaggeredAnimations() {
        for (index, feature) in features.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    _ = animatedFeatures.insert(feature.title)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1 + 1.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    _ = animatedFeatures.remove(feature.title)
                }
            }
        }
    }
    
    private func resetAndRestartAnimations() {
        animatedFeatures.removeAll()
        startStaggeredAnimations()
    }
}