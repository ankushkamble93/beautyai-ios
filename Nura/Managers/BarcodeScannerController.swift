import AVFoundation
import UIKit

final class BarcodeScannerController: NSObject {
    enum State { case stopped, running, detected(String) }
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var output = AVCaptureMetadataOutput()
    private var onDetected: ((String) -> Void)?
    private var isDebouncing = false
    private(set) var state: State = .stopped

    func attach(to view: UIView, onDetected: @escaping (String) -> Void) {
        self.onDetected = onDetected
        let session = AVCaptureSession()
        session.beginConfiguration()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("❌ [BarcodeScan] Unable to set up camera input")
            return
        }
        session.addInput(input)

        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            // Restrict to retail product symbologies only to avoid non-digit payloads (e.g., shipping Code128)
            output.metadataObjectTypes = [.ean13, .ean8, .upce]
        }

        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        previewLayer = layer
        captureSession = session
        session.commitConfiguration()
        start()
    }

    func start() {
        if case .running = state { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
            DispatchQueue.main.async { self.state = .running; print("🎥 [BarcodeScan] Session started (bg)") }
        }
    }

    func stop() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.stopRunning()
            DispatchQueue.main.async { self.state = .stopped; print("🛑 [BarcodeScan] Session stopped (bg)") }
        }
    }

    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = device.torchMode == .on ? .off : .on
            device.unlockForConfiguration()
            print("🔦 [BarcodeScan] Torch toggled -> \(device.torchMode == .on ? "on" : "off")")
        } catch {
            print("❌ [BarcodeScan] Torch toggle failed: \(error)")
        }
    }
}

extension BarcodeScannerController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !isDebouncing, let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let code = obj.stringValue else { return }
        isDebouncing = true
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        stop()
        print("✅ [BarcodeScan] Detected: \(code)")
        onDetected?(code)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { self.isDebouncing = false }
    }
}


