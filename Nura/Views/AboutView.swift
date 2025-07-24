import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showEasterEgg = false
    @State private var nuraTapCount = 0
    @Namespace private var logoNS
    private let craftedIcons = ["huggingface", "stripe", "openai"]
    private var accent: Color { Color(red: 0.93, green: 0.80, blue: 0.80) } // blush
    private var offWhite: Color { Color(red: 0.98, green: 0.97, blue: 0.95) }
    private var charcoal: Color { Color(red: 0.13, green: 0.12, blue: 0.11) }
    private var softBlue: Color { Color(red: 0.85, green: 0.88, blue: 0.95) }
    private var sectionBG: Color { colorScheme == .dark ? Color.black.opacity(0.7) : .white }
    private var sectionText: Color { colorScheme == .dark ? offWhite : charcoal }
    private var dimmed: Color { colorScheme == .dark ? Color.white.opacity(0.18) : Color.black.opacity(0.10) }
    private var version: String { "Version 1.0.0" }
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? [charcoal, Color.black] : [offWhite, accent.opacity(0.10)]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Floating logo with halo
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(
                                        RadialGradient(gradient: Gradient(colors: [accent.opacity(colorScheme == .dark ? 0.18 : 0.32), .clear]), center: .center, startRadius: 0, endRadius: 60)
                                    )
                                    .frame(width: 120, height: 120)
                                    .blur(radius: 0.5)
                                Text("n.")
                                    .font(.system(size: 64, weight: .bold, design: .serif))
                                    .foregroundColor(colorScheme == .dark ? offWhite : charcoal)
                                    .shadow(color: accent.opacity(0.18), radius: 8, x: 0, y: 2)
                                    .matchedGeometryEffect(id: "nuraLogo", in: logoNS)
                                    .onTapGesture {
                                        nuraTapCount += 1
                                        if nuraTapCount >= 5 {
                                            withAnimation(.spring()) { showEasterEgg = true }
                                        }
                                    }
                            }
                            .padding(.top, 32)
                            Text("Clarity begins within.")
                                .font(.subheadline)
                                .foregroundColor(colorScheme == .dark ? accent.opacity(0.85) : .secondary)
                                .padding(.bottom, 18)
                        }
                        // Fade-in sections
                        VStack(spacing: 32) {
                            FadeInSection(delay: 0.1) {
                                AboutSection(title: "What is Nura?", text: "A mirror, reimagined. Nura helps you understand your skin, not just cover it.")
                            }
                            FadeInSection(delay: 0.2) {
                                AboutSection(title: "Our Story", text: "A quiet rebellion against one-size-fits-all skincare. Designed by beauty obsessives, perfectionists, and believers in glow.")
                            }
                            FadeInSection(delay: 0.3) {
                                VStack(spacing: 10) {
                                    Text("Crafted With")
                                        .font(.headline).fontWeight(.semibold)
                                        .foregroundColor(sectionText)
                                    HStack(spacing: 32) {
                                        ParallaxIcon(symbol: "brain") // HuggingFace placeholder
                                        ParallaxIcon(symbol: "creditcard") // Stripe placeholder
                                        ParallaxIcon(symbol: "bolt.shield") // OpenAI placeholder
                                    }
                                    .padding(.top, 2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(sectionBG)
                                .cornerRadius(16)
                                .shadow(color: dimmed, radius: 6, x: 0, y: 2)
                            }
                            FadeInSection(delay: 0.4) {
                                VStack(spacing: 8) {
                                    Text("Transparency")
                                        .font(.headline).fontWeight(.semibold)
                                        .foregroundColor(sectionText)
                                    Text("Privacy isn’t optional.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Text("We don’t sell your data. We protect it like it’s part of your skin barrier.")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                    Link("Read our privacy policy", destination: URL(string: "https://nura.app/privacy")!)
                                        .font(.footnote)
                                        .foregroundColor(accent)
                                        .underline()
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                        // Footer
                        VStack(spacing: 6) {
                            Text(version)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if showEasterEgg {
                                VStack(spacing: 2) {
                                    Text("psst. you’re glowing ✨")
                                        .font(.footnote).italic()
                                        .foregroundColor(accent)
                                    Text("Built by the Nura team with love and AI.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .transition(.opacity)
                            }
                        }
                        .padding(.bottom, 18)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button("Done") { dismiss() })
            }
        }
    }
}

struct AboutSection: View {
    let title: String
    let text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline).fontWeight(.semibold)
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .background(Color.clear)
    }
}

struct FadeInSection<Content: View>: View {
    let delay: Double
    let content: () -> Content
    @State private var visible = false
    var body: some View {
        content()
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 24)
            .animation(.easeOut(duration: 0.7).delay(delay), value: visible)
            .onAppear { visible = true }
    }
}

struct ParallaxIcon: View {
    let symbol: String
    @State private var offset: CGFloat = 0
    var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .frame(width: 38, height: 38)
            .foregroundColor(.gray.opacity(0.55))
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    offset = CGFloat.random(in: -6...6)
                }
            }
    }
}

#Preview {
    AboutView()
} 