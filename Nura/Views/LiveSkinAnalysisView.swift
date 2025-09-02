import SwiftUI
import AVFoundation
import Vision

struct LiveSkinAnalysisView: View {
    let onComplete: ([UIImage]) -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraVisionController()
    @Environment(\.scenePhase) private var scenePhase
    
    private enum Angle: String { case front = "Front", left = "Left", right = "Right" }
    @State private var targetAngle: Angle = .front
    @State private var captured: [UIImage] = []
    @State private var holdProgress: Double = 0.0
    @State private var speakQueue: String = ""
    @State private var isVoiceEnabled: Bool = false
    private let tts = AVSpeechSynthesizer()
    private let successHaptic = UINotificationFeedbackGenerator()
    private let softHaptic = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        ZStack {
            if camera.isAvailable && camera.permissionGranted {
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
            } else {
                if camera.simulatorFeedEnabled {
                    SimulatorPreviewView()
                        .ignoresSafeArea()
                } else {
                    Color.black.opacity(0.92).ignoresSafeArea()
                    VStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.8))
                        Text(camera.isAvailable ? "Camera access is required" : "Camera not available in Simulator")
                            .foregroundColor(.white)
                            .font(.headline)
                        if !camera.permissionGranted {
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                            }
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(Color.white.opacity(0.15)).foregroundColor(.white).clipShape(Capsule())
                        }
                        Text("Connect a real device or enable Simulator Demo mode.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                            .padding(.horizontal)
                    }
                }
            }
            
            // Overlays: face rect, region guides, HUD
            GeometryReader { geo in
                ZStack {
                    // Face bounding boxes
                    ForEach(camera.faceOverlays, id: \.self) { rect in
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.yellow, lineWidth: 2)
                            .frame(width: rect.width * geo.size.width, height: rect.height * geo.size.height)
                            .position(x: rect.midX * geo.size.width, y: rect.midY * geo.size.height)
                        // Region guides (approx inside the face rect)
                        Group {
                            faceFittedRegionPath(in: rect, landmarks: camera.primaryLandmarks)
                                .stroke(Color.yellow.opacity(0.7), style: StrokeStyle(lineWidth: 1.6, dash: [6,4]))
                                .frame(width: rect.width * geo.size.width, height: rect.height * geo.size.height)
                                .position(x: rect.midX * geo.size.width, y: rect.midY * geo.size.height)
                        }
                    }
                    // Glare sparkles
                    ForEach(camera.glarePoints, id: \.self) { pt in
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 4, height: 4)
                            .position(x: pt.x * geo.size.width, y: (1-pt.y) * geo.size.height)
                    }
                }
            }
            .allowsHitTesting(false)
            
            VStack(spacing: 8) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundColor(.white)
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
                VStack(spacing: 6) {
                    Text("Live skin scan (beta) • Target: \(targetAngle.rawValue)")
                        .font(.footnote)
                        .padding(8)
                        .background(.black.opacity(0.5))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    Text("Local only • On-device")
                        .font(.caption2)
                        .padding(4)
                        .background(.black.opacity(0.35))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    exposureBanner
                    promptBanner
                }
                .padding(.bottom, 12)
                // Thumbnails + undo
                if !captured.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(0..<captured.count, id: \.self) { i in
                            Image(uiImage: captured[i])
                                .resizable().scaledToFill()
                                .frame(width: 48, height: 72).clipped().cornerRadius(6)
                        }
                        Button(action: undoLast) {
                            HStack(spacing: 4) { Image(systemName: "arrow.uturn.left.circle"); Text("Undo") }
                                .font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 6)
                                .background(Color.gray.opacity(0.3)).foregroundColor(.white).clipShape(Capsule())
                        }
                    }.padding(.bottom, 6)
                }
                HStack(spacing: 12) {
                    Button(action: capture) {
                        HStack { Image(systemName: "camera.circle.fill"); Text("Capture") }
                            .font(.headline)
                            .padding(.vertical, 10).padding(.horizontal, 16)
                            .background(canCapture ? Color.green : Color.gray.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .disabled(!canCapture)
                    
                    Button(action: finishIfReady) {
                        HStack { Image(systemName: "checkmark.circle.fill"); Text("Use 3 photos") }
                            .font(.headline)
                            .padding(.vertical, 10).padding(.horizontal, 16)
                            .background(captured.count >= 3 ? Color.blue : Color.gray.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .disabled(captured.count < 3)
                    Button(action: { isVoiceEnabled.toggle(); softHaptic.impactOccurred() }) {
                        Image(systemName: isVoiceEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 24)
                // Auto-capture progress ring
                ZStack {
                    Circle().stroke(Color.white.opacity(0.25), lineWidth: 6).frame(width: 48, height: 48)
                    Circle().trim(from: 0, to: holdProgress).stroke(canCapture ? Color.green : Color.red, style: StrokeStyle(lineWidth: 6, lineCap: .round)).rotationEffect(.degrees(-90)).frame(width: 48, height: 48)
                }
                .padding(.bottom, 12)
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .onChange(of: scenePhase) { _, phase in if phase != .active { camera.stop() } }
        .onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
            updateAutoCapture()
        }
    }
    
    private var canCapture: Bool {
        camera.faceDetected && camera.exposureOk && camera.glareOk && angleSatisfied
    }
    
    private var angleSatisfied: Bool {
        let yaw = camera.yaw ?? 0
        switch targetAngle {
        case .front: return abs(yaw) < 8 * .pi / 180
        case .left: return yaw > 12 * .pi / 180
        case .right: return yaw < -12 * .pi / 180
        }
    }
    
    private var promptBanner: some View {
        let prompt: String = {
            switch targetAngle {
            case .front: return "Center your face and look forward"
            case .left: return "Turn your head slightly LEFT"
            case .right: return "Turn your head slightly RIGHT"
            }
        }()
        return Text(prompt)
            .font(.caption)
            .padding(6)
            .background(.black.opacity(0.45))
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
    
    private var exposureBanner: some View {
        Group {
            if !camera.exposureOk {
                Text(camera.exposure < 0.35 ? "Too dark - add light" : "Too bright - reduce glare")
                    .font(.caption)
                    .padding(6)
                    .background(Color.orange.opacity(0.85))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            } else if !camera.glareOk {
                Text("Glare detected - tilt phone or move lighting")
                    .font(.caption)
                    .padding(6)
                    .background(Color.orange.opacity(0.85))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
    }
    
    private func capture() {
        guard let image = camera.captureCurrentImage() else { return }
        captured.append(image)
        successHaptic.notificationOccurred(.success)
        // Move to next angle
        switch targetAngle {
        case .front: targetAngle = .left
        case .left: targetAngle = .right
        case .right: targetAngle = .right
        }
    }
    
    private func finishIfReady() {
        guard captured.count >= 3 else { return }
        onComplete(Array(captured.prefix(3)))
        dismiss()
    }
    
    private func undoLast() {
        if !captured.isEmpty { captured.removeLast(); softHaptic.impactOccurred() }
    }
    
    private func updateAutoCapture() {
        // Voice prompts (throttled by message change)
        let key: String
        if !camera.faceDetected { key = "no_face" }
        else if !camera.exposureOk { key = camera.exposure < 0.35 ? "too_dark" : "too_bright" }
        else if !camera.glareOk { key = "glare" }
        else if !angleSatisfied { key = targetAngle == .left ? "turn_left" : (targetAngle == .right ? "turn_right" : "center") }
        else { key = "hold" }
        if key != speakQueue && isVoiceEnabled {
            speakQueue = key
            let phrase: String = {
                switch key {
                case "no_face": return "No face detected"
                case "too_dark": return "Too dark. Add more light"
                case "too_bright": return "Too bright. Reduce glare"
                case "glare": return "Glare detected. Tilt the phone"
                case "turn_left": return "Turn left a bit"
                case "turn_right": return "Turn right a bit"
                case "center": return "Center your face"
                default: return "Hold steady"
                }
            }()
            let u = AVSpeechUtterance(string: phrase)
            u.rate = 0.5
            tts.speak(u)
        }
        
        // Auto-capture progress
        if canCapture { holdProgress = min(1.0, holdProgress + 0.05/0.7) } else { holdProgress = max(0.0, holdProgress - 0.08) }
        if holdProgress >= 1.0 {
            capture()
            holdProgress = 0.0
        }
    }
    
    // Approximate T-zone/cheeks/chin path inside a unit rect (0-1)
    private func faceFittedRegionPath(in faceRect: CGRect, landmarks: FaceLandmarks?) -> Path {
        var p = Path()
        // If landmarks available, gently warp vertical bounds; otherwise fall back to rectangles
        func rectPath(_ r: CGRect) { p.addRoundedRect(in: r, cornerSize: CGSize(width: r.width * 0.12, height: r.height * 0.12)) }
        let foreheadTop = landmarks?.foreheadTop ?? (faceRect.minY + faceRect.height * 0.02)
        let chinY = landmarks?.chinY ?? (faceRect.maxY - faceRect.height * 0.02)
        let noseY = landmarks?.noseY ?? (faceRect.minY + faceRect.height * 0.45)
        let f = CGRect(x: faceRect.width * 0.15, y: foreheadTop - faceRect.minY, width: faceRect.width * 0.7, height: max(4, (noseY - faceRect.minY) * 0.45))
        let nose = CGRect(x: faceRect.midX - faceRect.width * 0.10, y: faceRect.minY + faceRect.height * 0.28, width: faceRect.width * 0.20, height: faceRect.height * 0.28)
        let lCheek = CGRect(x: faceRect.minX + faceRect.width * 0.05, y: faceRect.minY + faceRect.height * 0.32, width: faceRect.width * 0.22, height: (chinY - (faceRect.minY + faceRect.height * 0.32)) * 0.6)
        let rCheek = CGRect(x: faceRect.maxX - faceRect.width * 0.27, y: faceRect.minY + faceRect.height * 0.32, width: faceRect.width * 0.22, height: (chinY - (faceRect.minY + faceRect.height * 0.32)) * 0.6)
        let chin = CGRect(x: faceRect.midX - faceRect.width * 0.20, y: max(faceRect.minY, chinY - faceRect.height * 0.18), width: faceRect.width * 0.40, height: faceRect.height * 0.18)
        rectPath(f); rectPath(nose); rectPath(lCheek); rectPath(rCheek); rectPath(chin)
        return p
    }
}

struct FaceLandmarks {
    let foreheadTop: CGFloat
    let chinY: CGFloat
    let noseY: CGFloat
}

private extension Optional where Wrapped == NSNumber {
    var doubleValue: Double? { self?.doubleValue }
}

// MARK: - Camera + Vision controller
final class CameraVisionController: NSObject, ObservableObject {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "live.camera.session")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let visionQueue = DispatchQueue(label: "live.vision.queue")
    private let ciContext = CIContext()
    
    @Published var simulatorFeedEnabled: Bool = false
    @Published var permissionGranted: Bool = false
    @Published var isAvailable: Bool = true
    @Published var faceOverlays: [CGRect] = [] // normalized rects 0-1
    @Published var primaryLandmarks: FaceLandmarks? = nil
    @Published var faceDetected: Bool = false
    @Published var exposure: Double = 0.0 // 0-1
    @Published var exposureOk: Bool = true
    @Published var glareOk: Bool = true
    @Published var yaw: Double? = nil // radians
    @Published var roll: Double? = nil // radians
    @Published var glarePoints: [CGPoint] = [] // normalized 0-1, image coords (origin bottom-left)
    
    private var lastBuffer: CVPixelBuffer?
    private let sequenceHandler = VNSequenceRequestHandler()
    private var frameCount: Int = 0
    
    func start() {
        sessionQueue.async {
            self.configureIfNeeded()
            if !self.session.isRunning { self.session.startRunning() }
        }
    }
    
    func stop() {
        sessionQueue.async { if self.session.isRunning { self.session.stopRunning() } }
    }
    
    func captureCurrentImage() -> UIImage? {
        guard let buffer = lastBuffer else { return nil }
        let ci = CIImage(cvPixelBuffer: buffer)
        guard let cg = ciContext.createCGImage(ci, from: ci.extent) else { return nil }
        return UIImage(cgImage: cg, scale: UIScreen.main.scale, orientation: .upMirrored)
    }
    
    private var configured = false
    private func configureIfNeeded() {
        guard !configured else { return }
        session.beginConfiguration()
        session.sessionPreset = .high
        
        // Check device availability (simulator has no camera)
        #if targetEnvironment(simulator)
        self.isAvailable = false
        self.simulatorFeedEnabled = true
        session.commitConfiguration()
        return
        #else
        if AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) == nil { self.isAvailable = false; session.commitConfiguration(); return } else { self.isAvailable = true }
        #endif
        
        // Request permission if needed
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            let semaphore = DispatchSemaphore(value: 0)
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { self.permissionGranted = granted }
                semaphore.signal()
            }
            semaphore.wait()
        default:
            permissionGranted = false
        }
        guard permissionGranted else { session.commitConfiguration(); return }
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration(); return
        }
        session.addInput(input)
        
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        
        if let connection = videoOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
        }
        
        session.commitConfiguration()
        configured = true
    }
}

extension CameraVisionController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        lastBuffer = buffer
        // Basic exposure and glare heuristics + store last buffer
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        if let baseAddress = CVPixelBufferGetBaseAddress(buffer) {
            let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
            var total: Double = 0
            var brightPixels = 0
            var brightPts: [CGPoint] = []
            let step = max(1, (width * height) / 20000) // sample ~20k pixels
            for y in stride(from: 0, to: height, by: step) {
                let row = baseAddress.advanced(by: y * bytesPerRow)
                for x in stride(from: 0, to: width, by: step) {
                    let pixel = row.advanced(by: x * 4)
                    let b = Double(pixel.load(as: UInt8.self))
                    let g = Double(pixel.advanced(by: 1).load(as: UInt8.self))
                    let r = Double(pixel.advanced(by: 2).load(as: UInt8.self))
                    let lum = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
                    total += lum
                    if r > 248 && g > 248 && b > 248 {
                        brightPixels += 1
                        if brightPts.count < 32 { brightPts.append(CGPoint(x: CGFloat(x)/CGFloat(width), y: CGFloat(y)/CGFloat(height))) }
                    }
                }
            }
            let samples = Double((height/step) * (width/step))
            let avg = samples > 0 ? total / samples : 0
            let glareRatio = samples > 0 ? Double(brightPixels) / samples : 0
            DispatchQueue.main.async {
                self.exposure = avg
                self.exposureOk = (avg > 0.35 && avg < 0.9)
                self.glareOk = glareRatio < 0.03
                self.glarePoints = brightPts
            }
        }
        CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
        
        frameCount += 1
        // Throttle Vision processing to every 3rd frame
        guard frameCount % 3 == 0 else { return }
        
        let landmarksReq = VNDetectFaceLandmarksRequest { [weak self] req, _ in
            guard let self = self else { return }
            let observations = (req.results as? [VNFaceObservation]) ?? []
            let rects = observations.map { $0.boundingBox }
            var lm: FaceLandmarks? = nil
            if let first = observations.first {
                let faceRect = first.boundingBox
                let chinY = faceRect.minY
                let foreheadTop = faceRect.maxY
                let noseY = first.landmarks?.nose?.normalizedPoints.first.map { Double(faceRect.minY + faceRect.height * CGFloat($0.y)) } ?? Double(faceRect.midY)
                lm = FaceLandmarks(foreheadTop: foreheadTop, chinY: chinY, noseY: CGFloat(noseY))
                self.yaw = first.yaw?.doubleValue
                self.roll = first.roll?.doubleValue
            }
            DispatchQueue.main.async {
                self.faceOverlays = rects
                self.faceDetected = !rects.isEmpty
                self.primaryLandmarks = lm
            }
        }
        try? sequenceHandler.perform([landmarksReq], on: buffer, orientation: .up)
    }
}

// MARK: - CameraPreview layer
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView { PreviewView(session: session) }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

final class PreviewView: UIView {
    private let videoLayer = AVCaptureVideoPreviewLayer()
    init(session: AVCaptureSession) {
        super.init(frame: .zero)
        videoLayer.session = session
        videoLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(videoLayer)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() { super.layoutSubviews(); videoLayer.frame = bounds }
}

// MARK: - Simulator preview (animated gradient placeholder)
struct SimulatorPreviewView: View {
    @State private var phase: CGFloat = 0
    var body: some View {
        TimelineView(.animation) { _ in
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.25), Color.gray.opacity(0.45), Color.gray.opacity(0.25)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .hueRotation(.degrees(Double(phase)))
                    .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: phase)
                Image(systemName: "person.crop.square")
                    .resizable().scaledToFit().frame(width: 140)
                    .foregroundColor(.white.opacity(0.7))
            }
            .onAppear { phase = 360 }
        }
        .overlay(alignment: .topTrailing) {
            Text("Simulator Demo")
                .font(.caption2)
                .padding(6)
                .background(Color.black.opacity(0.4))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .padding(8)
        }
    }
}


