import SwiftUI

struct AnimatedRingView: View {
    var progress: Double // 0.0 to 1.0
    var ringColor: Color = .blue
    var ringWidth: CGFloat = 16
    var label: String = ""
    var animation: Animation = .easeOut(duration: 1.0)
    
    @State private var animatedProgress: Double = 0.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(ringColor.opacity(0.2), lineWidth: ringWidth)
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(animation, value: animatedProgress)
            if !label.isEmpty {
                Text(label)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onAppear {
            animatedProgress = progress
        }
        .onChange(of: progress) { newValue in
            animatedProgress = newValue
        }
    }
}

// Preview
struct AnimatedRingView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedRingView(progress: 0.75, ringColor: .green, label: "75")
            .frame(width: 120, height: 120)
    }
} 