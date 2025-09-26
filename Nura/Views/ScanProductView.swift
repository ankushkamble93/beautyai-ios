import SwiftUI
import AVFoundation

struct ScanProductView: View {
    var onCancel: () -> Void
    var onDetected: (String) -> Void
    @State private var torchOn = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScannerContainer(onDetected: onDetected)
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Button(action: onCancel) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(8)
                    }
                    Spacer()
                    Button(action: {
                        NotificationCenter.default.post(name: Notification.Name("nura.toggle.torch"), object: nil)
                        torchOn.toggle()
                    }) {
                        Image(systemName: torchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Spacer()
                Text("Align the barcode inside the frame")
                    .font(.callout)
                    .foregroundColor(.white)
                    .padding(.bottom, 24)
            }
        }
        .background(Color.black)
    }
}

private struct ScannerContainer: UIViewControllerRepresentable {
    var onDetected: (String) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .black
        let scanner = BarcodeScannerController()
        context.coordinator.scanner = scanner
        scanner.attach(to: vc.view) { code in
            onDetected(code)
        }
        NotificationCenter.default.addObserver(forName: Notification.Name("nura.toggle.torch"), object: nil, queue: .main) { _ in
            scanner.toggleTorch()
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var scanner: BarcodeScannerController? }
}


