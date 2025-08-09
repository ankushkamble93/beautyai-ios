import SwiftUI

struct SkinDiaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var skinDiaryManager: SkinDiaryManager
    @State private var selectedStates: Set<String> = []
    @State private var showOtherText: Bool = false
    @State private var otherText: String = ""
    @State private var note: String = ""
    @State private var isSaving: Bool = false
    @State private var savedDate: Date? = nil
    @State private var animateEmojis: Bool = false
    @State private var pulseEffect: Bool = false
    @State private var showTimeRestriction: Bool = false
    
    private let states = ["Clear", "Dry", "Oily", "Sensitive", "Bumpy", "Other"]
    private let stateEmojis = ["Clear": "✅", "Dry": "🔸", "Oily": "💧", "Sensitive": "⚠️", "Bumpy": "🔺", "Other": "📝"]
    private var accent: Color { Color(red: 0.93, green: 0.80, blue: 0.80) } // blush
    private var vibrantAccent: Color { Color(red: 0.98, green: 0.75, blue: 0.85) } // More vibrant pink
    private var softBlue: Color { Color(red: 0.85, green: 0.88, blue: 0.95) }
    private var cardBG: Color { colorScheme == .dark ? Color.black.opacity(0.7) : .white }
    private var todayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: Date())
    }
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced gradient background
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? 
                        [Color.black, Color(red: 0.15, green: 0.10, blue: 0.20), Color(red: 0.10, green: 0.05, blue: 0.15)] :
                        [Color(red: 0.98, green: 0.96, blue: 0.98), vibrantAccent.opacity(0.15), Color(red: 0.95, green: 0.90, blue: 0.95)]
                    ),
                    startPoint: .topLeading, 
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()
                
                // Floating background elements for visual interest
                GeometryReader { geometry in
                    ForEach(0..<6, id: \.self) { index in
                        Circle()
                            .fill(vibrantAccent.opacity(0.08))
                            .frame(width: 60 + CGFloat(index * 20), height: 60 + CGFloat(index * 20))
                            .offset(
                                x: CGFloat.random(in: -50...geometry.size.width + 50),
                                y: CGFloat.random(in: -50...geometry.size.height + 50)
                            )
                            .blur(radius: 15)
                            .scaleEffect(animateEmojis ? 1.1 : 0.9)
                            .animation(.easeInOut(duration: Double.random(in: 3...5)).repeatForever(autoreverses: true), value: animateEmojis)
                    }
                }
                
                VStack(spacing: 0) {
                    Spacer(minLength: 18)
                    
                    // Enhanced title with emoji and gradient
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Text("📊")
                                .font(.system(size: 32))
                                .scaleEffect(pulseEffect ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseEffect)
                            
                            Text("Skin Diary")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            colorScheme == .dark ? Color.white : Color(red: 0.2, green: 0.3, blue: 0.4),
                                            colorScheme == .dark ? Color.gray.opacity(0.8) : Color(red: 0.4, green: 0.5, blue: 0.6)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                        
                        Text("How did your skin feel today? ✨")
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundColor(colorScheme == .dark ? Color.white.opacity(0.9) : Color.primary.opacity(0.8))
                    }
                    .padding(.bottom, 24)
                    // Tap-to-select options
                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            ForEach(states.prefix(3), id: \.self) { state in
                                DiaryStatePill(
                                    label: state,
                                    emoji: stateEmojis[state] ?? "😊",
                                    selected: selectedStates.contains(state),
                                    color: colorForState(state)
                                ) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        toggleState(state)
                                    }
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            ForEach(states.suffix(3), id: \.self) { state in
                                DiaryStatePill(
                                    label: state,
                                    emoji: stateEmojis[state] ?? "😊",
                                    selected: selectedStates.contains(state),
                                    color: colorForState(state)
                                ) {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                        toggleState(state)
                                    }
                                    if state == "Other" && !showOtherText {
                                        withAnimation(.easeInOut) { showOtherText = true }
                                    } else if state != "Other" && showOtherText && !selectedStates.contains("Other") {
                                        withAnimation(.easeInOut) { showOtherText = false }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, showOtherText ? 24 : 18)
                    // Other text box
                    if showOtherText && selectedStates.contains("Other") {
                        TextField("Describe...", text: $otherText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.9))
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.horizontal, 32)
                            .padding(.bottom, 20)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    // Optional note
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Want to add a note?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("e.g. Used retinol last night", text: $note)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.9))
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                    // Time restriction warning
                    if !skinDiaryManager.canLogToday {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                Text("Diary logging is only available from 6 PM to midnight")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                            
                            if skinDiaryManager.timeUntilNextLog > 0 {
                                Text("Next available in \(skinDiaryManager.formatTimeUntilNextLog())")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 32)
                        .padding(.bottom, 18)
                    }
                    
                    // Enhanced log entry button
                    Button(action: logEntry) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    selectedStates.isEmpty ? 
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.15)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        gradient: Gradient(colors: [vibrantAccent, accent]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 56)
                                .shadow(
                                    color: selectedStates.isEmpty ? .clear : vibrantAccent.opacity(0.3),
                                    radius: selectedStates.isEmpty ? 0 : 8,
                                    x: 0,
                                    y: selectedStates.isEmpty ? 0 : 4
                                )
                            
                            if isSaving {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                    Text("Saving your thoughts...")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Text("💾")
                                        .font(.title2)
                                    Text("Log entry")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedStates.isEmpty ? .secondary : .white)
                                }
                            }
                        }
                    }
                    .disabled(selectedStates.isEmpty || isSaving || !skinDiaryManager.canLogToday)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 18)
                    .scaleEffect(isSaving ? 0.97 : (selectedStates.isEmpty || !skinDiaryManager.canLogToday ? 1.0 : 1.02))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSaving)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedStates.isEmpty)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: skinDiaryManager.canLogToday)
                    // Confirmation
                    if let savedDate = savedDate {
                        Text("Logged for \(dateString(savedDate))")
                            .font(.footnote)
                            .foregroundColor(accent)
                            .padding(.top, 2)
                            .transition(.opacity)
                    }
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: Button("Done") { dismiss() })
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        animateEmojis = true
                    }
                    withAnimation(.easeInOut(duration: 2).delay(0.5)) {
                        pulseEffect = true
                    }
                }
            }
        }
    }
    func toggleState(_ state: String) {
        if selectedStates.contains(state) {
            selectedStates.remove(state)
            if state == "Other" { otherText = "" }
        } else if selectedStates.count < 3 {
            selectedStates.insert(state)
        }
    }
    func logEntry() {
        guard !selectedStates.isEmpty && skinDiaryManager.canLogToday else { return }
        isSaving = true
        
        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            let success = skinDiaryManager.addEntry(
                states: selectedStates,
                otherText: otherText,
                note: note
            )
            
            isSaving = false
            
            if success {
                savedDate = Date()
                // Reset after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    savedDate = nil
                    selectedStates.removeAll()
                    otherText = ""
                    note = ""
                    showOtherText = false
                }
            } else {
                // Show error if logging failed
                showTimeRestriction = true
            }
        }
    }
    func colorForState(_ state: String) -> Color {
        switch state {
        case "Clear": return Color(red: 0.2, green: 0.8, blue: 0.5).opacity(0.25) // Vibrant mint green
        case "Dry": return Color(red: 0.9, green: 0.6, blue: 0.3).opacity(0.25) // Warm orange
        case "Oily": return Color(red: 0.3, green: 0.7, blue: 0.9).opacity(0.25) // Bright blue
        case "Sensitive": return Color(red: 0.9, green: 0.5, blue: 0.7).opacity(0.25) // Soft pink
        case "Bumpy": return Color(red: 0.7, green: 0.4, blue: 0.9).opacity(0.25) // Rich purple
        case "Other": return Color(red: 0.6, green: 0.6, blue: 0.6).opacity(0.25) // Modern gray
        default: return vibrantAccent.opacity(0.15)
        }
    }
    func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct DiaryStatePill: View {
    let label: String
    let emoji: String
    let selected: Bool
    let color: Color
    let action: () -> Void
    
    @State private var bounceEffect: Bool = false
    
    var body: some View {
        Button(action: {
            action()
            // Trigger bounce effect
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bounceEffect.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 16))
                    .scaleEffect(selected ? 1.1 : 1.0)
                    .scaleEffect(bounceEffect ? 1.2 : 1.0)
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        selected ? 
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.08)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(selected ? .primary : .secondary)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        selected ? color.opacity(0.8) : Color.gray.opacity(0.15), 
                        lineWidth: selected ? 2.0 : 1.0
                    )
            )
            .shadow(
                color: selected ? color.opacity(0.25) : .clear, 
                radius: selected ? 6 : 0, 
                x: 0, 
                y: selected ? 3 : 0
            )
            .scaleEffect(selected ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selected)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: bounceEffect)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SkinDiaryView()
} 