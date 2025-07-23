import SwiftUI

struct NuraProView: View {
    @State private var billingCycle: BillingCycle = .monthly
    @Namespace private var toggleNS
    @State private var animateConfetti = false
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.12), Color.white]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 4) {
                        HStack(spacing: 10) {
                            Text("Nura Pro")
                                .font(.largeTitle).fontWeight(.bold)
                                .overlay(
                                    ZStack {
                                        if animateConfetti {
                                            ForEach(0..<12) { i in
                                                Circle()
                                                    .fill(Color.accentColor.opacity(0.18))
                                                    .frame(width: 8, height: 8)
                                                    .offset(x: CGFloat.random(in: -30...30), y: CGFloat.random(in: -30...30))
                                                    .opacity(Double.random(in: 0.5...1))
                                                    .animation(.easeOut(duration: 1.2).delay(Double(i) * 0.05), value: animateConfetti)
                                            }
                                        }
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .shadow(color: .yellow.opacity(0.5), radius: 8, x: 0, y: 0)
                                            .scaleEffect(1.2)
                                            .offset(x: 38, y: -18)
                                            .glow(color: .yellow, radius: 8)
                                    }, alignment: .topTrailing
                                )
                        }
                        .padding(.top, 18)
                        Text("Unlock your best skin, personalized.")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .onAppear { animateConfetti = true }
                    // Benefits
                    VStack(spacing: 10) {
                        ForEach(ProBenefit.all, id: \ .title) { benefit in
                            BenefitCard(benefit: benefit)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 4)
                    // Comparison Table
                    ComparisonTableView(billingCycle: $billingCycle)
                        .padding(.horizontal, 0)
                    // Pricing Section
                    PricingSection(billingCycle: $billingCycle)
                        .padding(.horizontal, 0)
                    // Trial/Guarantee
                    VStack(spacing: 2) {
                        Text("7-day free trial. Cancel anytime.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("100% skin-confidence guarantee.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 18)
                }
            }
        }
    }
}

// MARK: - Benefit Card
struct BenefitCard: View {
    let benefit: ProBenefit
    @State private var appear = false
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: benefit.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .padding(12)
                .background(Color.accentColor.opacity(0.09))
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(benefit.title)
                    .font(.headline)
                Text(benefit.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 30)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85).delay(Double.random(in: 0.05...0.18))) {
                appear = true
            }
        }
    }
}

struct ProBenefit {
    let icon: String
    let title: String
    let description: String
    static let all: [ProBenefit] = [
        .init(icon: "checkmark.shield.fill", title: "Unlimited skin scans", description: "Scan anytime — no limits, no delays."),
        .init(icon: "sparkles", title: "AI-powered routine generator", description: "Get a daily routine tailored to your skin."),
        .init(icon: "wand.and.stars", title: "Personalized product recommendations", description: "Discover products that match your unique needs."),
        .init(icon: "star.circle.fill", title: "Early access to new features", description: "Be the first to try new Nura tools."),
        .init(icon: "message.fill", title: "Premium chat support", description: "Get priority help from our team.")
    ]
}

// MARK: - Comparison Table
struct ComparisonTableView: View {
    @Binding var billingCycle: BillingCycle
    let features: [ComparisonFeature] = [
        .init(title: "Skin Scans", free: .text("Limited"), pro: .text("Unlimited")),
        .init(title: "Routine Builder", free: .icon("xmark.circle", .red), pro: .icon("checkmark.circle.fill", .green)),
        .init(title: "Support", free: .icon("envelope", .gray), pro: .icon("message.fill", .blue)),
        .init(title: "Product Matchmaking", free: .icon("xmark.circle", .red), pro: .icon("checkmark.circle.fill", .green))
    ]
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                Text("Free")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer(minLength: 0)
                Text("")
                    .frame(width: 40)
                Spacer(minLength: 0)
                Text("Pro")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(12)
                    .shadow(color: Color.purple.opacity(0.13), radius: 4, x: 0, y: 1)
                Spacer()
            }
            .padding(.vertical, 8)
            ForEach(features) { feature in
                HStack(spacing: 0) {
                    Spacer()
                    feature.freeView
                        .frame(width: 80)
                    Spacer(minLength: 0)
                    Text(feature.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(width: 120)
                        .multilineTextAlignment(.center)
                    Spacer(minLength: 0)
                    feature.proView
                        .frame(width: 80)
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.95))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.02), radius: 2, x: 0, y: 1)
                .padding(.vertical, 2)
                if feature.id != features.last?.id {
                    Divider().padding(.horizontal, 24)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.vertical, 10)
    }
}

enum ComparisonCell {
    case text(String)
    case icon(String, Color)
    @ViewBuilder var view: some View {
        switch self {
        case .text(let str):
            Text(str)
                .font(.subheadline)
                .foregroundColor(.secondary)
        case .icon(let name, let color):
            Image(systemName: name)
                .font(.title3)
                .foregroundColor(color)
        }
    }
}

extension ComparisonFeature {
    var freeView: some View { free.view }
    var proView: some View { pro.view }
}

struct ComparisonFeature: Identifiable {
    let id = UUID()
    let title: String
    let free: ComparisonCell
    let pro: ComparisonCell
}

// MARK: - Pricing Section
struct PricingSection: View {
    @Binding var billingCycle: BillingCycle
    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                Text("Monthly")
                    .fontWeight(billingCycle == .monthly ? .bold : .regular)
                    .foregroundColor(billingCycle == .monthly ? .accentColor : .secondary)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            billingCycle = .monthly
                        }
                    }
                Spacer()
                if billingCycle == .yearly {
                    Text("Save 35%")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 16)
                        .background(Color.green)
                        .cornerRadius(12)
                        .shadow(color: Color.green.opacity(0.18), radius: 4, x: 0, y: 1)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
                Text("Yearly")
                    .fontWeight(billingCycle == .yearly ? .bold : .regular)
                    .foregroundColor(billingCycle == .yearly ? .accentColor : .secondary)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            billingCycle = .yearly
                        }
                    }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            // Pricing Card
            VStack(spacing: 8) {
                if billingCycle == .monthly {
                    Text("$7.99/mo")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                } else {
                    Text("$59.99/year")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.13), Color.blue.opacity(0.13)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .cornerRadius(16)
            .shadow(color: Color.purple.opacity(0.08), radius: 8, x: 0, y: 2)
            // CTA Button
            Button(action: {
                // Upgrade logic here
            }) {
                HStack {
                    Spacer()
                    Text("Go Pro")
                        .fontWeight(.bold)
                        .font(.title3)
                        .padding(.vertical, 16)
                    Spacer()
                }
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: Color.purple.opacity(0.18), radius: 6, x: 0, y: 2)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.vertical, 10)
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