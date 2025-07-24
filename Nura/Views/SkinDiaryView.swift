import SwiftUI

struct SkinDiaryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedStates: Set<String> = []
    @State private var showOtherText: Bool = false
    @State private var otherText: String = ""
    @State private var note: String = ""
    @State private var isSaving: Bool = false
    @State private var savedDate: Date? = nil
    private let states = ["Clear", "Dry", "Oily", "Sensitive", "Bumpy", "Other"]
    private var accent: Color { Color(red: 0.93, green: 0.80, blue: 0.80) } // blush
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
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? [Color.black, Color(red: 0.13, green: 0.12, blue: 0.11)] : [Color.white, accent.opacity(0.13)]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer(minLength: 18)
                    Text("Skin Diary")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                        .padding(.bottom, 2)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.primary)
                    Text("How did your skin feel today?")
                        .font(.title2).fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 18)
                    // Tap-to-select options
                    VStack(spacing: 14) {
                        HStack(spacing: 12) {
                            ForEach(states.prefix(3), id: \.self) { state in
                                DiaryStatePill(
                                    label: state,
                                    selected: selectedStates.contains(state),
                                    color: colorForState(state)
                                ) {
                                    toggleState(state)
                                }
                            }
                        }
                        HStack(spacing: 12) {
                            ForEach(states.suffix(3), id: \.self) { state in
                                DiaryStatePill(
                                    label: state,
                                    selected: selectedStates.contains(state),
                                    color: colorForState(state)
                                ) {
                                    toggleState(state)
                                    if state == "Other" && !showOtherText {
                                        withAnimation(.easeInOut) { showOtherText = true }
                                    } else if state != "Other" && showOtherText && !selectedStates.contains("Other") {
                                        withAnimation(.easeInOut) { showOtherText = false }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, showOtherText ? 0 : 18)
                    // Other text box
                    if showOtherText && selectedStates.contains("Other") {
                        TextField("Describe...", text: $otherText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 32)
                            .padding(.bottom, 12)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    // Optional note
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Want to add a note?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("e.g. Used retinol last night", text: $note)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 18)
                    // Log entry button
                    Button(action: logEntry) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selectedStates.isEmpty ? Color.gray.opacity(0.13) : accent)
                                .frame(height: 52)
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Log entry")
                                    .font(.title3).fontWeight(.semibold)
                                    .foregroundColor(selectedStates.isEmpty ? .secondary : .white)
                            }
                        }
                    }
                    .disabled(selectedStates.isEmpty || isSaving)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 18)
                    .scaleEffect(isSaving ? 0.97 : 1.0)
                    .animation(.easeInOut(duration: 0.18), value: isSaving)
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
        guard !selectedStates.isEmpty else { return }
        isSaving = true
        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            isSaving = false
            savedDate = Date()
            // Reset after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                savedDate = nil
                selectedStates.removeAll()
                otherText = ""
                note = ""
                showOtherText = false
            }
        }
    }
    func colorForState(_ state: String) -> Color {
        switch state {
        case "Clear": return Color.green.opacity(0.18)
        case "Dry": return Color.orange.opacity(0.18)
        case "Oily": return Color.blue.opacity(0.18)
        case "Sensitive": return Color.pink.opacity(0.18)
        case "Bumpy": return Color.purple.opacity(0.18)
        case "Other": return Color.gray.opacity(0.18)
        default: return accent.opacity(0.13)
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
    let selected: Bool
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline).fontWeight(.medium)
                .padding(.vertical, 10)
                .padding(.horizontal, 22)
                .background(selected ? color : Color.gray.opacity(0.07))
                .foregroundColor(selected ? .primary : .secondary)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(selected ? color.opacity(0.7) : Color.gray.opacity(0.13), lineWidth: 1.2)
                )
                .shadow(color: color.opacity(selected ? 0.12 : 0.0), radius: 2, x: 0, y: 1)
                .animation(.easeInOut(duration: 0.18), value: selected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SkinDiaryView()
} 