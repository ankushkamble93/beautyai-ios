import SwiftUI

struct OnboardingQuestionnaireView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var step: Int = 0
    @State private var answers: [String] = Array(repeating: "", count: 6)
    @State private var showToast: Bool = false
    @State private var otherCondition: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String? = nil
    let totalSteps = 6
    

    
    init() {
        print("🔍 OnboardingQuestionnaireView: Initialized")
    }
    var body: some View {
        let _ = print("🔍 OnboardingQuestionnaireView: Body called")
        return ZStack {
            // Soft, inviting background
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [Color(red:0.13,green:0.12,blue:0.11), Color(red:0.18,green:0.16,blue:0.13)] : [Color(red:0.98,green:0.96,blue:0.93), Color(red:1.0,green:0.98,blue:0.93)]),
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            

            
            VStack(spacing: 0) {
                // Progress bar
                ProgressView(value: Double(step), total: Double(totalSteps))
                    .accentColor(Color.mint)
                    .padding(.top, 32)
                    .padding(.horizontal, 40)
                Spacer(minLength: 18)
                // Card
                VStack(spacing: 18) {
                    Text("Let’s personalize your skincare")
                        .font(.title).fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    Text("Answer a few quick questions to help us understand your body, habits, and goals.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 8)
                    
                    // Back button (except on first step)
                    if step > 0 {
                        HStack {
                            Button(action: {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    step -= 1
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("Back")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.mint)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                    }
                    
                    // Question Card
                    ZStack {
                        ForEach(0..<totalSteps, id: \ .self) { idx in
                            if step == idx {
                                questionCard(for: idx)
                                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
                            }
                        }
                    }
                    .frame(maxWidth: 400)
                    .animation(.spring(response: 0.45, dampingFraction: 0.85), value: step)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(colorScheme == .dark ? Color(red:0.18,green:0.16,blue:0.13) : Color.white)
                        .shadow(color: Color.black.opacity(0.07), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
                Spacer()
            }
            if isSaving {
                Color.black.opacity(0.18).ignoresSafeArea()
                ProgressView("Saving...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .mint))
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
                    .shadow(radius: 8)
            }
            if let error = errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                        .shadow(radius: 6)
                        .padding(.bottom, 40)
                }
            }
            // Toast
            if showToast {
                VStack {
                    HStack {
                        Spacer()
                        Text("Thanks! We'll use this to tailor your skincare journey.")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color.mint.opacity(0.95)))
                            .shadow(radius: 8)
                        Spacer()
                    }
                    .padding(.top, 48)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // True floating debug button - overlays everything
            Button("Sign Out & Clear All") {
                Task {
                    await authManager.signOut()
                    await authManager.clearAllCachedState()
                }
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.9))
            .foregroundColor(.white)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            .position(x: UIScreen.main.bounds.width - 100, y: 100)
            .allowsHitTesting(true)
            .zIndex(9999)
        }
        .onAppear {
            print("🔍 OnboardingQuestionnaireView: Appeared")
            print("🔍 OnboardingQuestionnaireView: User profile - onboarding_complete = \(authManager.userProfile?.onboarding_complete ?? false)")
        }
    }
    @ViewBuilder
    private func questionCard(for idx: Int) -> some View {
        switch idx {
        case 0:
            VStack(spacing: 18) {
                Text("What's your age?")
                    .font(.title2).fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 12) {
                    ForEach([
                        "18-24",
                        "25-34", 
                        "35-44",
                        "45-54",
                        "55-64",
                        "65+"
                    ], id: \.self) { option in
                        answerButton(option: option, idx: idx)
                    }
                }
            }
        case 1:
            VStack(spacing: 18) {
                Text("What's your sex?")
                    .font(.title2).fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 12) {
                    ForEach(["Female", "Male", "Non-binary", "Prefer not to say"], id: \ .self) { option in
                        answerButton(option: option, idx: idx)
                    }
                }
            }
        case 2:
            VStack(spacing: 18) {
                Text("How active are you weekly?")
                    .font(.title2).fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 12) {
                    ForEach(["Sedentary (rarely work out)", "Light activity (1–2x/week)", "Moderate (3–4x/week)", "Intense (5+ workouts/week)"], id: \ .self) { option in
                        answerButton(option: option, idx: idx)
                    }
                }
            }
        case 3:
            VStack(spacing: 18) {
                Text("How hydrated are you daily?")
                    .font(.title2).fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 12) {
                    ForEach([
                        "Less than 1L ( < 0.26 gal )",
                        "1–2L (0.26–0.53 gal)",
                        "2–3L (0.53–0.79 gal)",
                        "3L+ (0.79+ gal)"
                    ], id: \ .self) { option in
                        answerButton(option: option, idx: idx)
                    }
                }
            }
        case 4:
            VStack(spacing: 18) {
                Text("What's your current skincare goal?")
                    .font(.title2).fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 12) {
                    ForEach(["Clear up acne", "Reduce dryness", "Improve glow", "Slow aging", "Just exploring"], id: \ .self) { option in
                        answerButton(option: option, idx: idx)
                    }
                }
            }
        case 5:
            VStack(spacing: 18) {
                Text("Do you have any known skin conditions?")
                    .font(.title2).fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(spacing: 12) {
                    ForEach(["None", "Acne", "Eczema", "Rosacea"], id: \ .self) { option in
                        answerButton(option: option, idx: idx)
                    }
                    HStack {
                        Text("Other:")
                        TextField("Type here", text: $otherCondition)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 180)
                    }
                    .padding(.top, 4)
                    Button(action: {
                        answers[idx] = otherCondition
                        nextStep()
                    }) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 32)
                            .background(Color.mint.opacity(0.18))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                    .disabled(otherCondition.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        default:
            EmptyView()
        }
    }
    private func answerButton(option: String, idx: Int) -> some View {
        Button(action: {
            answers[idx] = option
            nextStep()
        }) {
            Text(option)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.mint.opacity(0.13))
                .foregroundColor(.primary)
                .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
    }
    private func nextStep() {
        if step < totalSteps - 1 {
            step += 1
        } else {
            finishOnboarding()
        }
    }
    private func finishOnboarding() {
        isSaving = true
        errorMessage = nil
        
        // Create OnboardingAnswers structure for ChatGPT integration
        let onboardingAnswers = OnboardingAnswers.fromAnswers(answers)
        
        // Log the answers for debugging and future ChatGPT integration
        print("🔍 OnboardingAnswers created:")
        if let answers = onboardingAnswers {
            print(answers.asFormattedString)
            print("🔍 OnboardingAnswers as dictionary:")
            print(answers.asDictionary)
        } else {
            print("❌ No onboarding answers available")
        }
        
        Task {
            await authManager.setOnboardingComplete(onboardingAnswers: onboardingAnswers)
            if let error = authManager.errorMessage {
                isSaving = false
                errorMessage = error
                return
            }
            showToast = true
            isSaving = false
            // Remove dismiss() since this is part of main navigation flow
            // The auth state change will automatically navigate to dashboard
        }
    }
    
    // Function to get onboarding answers for external use (e.g., ChatGPT integration)
    func getOnboardingAnswers() -> OnboardingAnswers? {
        return OnboardingAnswers.fromAnswers(answers)
    }
}

#Preview {
    OnboardingQuestionnaireView()
} 