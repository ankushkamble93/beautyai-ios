import SwiftUI
import PhotosUI

struct RateNuraView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var rating: Int = 0
    @State private var hoverRating: Int = 0
    @State private var feedback: String = ""
    @State private var isSubmitting: Bool = false
    @State private var submitted: Bool = false
    @State private var selectedImage: PhotosPickerItem? = nil
    @State private var attachedImage: UIImage? = nil
    @FocusState private var feedbackFocused: Bool
    private let emojiScale = ["😡", "😕", "😐", "🙂", "🤩"]
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
    private var accent: Color { Color(red: 0.93, green: 0.80, blue: 0.80) } // blush
    private var offWhite: Color { Color(red: 0.98, green: 0.97, blue: 0.95) }
    private var charcoal: Color { Color(red: 0.13, green: 0.12, blue: 0.11) }
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? [charcoal, Color.black] : [offWhite, accent.opacity(0.13)]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer(minLength: 18)
                    // Big emoji star
                    Text("⭐️")
                        .font(.system(size: 64))
                        .padding(.bottom, 8)
                        .scaleEffect(rating > 0 ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: rating)
                    Text("How are we doing?")
                        .font(.title).fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? offWhite : charcoal)
                        .padding(.bottom, 18)
                    // Animated 5-star selector
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \ .self) { i in
                            Image(systemName: (hoverRating >= i || rating >= i) ? "star.fill" : "star")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 38, height: 38)
                                .foregroundColor((hoverRating >= i || rating >= i) ? Color.yellow : Color.gray.opacity(0.25))
                                .scaleEffect((hoverRating == i || rating == i) ? 1.18 : 1.0)
                                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: hoverRating)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                                        rating = i
                                    }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                                .onHover { hovering in
                                    #if os(macOS)
                                    hoverRating = hovering ? i : 0
                                    #endif
                                }
                        }
                    }
                    .padding(.bottom, 24)
                    // Sliding emoji scale
                    ZStack {
                        Capsule()
                            .fill(accent.opacity(0.13))
                            .frame(height: 32)
                        HStack(spacing: 0) {
                            ForEach(0..<emojiScale.count, id: \ .self) { i in
                                Text(emojiScale[i])
                                    .font(.system(size: 24))
                                    .frame(width: 48, height: 32)
                                    .scaleEffect(rating == i+1 ? 1.25 : 1.0)
                                    .opacity(rating == i+1 ? 1.0 : 0.7)
                                    .animation(.spring(response: 0.25, dampingFraction: 0.7), value: rating)
                            }
                        }
                        .frame(width: 48 * 5)
                        .clipped()
                    }
                    .frame(width: 48 * 5, height: 32)
                    .padding(.bottom, 18)
                    // Conditional feedback
                    if rating >= 4 {
                        VStack(spacing: 16) {
                            Text("Thank you 🫶 — would you mind leaving a review?")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                                .padding(.bottom, 2)
                            HStack(spacing: 18) {
                                Link(destination: URL(string: "https://apps.apple.com/app/idXXXXXXXX")!) {
                                    HStack {
                                        Image(systemName: "applelogo")
                                        Text("App Store")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.subheadline)
                                    .frame(minWidth: 120, minHeight: 44)
                                    .padding(.horizontal, 8)
                                    .background(colorScheme == .dark ? Color(red: 0.98, green: 0.85, blue: 0.90) : accent)
                                    .foregroundColor(colorScheme == .dark ? Color.black : .primary)
                                    .cornerRadius(22)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22)
                                            .stroke(colorScheme == .dark ? Color.white.opacity(0.18) : accent.opacity(0.25), lineWidth: 1.2)
                                    )
                                    .shadow(color: colorScheme == .dark ? Color.white.opacity(0.08) : accent.opacity(0.10), radius: 2, x: 0, y: 1)
                                }
                                Link(destination: URL(string: "https://play.google.com/store/apps/details?id=XXXXXXXX")!) {
                                    HStack {
                                        Image(systemName: "play.rectangle.fill")
                                        Text("Play Store")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.subheadline)
                                    .frame(minWidth: 120, minHeight: 44)
                                    .padding(.horizontal, 8)
                                    .background(colorScheme == .dark ? Color(red: 0.80, green: 0.80, blue: 0.95) : Color(red: 0.93, green: 0.93, blue: 0.98))
                                    .foregroundColor(colorScheme == .dark ? Color.black : .primary)
                                    .cornerRadius(22)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22)
                                            .stroke(colorScheme == .dark ? Color.white.opacity(0.18) : Color.blue.opacity(0.15), lineWidth: 1.2)
                                    )
                                    .shadow(color: colorScheme == .dark ? Color.white.opacity(0.08) : Color.blue.opacity(0.10), radius: 2, x: 0, y: 1)
                                }
                            }
                        }
                        .padding(18)
                        .background(cardBackground)
                        .cornerRadius(18)
                        .shadow(color: colorScheme == .dark ? .black.opacity(0.12) : .gray.opacity(0.08), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 10)
                    } else if rating > 0 {
                        VStack(spacing: 16) {
                            Text("We’d love to improve. What can we do better?")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                            ZStack(alignment: .topLeading) {
                                if feedback.isEmpty {
                                    Text("Your feedback helps us grow!")
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 18)
                                }
                                TextEditor(text: $feedback)
                                    .frame(minHeight: 80, maxHeight: 180)
                                    .padding(10)
                                    .background(cardBackground)
                                    .cornerRadius(10)
                                    .foregroundColor(.primary)
                                    .focused($feedbackFocused)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(feedbackFocused ? accent : Color.clear, lineWidth: 1.5)
                                            .animation(.easeInOut(duration: 0.3), value: feedbackFocused)
                                    )
                                    .animation(.easeInOut(duration: 0.3), value: feedbackFocused)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Attach screenshot (optional)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack(spacing: 10) {
                                    PhotosPicker(selection: $selectedImage, matching: .images) {
                                        HStack {
                                            Image(systemName: "paperclip")
                                            Text(attachedImage == nil ? "Upload file" : "Change file")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(accent)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(cardBackground)
                                        .cornerRadius(8)
                                    }
                                    if let img = attachedImage {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 38, height: 38)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(accent, lineWidth: 1))
                                            .shadow(radius: 2)
                                    }
                                }
                            }
                            Button(action: submitFeedback) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(feedback.isEmpty ? Color.gray.opacity(0.18) : accent)
                                        .frame(height: 52)
                                    if isSubmitting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else if submitted {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundColor(.white)
                                            .scaleEffect(submitted ? 1.2 : 1.0)
                                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: submitted)
                                    } else {
                                        Text("Submit")
                                            .font(.title3).fontWeight(.semibold)
                                            .foregroundColor(feedback.isEmpty ? .secondary : .white)
                                    }
                                }
                            }
                            .disabled(feedback.isEmpty || isSubmitting)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                            .scaleEffect(isSubmitting ? 0.97 : 1.0)
                            .animation(.easeInOut(duration: 0.18), value: isSubmitting)
                        }
                        .padding(18)
                        .background(cardBackground)
                        .cornerRadius(18)
                        .shadow(color: colorScheme == .dark ? .black.opacity(0.12) : .gray.opacity(0.08), radius: 10, x: 0, y: 4)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 10)
                    }
                    Spacer()
                    // Elegant footer
                    Text("Your voice shapes Nura 💫")
                        .font(.system(.body, design: .serif)).italic()
                        .foregroundColor(colorScheme == .dark ? offWhite.opacity(0.8) : charcoal.opacity(0.7))
                        .padding(.bottom, 18)
                }
                .onChange(of: selectedImage, initial: false) { oldItem, newItem in
                    if let newItem {
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self), let uiImage = UIImage(data: data) {
                                attachedImage = uiImage
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Done") { dismiss() })
        }
    }
    func submitFeedback() {
        guard !feedback.isEmpty else { return }
        isSubmitting = true
        submitted = false
        // Simulate send delay and animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isSubmitting = false
            submitted = true
            feedback = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                submitted = false
            }
        }
    }
}

#Preview {
    RateNuraView()
} 