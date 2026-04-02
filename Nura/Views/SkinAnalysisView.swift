import SwiftUI
import PhotosUI
import Vision
import AVFoundation

struct SkinAnalysisView: View {
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var showingResults = false
    @State private var showPremiumBanner = false
    @State private var showLimitReachedBanner = false
    @State private var showLiveAnalysis = false
    @State private var showLiveInfo = false
    @State private var debugLiveEnabled = false
    @State private var showDebugAlert = false
    // Progress is now driven by SkinAnalysisManager.analysisProgress
    @State private var photoStates: [UUID: Bool] = [:] // Track individual photo states
    @State private var photoValidationResults: [Int: PhotoValidationResult] = [:] // Cache validation results
    @State private var imageToPhotosPickerMapping: [Int: PhotosPickerItem] = [:] // Map uploaded image index to PhotosPicker item
    @State private var showAnalyzeSuccess: Bool = false
    @State private var showIssueHighlightsSheet: Bool = false
    @State private var analysisRequestDate: Date? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 22) {
                    // Custom large, centered title - maintain consistent top margin with other pages
                    HStack {
                        Spacer()
                        Text("Skin Analysis")
                            .font(.largeTitle).fontWeight(.bold)
                            .padding(.top, 8) // Restored to maintain consistency with other page titles
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                        Spacer()
                    }
                    // Reduced space between title and camera icon for better visual balance
                    Spacer().frame(height: 0)
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(isDark ? NuraColors.primaryDark : NuraColors.primary)
                        .padding(.top, -6)
                        
                    // Removed duplicate "Upload 3 selfies" text - only keeping the one in the upload section
                    
                    // Image upload section - moved above tips
                    VStack(spacing: 20) {
                        if skinAnalysisManager.uploadedImages.isEmpty {
                            // Upload prompt
                            VStack(spacing: 15) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 40))
                                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.85))
                                
                                Text("Upload 3 Selfies")
                                    .font(.headline)
                                
                                Text("Front, left side, and right side views for best results")
                                    .font(.caption)
                                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.85))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                            .background(isDark ? NuraColors.cardDark : NuraColors.card.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke((isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.75)).opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                            )
                        } else {
                            // Uploaded images with trash can overlays
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                                ForEach(Array(skinAnalysisManager.uploadedImages.enumerated()), id: \.offset) { index, image in
                                    ZStack {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 180)
                                            .clipped()
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(NuraColors.primary, lineWidth: 2)
                                            )
                                        
                                        // Trash can overlay for photo removal
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Button(action: {
                                                    removePhoto(at: index)
                                                }) {
                                                    Image(systemName: "trash.circle.fill")
                                                        .font(.system(size: 24))
                                                        .foregroundColor(.white)
                                                        .background(Color.red.opacity(0.8))
                                                        .clipShape(Circle())
                                                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                                }
                                                .padding(.top, 8)
                                                Spacer()
                                            }
                                            Spacer()
                                        }
                                    }
                                    .id("photo_\(index)_\(image.hashValue)") // Unique identifier for each photo
                                }
                            }
                        }
                        
                                            // Add daily limit information (hidden for Pro Unlimited)
                    if !skinAnalysisManager.uploadedImages.isEmpty && !userTierManager.hasUnlimitedAnalysisAccess() {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                Text("Daily Analysis Limit")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                                Spacer()
                                Text("\(userTierManager.getCurrentDailyAnalysisCount())/\(userTierManager.getDailyAnalysisLimit())")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                            }
                            if !userTierManager.canPerformAnalysis() {
                                let formatter: DateFormatter = {
                                    let f = DateFormatter()
                                    f.timeStyle = .short
                                    f.dateStyle = .medium
                                    return f
                                }()
                                Text("Next analysis available: \(formatter.string(from: userTierManager.getNextAnalysisTime()))")
                                    .font(.caption2)
                                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
                            }
                        }
                        .padding(.horizontal)
                    }
                        
                        // Compute if the select photos button should be disabled (uploaded and before nextDay)
                        let isUploadLocked: Bool = {
                            if skinAnalysisManager.uploadedImages.isEmpty { return false }
                            if userTierManager.hasUnlimitedAnalysisAccess() { return false }
                            let now = Date()
                            let calendar = Calendar.current
                            let nextDay = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) ?? now
                            return now < nextDay
                        }()
                        
                        // Upload + Camera row: 5/6 select + 1/6 camera
                        HStack(spacing: 8) {
                            Button(action: { showLiveAnalysis = true }) {
                                Image(systemName: "camera.fill")
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.white)
                                    .background((isUploadLocked ? Color.gray.opacity(0.4) : NuraColors.primary).opacity(0.85))
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.75), lineWidth: 1))
                            }
                            .disabled(isUploadLocked)
                            .frame(width: 50)
                            
                            PhotosPicker(selection: $selectedImages, maxSelectionCount: 3, matching: .images) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Select Photos")
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(isUploadLocked ? Color.gray.opacity(0.4) : NuraColors.primary)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isUploadLocked)
                            .onChange(of: selectedImages) { oldValue, newValue in
                                Task { await loadImages(from: newValue) }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Removed mid-page live analysis button (moved to top as disabled beta)
                    
                    // Analysis button with progress bar
                    if !skinAnalysisManager.uploadedImages.isEmpty {
                        VStack(spacing: 14) {
                            let canAnalyzeNow: Bool = userTierManager.canPerformAnalysis() && skinAnalysisManager.uploadedImages.count >= 3
                            Button(action: {
                                if canAnalyzeNow {
                                    analysisRequestDate = Date()
                                    skinAnalysisManager.uploadImages(skinAnalysisManager.uploadedImages)
                                } else {
                                    // Show limit reached banner (hidden for Pro Unlimited)
                                    if !userTierManager.hasUnlimitedAnalysisAccess() && skinAnalysisManager.uploadedImages.count >= 3 {
                                        showLimitReachedBanner = true
                                    }
                                }
                            }) {
                                HStack {
                                    if skinAnalysisManager.isAnalyzing && !showAnalyzeSuccess {
                                        ProgressView().scaleEffect(0.8).tint(.white)
                                    } else if !showAnalyzeSuccess {
                                        Image(systemName: "sparkles")
                                    } else {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                    Text(showAnalyzeSuccess ? "Analyzed" : "Analyze Skin")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(showAnalyzeSuccess ? Color.green : (canAnalyzeNow ? Color(red: 0.45, green: 0.32, blue: 0.60) : Color.gray))
                                .cornerRadius(12)
                            }
                            .disabled(skinAnalysisManager.isAnalyzing || !canAnalyzeNow)
                            
                            // Loading bar + percent during analysis
                            if skinAnalysisManager.isAnalyzing {
                                VStack(spacing: 6) {
                                    GeometryReader { geometry in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.gray.opacity(0.25))
                                                .frame(height: 6)
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(NuraColors.primary)
                                                .frame(width: max(0, skinAnalysisManager.analysisProgress * geometry.size.width), height: 6)
                                                .animation(.easeInOut(duration: 0.25), value: skinAnalysisManager.analysisProgress)
                                        }
                                    }
                                    .frame(height: 6)
                                    Text("\(Int(skinAnalysisManager.analysisProgress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }

                            if shouldShowIssueHighlightsButton {
                                Button(action: {
                                    showIssueHighlightsSheet = true
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "photo.stack.fill")
                                        Text("See Highlighted Areas")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(
                                        LinearGradient(
                                            colors: isDark
                                            ? [Color(red: 0.22, green: 0.16, blue: 0.34), Color(red: 0.17, green: 0.12, blue: 0.29)]
                                            : [Color(red: 0.36, green: 0.25, blue: 0.56), Color(red: 0.26, green: 0.18, blue: 0.46)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .onChange(of: skinAnalysisManager.isAnalyzing) { oldValue, newValue in
                            if oldValue == true && newValue == false && skinAnalysisManager.analysisProgress >= 1.0 {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) { showAnalyzeSuccess = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    withAnimation { showAnalyzeSuccess = false }
                                }
                            }
                        }
                    }
                    
                    // Error message
                    if let errorMessage = skinAnalysisManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(isDark ? NuraColors.errorDark : NuraColors.error)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Photo quality tips and validation - moved to bottom
                    if skinAnalysisManager.uploadedImages.isEmpty {
                        PhotoQualityTipsView()
                    } else {
                        PhotoValidationView(
                            images: skinAnalysisManager.uploadedImages,
                            validationResults: photoValidationResults
                        )
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
        }
        .id(appearanceManager.colorSchemePreference)
        .onAppear {
            initializeValidation()
        }
        // Ensure the Live Scan sheet is always attachable regardless of conditional UI
        .sheet(isPresented: $showLiveAnalysis) {
            LiveSkinAnalysisView { images in
                // Replace current images with those returned from Live Scan
                skinAnalysisManager.uploadedImages = images
                analysisRequestDate = nil
                // Clear picker-related state
                selectedImages.removeAll()
                imageToPhotosPickerMapping.removeAll()
                // Re-validate all photos immediately so Photo Quality Check updates without leaving the page
                photoValidationResults.removeAll()
                Task {
                    for (index, image) in images.enumerated() {
                        let result = await validateSinglePhotoAsync(image)
                        await MainActor.run { photoValidationResults[index] = result }
                    }
                    print("✅ SkinAnalysisView: Live Scan images validated immediately (\(images.count))")
                }
            }
        }
        .sheet(isPresented: $showIssueHighlightsSheet) {
            SkinIssueHighlightsView(
                images: Array(skinAnalysisManager.uploadedImages.prefix(3)),
                conditions: validDetectedConditions
            )
            .environmentObject(appearanceManager)
        }
        .overlay(
            Group {
                if showPremiumBanner {
                    ComicBookPremiumBanner(
                        feature: .advancedSkinAnalysis,
                        userTierManager: userTierManager,
                        onUpgrade: {
                            print("Navigate to premium upgrade")
                        },
                        onDismiss: {
                            showPremiumBanner = false
                        }
                    )
                }
                
                if showLimitReachedBanner {
                    ComicBookPremiumBanner(
                        feature: .unlimitedAnalysis,
                        userTierManager: userTierManager,
                        onUpgrade: {
                            print("Navigate to premium upgrade")
                        },
                        onDismiss: {
                            showLimitReachedBanner = false
                        }
                    )
                }
            }
        )
    }

    // Handle images coming from Live Scan (kept for clarity if we later reuse)
    private func handleLiveScanImages(_ images: [UIImage]) {
        skinAnalysisManager.uploadedImages = images
        analysisRequestDate = nil
        selectedImages.removeAll()
        imageToPhotosPickerMapping.removeAll()
        photoValidationResults.removeAll()
        Task {
            for (index, image) in images.enumerated() {
                let validationResult = await validateSinglePhotoAsync(image)
                await MainActor.run { photoValidationResults[index] = validationResult }
            }
            print("✅ SkinAnalysisView: handleLiveScanImages validated \(images.count) images")
        }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        var loadedImages: [UIImage] = []
        var newMapping: [Int: PhotosPickerItem] = [:]
        
        for (index, item) in items.enumerated() {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loadedImages.append(image)
                newMapping[index] = item
            }
        }
        
        DispatchQueue.main.async {
            analysisRequestDate = nil
            // Clear existing validation results when new images are loaded
            photoValidationResults.removeAll()
            
            // Replace all images with new selection
            skinAnalysisManager.uploadedImages = loadedImages
            
            // Update the mapping
            imageToPhotosPickerMapping = newMapping
            
            // Validate all images asynchronously
            Task {
                for (index, image) in loadedImages.enumerated() {
                    let validationResult = await validateSinglePhotoAsync(image)
                    await MainActor.run {
                        photoValidationResults[index] = validationResult
                    }
                }
                
                // IMPORTANT: Do NOT automatically trigger analysis here
                // Analysis should only be triggered when the user presses the "Analyze" button
                print("✅ SkinAnalysisView: Validation completed for \(loadedImages.count) images. Waiting for user to press Analyze button.")
            }
        }
    }
    
    // Initialize validation for existing images when view appears
    private func initializeValidation() {
        guard photoValidationResults.isEmpty else { return }
        
        // Validate existing images asynchronously
        Task {
            for (index, image) in skinAnalysisManager.uploadedImages.enumerated() {
                let validationResult = await validateSinglePhotoAsync(image)
                await MainActor.run {
                    photoValidationResults[index] = validationResult
                }
            }
            
            // IMPORTANT: Do NOT automatically trigger analysis here
            // Analysis should only be triggered when the user presses the "Analyze" button
            print("✅ SkinAnalysisView: Initialization validation completed for \(skinAnalysisManager.uploadedImages.count) images. Waiting for user to press Analyze button.")
        }
    }
    
    private func removePhoto(at index: Int) {
        // Validate index bounds
        guard index >= 0 && index < skinAnalysisManager.uploadedImages.count else {
            print("⚠️ Invalid photo index: \(index), total photos: \(skinAnalysisManager.uploadedImages.count)")
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            analysisRequestDate = nil
            // Get the PhotosPicker item that corresponds to this image
            let photosPickerItem = imageToPhotosPickerMapping[index]
            
            // Remove the specific photo at the given index
            skinAnalysisManager.uploadedImages.remove(at: index)
            
            // Remove the corresponding PhotosPicker item if we have it mapped
            if let item = photosPickerItem {
                if let itemIndex = selectedImages.firstIndex(where: { $0 == item }) {
                    selectedImages.remove(at: itemIndex)
                    print("🗑️ Removed PhotosPicker item at index \(itemIndex)")
                }
            }
            
            // Update the mapping for remaining images
            var newMapping: [Int: PhotosPickerItem] = [:]
            for (oldIndex, item) in imageToPhotosPickerMapping {
                if oldIndex < index {
                    // Keep items before the removed index
                    newMapping[oldIndex] = item
                } else if oldIndex > index {
                    // Shift items after the removed index
                    newMapping[oldIndex - 1] = item
                }
                // Skip the removed index
            }
            imageToPhotosPickerMapping = newMapping
            
            // Clear all validation results since indices will change
            photoValidationResults.removeAll()
            
            // Re-validate remaining images with new indices
            Task {
                for (index, image) in skinAnalysisManager.uploadedImages.enumerated() {
                    let validationResult = await validateSinglePhotoAsync(image)
                    await MainActor.run {
                        photoValidationResults[index] = validationResult
                    }
                }
            }
            
            print("🗑️ Removed photo at index \(index), remaining photos: \(skinAnalysisManager.uploadedImages.count)")
        }
    }
    
    // Asynchronous photo validation function using Vision framework
    private func validateSinglePhotoAsync(_ image: UIImage) async -> PhotoValidationResult {
        // Smart client-side validation without expensive API calls
        let size = image.size
        
        // Check if image is too small (basic quality check)
        if size.width < 300 || size.height < 300 {
            return PhotoValidationResult(
                isValid: false,
                message: "Image too small for accurate analysis"
            )
        }
        
        // Basic brightness check (very rough estimate)
        if let cgImage = image.cgImage {
            let width = cgImage.width
            let height = cgImage.height
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            let bitsPerComponent = 8
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            
            guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
                return PhotoValidationResult(isValid: true, message: "Image quality looks good for analysis")
            }
            
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            
            if let data = context.data {
                let buffer = data.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
                var totalBrightness: Double = 0
                let sampleSize = min(width * height, 1000) // Sample up to 1000 pixels for performance
                
                for i in stride(from: 0, to: sampleSize, by: 10) {
                    let pixelIndex = i * bytesPerPixel
                    if pixelIndex + 2 < width * height * bytesPerPixel {
                        let r = Double(buffer[pixelIndex])
                        let g = Double(buffer[pixelIndex + 1])
                        let b = Double(buffer[pixelIndex + 2])
                        totalBrightness += (r + g + b) / 3.0 // Average brightness
                    }
                }
                
                let averageBrightness = totalBrightness / Double(sampleSize / 10)
                
                // Check if image is too dark or too bright
                if averageBrightness < 30 {
                    return PhotoValidationResult(
                        isValid: false,
                        message: "Image too dark - use better lighting"
                    )
                } else if averageBrightness > 220 {
                    return PhotoValidationResult(
                        isValid: false,
                        message: "Image too bright - avoid overexposure"
                    )
                }
                
                // Use Vision framework for accurate face detection and orientation
                let faceDetectionResult = await detectFaceWithVisionAsync(image: image)
                if let result = faceDetectionResult {
                    print("✅ Vision framework detected face: \(result.message)")
                    return result
                }
                
                // Fallback: Basic face detection using image analysis
                let basicFaceResult = await basicFaceDetectionFallback(image: image)
                if let result = basicFaceResult {
                    print("✅ Custom algorithm detected face: \(result.message)")
                    return result
                }
                
                // Final fallback: Enhanced face detection with lower thresholds
                let enhancedFaceResult = await enhancedFaceDetectionFallback(image: image)
                if let result = enhancedFaceResult {
                    print("✅ Enhanced algorithm detected face: \(result.message)")
                    return result
                }
            }
        }
        
        // If all checks pass, return success
        return PhotoValidationResult(
            isValid: true,
            message: "Image quality looks good for analysis"
        )
    }
    
    // Enhanced face detection using Vision framework (free, built into iOS)
    private func detectFaceWithVisionAsync(image: UIImage) async -> PhotoValidationResult? {
        guard let cgImage = image.cgImage else { 
            print("⚠️ Vision framework: Failed to get CGImage")
            return nil 
        }
        
        return await withCheckedContinuation { continuation in
            let semaphore = DispatchSemaphore(value: 0)
            var result: PhotoValidationResult?
            
            // Use basic face detection first (more reliable in simulator)
            let request = VNDetectFaceRectanglesRequest { request, error in
                defer {
                    semaphore.signal()
                }
                
                if let error = error {
                    // Suppress known simulator errors (Error Code 1: cancelled, Error Code 9: inference context)
                    #if !targetEnvironment(simulator)
                    print("⚠️ Vision framework error: \(error)")
                    #else
                    // In simulator, these errors are expected due to Neural Engine limitations
                    if let nsError = error as NSError?, nsError.code == 1 || nsError.code == 9 {
                        print("ℹ️ Vision framework simulator limitation (expected): \(error.localizedDescription)")
                    } else {
                        print("⚠️ Vision framework error: \(error)")
                    }
                    #endif
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation] else {
                    print("⚠️ Vision framework: No face observations returned")
                    return
                }
                
                print("🔍 Vision framework found \(observations.count) faces")
                
                if observations.isEmpty {
                    // No faces detected - this might be an inanimate object
                    result = PhotoValidationResult(
                        isValid: false,
                        message: "No face detected - please take a selfie"
                    )
                    print("⚠️ Vision framework: No faces detected")
                    return
                }
                
                // Multiple faces detected
                if observations.count > 1 {
                    result = PhotoValidationResult(
                        isValid: false,
                        message: "Multiple faces detected - please take a single selfie"
                    )
                    print("⚠️ Vision framework: Multiple faces detected (\(observations.count))")
                    return
                }
                
                guard let firstFace = observations.first else {
                    print("⚠️ Vision framework: Failed to get first face observation")
                    return
                }
                
                print("✅ Vision framework: Face detected successfully")
                // Read a lightweight property so the binding is meaningfully used
                let _ = firstFace.boundingBox
                
                // Simplified message - just face detection without orientation
                result = PhotoValidationResult(
                    isValid: true,
                    message: "Face detected"
                )
                print("✅ Vision framework result: Face detected")
            }
            
            // Configure for simulator compatibility
            #if targetEnvironment(simulator)
            request.usesCPUOnly = true
            #endif
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                print("🔍 Starting Vision framework face detection...")
                try handler.perform([request])
            } catch {
                // Suppress known simulator errors during perform
                #if !targetEnvironment(simulator)
                print("⚠️ Vision framework error during perform: \(error)")
                #else
                if let nsError = error as NSError?, nsError.code == 9 {
                    print("ℹ️ Vision framework simulator limitation during perform (expected): \(error.localizedDescription)")
                } else {
                    print("⚠️ Vision framework error during perform: \(error)")
                }
                #endif
                semaphore.signal()
            }
            
            // Wait for the Vision framework to complete with a timeout
            let timeoutResult = semaphore.wait(timeout: .now() + 10.0) // Increased timeout to 10 seconds
            
            if timeoutResult == .timedOut {
                print("⚠️ Vision framework timeout - falling back to basic validation")
                continuation.resume(returning: nil)
            } else {
                // Resume with the result (or nil if no result was set)
                print("🔍 Vision framework completed with result: \(result?.message ?? "nil")")
                continuation.resume(returning: result)
            }
        }
    }
    
    // Simple face orientation analysis for basic detection
    private func analyzeBasicFaceOrientation(faceObservation: VNFaceObservation) -> String {
        let faceBounds = faceObservation.boundingBox
        let centerX = faceBounds.midX
        let threshold = 0.2 // Conservative threshold to avoid false classifications
        
        print("🔍 Face bounds: centerX=\(centerX), width=\(faceBounds.width), height=\(faceBounds.height)")
        
        // Vision framework coordinates: (0,0) is bottom-left, (1,1) is top-right
        // For face orientation:
        // - If face center is significantly LEFT (centerX < 0.5 - threshold), person is likely looking RIGHT
        // - If face center is significantly RIGHT (centerX > 0.5 + threshold), person is likely looking LEFT
        // - This is because when you look left, your face shifts to the right side of the frame
        
        if centerX < 0.5 - threshold {
            print("🔍 Face positioned left in frame (centerX=\(centerX)) → Person looking RIGHT")
            return "right"
        } else if centerX > 0.5 + threshold {
            print("🔍 Face positioned right in frame (centerX=\(centerX)) → Person looking LEFT")
            return "left"
        } else {
            print("🔍 Face centered in frame (centerX=\(centerX)) → Person looking CENTER")
            return "center"
        }
    }
    
    // Fallback face detection using basic image analysis
    private func basicFaceDetectionFallback(image: UIImage) async -> PhotoValidationResult? {
        print("🔍 Starting basic face detection fallback...")
        guard let cgImage = image.cgImage else { 
            print("⚠️ Basic fallback: Failed to get CGImage")
            return nil 
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        print("🔍 Basic fallback: Image dimensions \(width)x\(height)")
        
        // Basic face detection heuristics
        let faceDetectionResult = await analyzeImageForFacePatterns(cgImage: cgImage, width: width, height: height)
        
        print("🔍 Basic fallback result: hasFace=\(faceDetectionResult.hasFace), orientation=\(faceDetectionResult.orientation)")
        
        if faceDetectionResult.hasFace {
            return PhotoValidationResult(
                isValid: true,
                message: "Face detected"
            )
        } else {
            return PhotoValidationResult(
                isValid: false,
                message: "No face detected - please take a selfie"
            )
        }
    }
    
    // Advanced image analysis for face patterns
    private func analyzeImageForFacePatterns(cgImage: CGImage, width: Int, height: Int) async -> (hasFace: Bool, orientation: String) {
        // Create a smaller version for analysis (performance optimization)
        let targetSize = CGSize(width: 200, height: 200)
        let scale = min(targetSize.width / CGFloat(width), targetSize.height / CGFloat(height))
        let scaledWidth = Int(CGFloat(width) * scale)
        let scaledHeight = Int(CGFloat(height) * scale)
        
        print("🔍 Analyzing image patterns: original \(width)x\(height) -> scaled \(scaledWidth)x\(scaledHeight)")
        
        guard let context = CGContext(data: nil, width: scaledWidth, height: scaledHeight, bitsPerComponent: 8, bytesPerRow: scaledWidth * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            print("⚠️ Failed to create CGContext for face analysis")
            return (false, "unknown")
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
        
        guard let data = context.data else {
            print("⚠️ Failed to get image data for face analysis")
            return (false, "unknown")
        }
        
        let buffer = data.bindMemory(to: UInt8.self, capacity: scaledWidth * scaledHeight * 4)
        
        // Analyze image for face-like patterns
        let faceScore = await calculateFaceLikelihood(buffer: buffer, width: scaledWidth, height: scaledHeight)
        let orientation = await determineFaceOrientation(buffer: buffer, width: scaledWidth, height: scaledHeight)
        
        // Lower threshold for face detection (30% instead of 60%)
        let hasFace = faceScore > 0.3
        
        print("🔍 Face analysis: score=\(faceScore), threshold=0.3, hasFace=\(hasFace)")
        
        return (hasFace, orientation)
    }
    
    // Calculate likelihood that image contains a face
    private func calculateFaceLikelihood(buffer: UnsafePointer<UInt8>, width: Int, height: Int) async -> Double {
        var faceScore = 0.0
        let totalPixels = width * height
        
        // Sample pixels for analysis
        let sampleSize = min(totalPixels, 1000)
        let step = max(1, totalPixels / sampleSize)
        
        var skinTonePixels = 0
        
        for i in stride(from: 0, to: totalPixels, by: step) {
            let pixelIndex = i * 4
            if pixelIndex + 2 < totalPixels * 4 {
                let r = Double(buffer[pixelIndex])
                let g = Double(buffer[pixelIndex + 1])
                let b = Double(buffer[pixelIndex + 2])
                
                // Skin tone detection (basic heuristic)
                let isSkinTone = detectSkinTone(r: r, g: g, b: b)
                if isSkinTone {
                    skinTonePixels += 1
                    faceScore += 1.0
                }
                
                // Edge detection for facial features
                let edgeScore = detectEdges(buffer: buffer, pixelIndex: pixelIndex, width: width, height: height)
                faceScore += edgeScore
            }
        }
        
        let skinToneRatio = Double(skinTonePixels) / Double(sampleSize)
        let finalScore = min(faceScore / Double(sampleSize), 1.0)
        
        print("🔍 Face likelihood: skinTonePixels=\(skinTonePixels)/\(sampleSize) (\(skinToneRatio)), finalScore=\(finalScore)")
        
        return finalScore
    }
    
    // Detect skin tone in RGB values
    private func detectSkinTone(r: Double, g: Double, b: Double) -> Bool {
        // Basic skin tone detection algorithm
        let rNorm = r / 255.0
        let gNorm = g / 255.0
        let bNorm = b / 255.0
        
        // Skin tone typically has R > G > B and specific ranges
        let isRedDominant = rNorm > gNorm && gNorm > bNorm
        let redInRange = rNorm > 0.4 && rNorm < 0.9
        let greenInRange = gNorm > 0.2 && gNorm < 0.8
        let blueInRange = bNorm > 0.1 && bNorm < 0.7
        
        return isRedDominant && redInRange && greenInRange && blueInRange
    }
    
    // Detect edges for facial features
    private func detectEdges(buffer: UnsafePointer<UInt8>, pixelIndex: Int, width: Int, height: Int) -> Double {
        // Simple edge detection using neighboring pixels
        let x = (pixelIndex / 4) % width
        let y = (pixelIndex / 4) / width
        
        if x > 0 && x < width - 1 && y > 0 && y < height - 1 {
            let current = Double(buffer[pixelIndex])
            let left = Double(buffer[pixelIndex - 4])
            let right = Double(buffer[pixelIndex + 4])
            let top = Double(buffer[pixelIndex - width * 4])
            let bottom = Double(buffer[pixelIndex + width * 4])
            
            let horizontalGradient = abs(current - left) + abs(current - right)
            let verticalGradient = abs(current - top) + abs(current - bottom)
            
            let edgeStrength = (horizontalGradient + verticalGradient) / 510.0 // Normalize to 0-1
            return edgeStrength * 0.1 // Small contribution to face score
        }
        
        return 0.0
    }
    
    // Determine face orientation from image analysis
    private func determineFaceOrientation(buffer: UnsafePointer<UInt8>, width: Int, height: Int) async -> String {
        var leftScore = 0.0
        var centerScore = 0.0
        var rightScore = 0.0
        
        let leftRegion = width / 3
        let rightRegion = 2 * width / 3
        
        // Sample pixels from different regions
        let sampleSize = min(width * height, 500)
        let step = max(1, width * height / sampleSize)
        
        for i in stride(from: 0, to: width * height, by: step) {
            let pixelIndex = i * 4
            let x = i % width
            
            if pixelIndex + 2 < width * height * 4 {
                let r = Double(buffer[pixelIndex])
                let g = Double(buffer[pixelIndex + 1])
                let b = Double(buffer[pixelIndex + 2])
                
                let isSkinTone = detectSkinTone(r: r, g: g, b: b)
                if isSkinTone {
                    // Weight skin tone pixels by their horizontal position
                    if x < leftRegion {
                        leftScore += 1.0
                    } else if x > rightRegion {
                        rightScore += 1.0
                    } else {
                        centerScore += 1.0
                    }
                }
            }
        }
        
        print("🔍 Custom orientation scores - Left: \(leftScore), Center: \(centerScore), Right: \(rightScore)")
        
        // Determine orientation based on highest score
        let maxScore = max(leftScore, max(centerScore, rightScore))
        let threshold = 1.3 // Conservative threshold to avoid false classifications
        
        // Apply the SAME corrected logic as Vision framework:
        // If most skin pixels are on the LEFT side of image, person is looking RIGHT
        // If most skin pixels are on the RIGHT side of image, person is looking LEFT
        if maxScore == leftScore && leftScore > centerScore * threshold {
            print("🔍 Most skin pixels on left side → Person looking RIGHT")
            return "right"
        } else if maxScore == rightScore && rightScore > centerScore * threshold {
            print("🔍 Most skin pixels on right side → Person looking LEFT")
            return "left"
        } else {
            print("🔍 Skin pixels centered → Person looking CENTER")
            return "center"
        }
    }
    
    // Analyze face orientation using facial landmarks (Vision framework)
    private func analyzeFaceOrientationAdvanced(faceObservation: VNFaceObservation) -> String {
        // Get face bounds and landmarks
        let faceBounds = faceObservation.boundingBox
        
        // Check if we have facial landmarks for more accurate orientation
        if let landmarks = faceObservation.landmarks {
            // Use nose position for orientation
            if let nose = landmarks.nose {
                let nosePoints = nose.normalizedPoints
                if !nosePoints.isEmpty {
                    let noseX = nosePoints.map { Float($0.x) }.reduce(0, +) / Float(nosePoints.count)
                    
                    // Determine orientation based on nose position
                    if noseX < 0.4 {
                        return "left"
                    } else if noseX > 0.6 {
                        return "right"
                    } else {
                        return "center"
                    }
                }
            }
            
            // Fallback to eyes position
            if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
                let leftEyePoints = leftEye.normalizedPoints
                let rightEyePoints = rightEye.normalizedPoints
                
                if !leftEyePoints.isEmpty && !rightEyePoints.isEmpty {
                    let leftEyeX = leftEyePoints.map { Float($0.x) }.reduce(0, +) / Float(leftEyePoints.count)
                    let rightEyeX = rightEyePoints.map { Float($0.x) }.reduce(0, +) / Float(rightEyePoints.count)
                    
                    let eyeCenterX = (leftEyeX + rightEyeX) / 2.0
                    
                    if eyeCenterX < 0.4 {
                        return "left"
                    } else if eyeCenterX > 0.6 {
                        return "right"
                    } else {
                        return "center"
                    }
                }
            }
        }
        
        // Fallback to bounding box analysis
        let centerX = faceBounds.midX
        let threshold = 0.1 // 10% threshold
        
        if centerX < 0.5 - threshold {
            return "left"
        } else if centerX > 0.5 + threshold {
            return "right"
        } else {
            return "center"
        }
    }
    
    // Enhanced face detection with lower thresholds and better algorithms
    private func enhancedFaceDetectionFallback(image: UIImage) async -> PhotoValidationResult? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        
        // Create a smaller version for analysis (performance optimization)
        let targetSize = CGSize(width: 300, height: 300) // Increased from 200x200
        let scale = min(targetSize.width / CGFloat(width), targetSize.height / CGFloat(height))
        let scaledWidth = Int(CGFloat(width) * scale)
        let scaledHeight = Int(CGFloat(height) * scale)
        
        guard let context = CGContext(data: nil, width: scaledWidth, height: scaledHeight, bitsPerComponent: 8, bytesPerRow: scaledWidth * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight))
        
        guard let data = context.data else {
            return nil
        }
        
        let buffer = data.bindMemory(to: UInt8.self, capacity: scaledWidth * scaledHeight * 4)
        
        // Enhanced face detection with multiple algorithms
        let faceScore = await calculateEnhancedFaceLikelihood(buffer: buffer, width: scaledWidth, height: scaledHeight)
        let orientation = await determineEnhancedFaceOrientation(buffer: buffer, width: scaledWidth, height: scaledHeight)
        
        // Lower threshold for enhanced detection (40% instead of 60%)
        let hasFace = faceScore > 0.4
        
        print("🔍 Enhanced face detection - Score: \(faceScore), Has Face: \(hasFace), Orientation: \(orientation)")
        
        if hasFace {
            return PhotoValidationResult(
                isValid: true,
                message: "Face detected"
            )
        } else {
            return PhotoValidationResult(
                isValid: false,
                message: "No face detected - please take a selfie"
            )
        }
    }
    
    // Enhanced face likelihood calculation with multiple detection methods
    private func calculateEnhancedFaceLikelihood(buffer: UnsafePointer<UInt8>, width: Int, height: Int) async -> Double {
        var faceScore = 0.0
        let totalPixels = width * height
        
        // Sample pixels for analysis
        let sampleSize = min(totalPixels, 1500) // Increased sample size
        let step = max(1, totalPixels / sampleSize)
        
        var skinToneCount = 0
        var edgeScore = 0.0
        var symmetryScore = 0.0
        
        for i in stride(from: 0, to: totalPixels, by: step) {
            let pixelIndex = i * 4
            if pixelIndex + 2 < totalPixels * 4 {
                let r = Double(buffer[pixelIndex])
                let g = Double(buffer[pixelIndex + 1])
                let b = Double(buffer[pixelIndex + 2])
                
                // Enhanced skin tone detection
                let isSkinTone = detectEnhancedSkinTone(r: r, g: g, b: b)
                if isSkinTone {
                    skinToneCount += 1
                    faceScore += 1.0
                }
                
                // Enhanced edge detection for facial features
                let pixelEdgeScore = detectEnhancedEdges(buffer: buffer, pixelIndex: pixelIndex, width: width, height: height)
                edgeScore += pixelEdgeScore
                
                // Symmetry detection (faces are typically symmetrical)
                let pixelSymmetryScore = detectSymmetry(buffer: buffer, pixelIndex: pixelIndex, width: width, height: height)
                symmetryScore += pixelSymmetryScore
            }
        }
        
        // Calculate final score with multiple factors
        let skinToneRatio = Double(skinToneCount) / Double(sampleSize)
        let averageEdgeScore = edgeScore / Double(sampleSize)
        let averageSymmetryScore = symmetryScore / Double(sampleSize)
        
        // Weighted combination of different detection methods
        let finalScore = (skinToneRatio * 0.5) + (averageEdgeScore * 0.3) + (averageSymmetryScore * 0.2)
        
        print("🔍 Face detection breakdown - Skin: \(skinToneRatio), Edge: \(averageEdgeScore), Symmetry: \(averageSymmetryScore), Final: \(finalScore)")
        
        return min(finalScore, 1.0)
    }
    
    // Enhanced skin tone detection with broader ranges
    private func detectEnhancedSkinTone(r: Double, g: Double, b: Double) -> Bool {
        let rNorm = r / 255.0
        let gNorm = g / 255.0
        let bNorm = b / 255.0
        
        // Broader skin tone ranges to catch more variations
        let isRedDominant = rNorm > gNorm && gNorm > bNorm
        let redInRange = rNorm > 0.3 && rNorm < 0.95  // Expanded range
        let greenInRange = gNorm > 0.15 && gNorm < 0.85 // Expanded range
        let blueInRange = bNorm > 0.05 && bNorm < 0.75  // Expanded range
        
        // Additional check for different skin tones
        let isWarmTone = rNorm > 0.4 && gNorm > 0.2 && bNorm < 0.6
        let isMediumTone = rNorm > 0.35 && gNorm > 0.25 && bNorm < 0.7
        
        return (isRedDominant && redInRange && greenInRange && blueInRange) || isWarmTone || isMediumTone
    }
    
    // Enhanced edge detection
    private func detectEnhancedEdges(buffer: UnsafePointer<UInt8>, pixelIndex: Int, width: Int, height: Int) -> Double {
        let x = (pixelIndex / 4) % width
        let y = (pixelIndex / 4) / width
        
        if x > 1 && x < width - 2 && y > 1 && y < height - 2 {
            let current = Double(buffer[pixelIndex])
            let left = Double(buffer[pixelIndex - 4])
            let right = Double(buffer[pixelIndex + 4])
            let top = Double(buffer[pixelIndex - width * 4])
            let bottom = Double(buffer[pixelIndex + width * 4])
            
            let horizontalGradient = abs(current - left) + abs(current - right)
            let verticalGradient = abs(current - top) + abs(current - bottom)
            
            let edgeStrength = (horizontalGradient + verticalGradient) / 510.0
            return edgeStrength * 0.2 // Increased contribution
        }
        
        return 0.0
    }
    
    // Symmetry detection for faces
    private func detectSymmetry(buffer: UnsafePointer<UInt8>, pixelIndex: Int, width: Int, height: Int) -> Double {
        let x = (pixelIndex / 4) % width
        let y = (pixelIndex / 4) / width
        
        // Check for symmetry around the center
        let mirrorX = width - 1 - x
        
        if mirrorX < width && mirrorX >= 0 {
            let currentPixel = pixelIndex
            let mirrorPixel = mirrorX + y * width
            
            if mirrorPixel * 4 + 2 < width * height * 4 {
                let current = Double(buffer[currentPixel])
                let mirror = Double(buffer[mirrorPixel * 4])
                
                // Calculate symmetry score (lower difference = higher symmetry)
                let difference = abs(current - mirror)
                let symmetryScore = max(0, 1.0 - (difference / 255.0))
                return symmetryScore * 0.1
            }
        }
        
        return 0.0
    }
    
    // Enhanced face orientation detection
    private func determineEnhancedFaceOrientation(buffer: UnsafePointer<UInt8>, width: Int, height: Int) async -> String {
        var leftScore = 0.0
        var centerScore = 0.0
        var rightScore = 0.0
        
        let leftRegion = width / 3
        let rightRegion = 2 * width / 3
        
        // Sample pixels from different regions
        let sampleSize = min(width * height, 800) // Increased sample size
        let step = max(1, width * height / sampleSize)
        
        for i in stride(from: 0, to: width * height, by: step) {
            let pixelIndex = i * 4
            let x = i % width
            
            if pixelIndex + 2 < width * height * 4 {
                let r = Double(buffer[pixelIndex])
                let g = Double(buffer[pixelIndex + 1])
                let b = Double(buffer[pixelIndex + 2])
                
                let isSkinTone = detectEnhancedSkinTone(r: r, g: g, b: b)
                if isSkinTone {
                    // Weight skin tone pixels by position
                    if x < leftRegion {
                        leftScore += 1.0
                    } else if x > rightRegion {
                        rightScore += 1.0
                    } else {
                        centerScore += 1.0
                    }
                }
            }
        }
        
        print("🔍 Enhanced orientation scores - Left: \(leftScore), Center: \(centerScore), Right: \(rightScore)")
        
        // Determine orientation based on highest score
        let maxScore = max(leftScore, max(centerScore, rightScore))
        let threshold = 1.2 // Conservative threshold to avoid false classifications
        
        // Apply the SAME corrected logic as Vision framework:
        // If most skin pixels are on the LEFT side of image, person is looking RIGHT
        // If most skin pixels are on the RIGHT side of image, person is looking LEFT
        if maxScore == leftScore && leftScore > centerScore * threshold {
            print("🔍 Enhanced: Most skin pixels on left side → Person looking RIGHT")
            return "right"
        } else if maxScore == rightScore && rightScore > centerScore * threshold {
            print("🔍 Enhanced: Most skin pixels on right side → Person looking LEFT")
            return "left"
        } else {
            print("🔍 Enhanced: Skin pixels centered → Person looking CENTER")
            return "center"
        }
    }
    
    // Removed fake progress; progress is bound to SkinAnalysisManager
    private var validDetectedConditions: [SkinCondition] {
        guard let result = skinAnalysisManager.analysisResults else { return [] }
        return result.conditions.filter { condition in
            let lowerName = condition.name.lowercased()
            let isFallback = lowerName.contains("analysis failed") ||
                lowerName.contains("review required") ||
                lowerName.contains("analysis completed")
            return !isFallback
        }
    }

    private var shouldShowIssueHighlightsButton: Bool {
        guard skinAnalysisManager.uploadedImages.count == 3 else { return false }
        guard !skinAnalysisManager.isAnalyzing else { return false }
        guard let requestedAt = analysisRequestDate else { return false }
        guard let result = skinAnalysisManager.analysisResults else { return false }
        return result.imageCount == 3 && result.analysisDate >= requestedAt
    }

    private var isDark: Bool { 
        appearanceManager.colorSchemePreference == "dark" || 
        (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark) 
    }
}

















// MARK: - New Simplified Analysis Summary View

struct AnalysisSummaryView: View {
    let results: SkinAnalysisResult
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Message
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(NuraColors.success)
                
                Text("Analysis Complete! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                
                Text("Your skin has been analyzed using AI")
                    .font(.subheadline)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
            }
            
            // Skin Health Score
            VStack(spacing: 16) {
                Text("Skin Health Score")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                
                HStack(spacing: 20) {
                    // Score Circle
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: Double(results.skinHealthScore) / 100.0)
                            .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 80, height: 80)
                        
                        VStack(spacing: 2) {
                            Text("\(results.skinHealthScore)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(scoreColor)
                            
                            Text("out of 100")
                                .font(.caption2)
                                .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                        }
                    }
                    
                    // Confidence Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Analysis Confidence")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                        
                        Text("\(Int(results.confidence * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(confidenceColor)
                        
                        Text("High confidence means better accuracy")
                            .font(.caption)
                            .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                    }
                }
            }
            .padding()
            .background(isDark ? NuraColors.cardDark : NuraColors.card.opacity(0.1))
            .cornerRadius(16)
            
            // Photo Quality Tips
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text("Tips for Better Results")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("• Use natural lighting (avoid harsh shadows)")
                        .font(.caption)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                    
                    Text("• Keep your face centered and clearly visible")
                        .font(.caption)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                    
                    Text("• Remove glasses, hats, and heavy makeup")
                        .font(.caption)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.7))
                    
                    Text("• Higher confidence = more accurate analysis")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(NuraColors.primary)
                }
            }
            .padding()
            .background(isDark ? NuraColors.cardDark.opacity(0.5) : Color.yellow.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.horizontal)
    }
    
    private var scoreColor: Color {
        switch results.skinHealthScore {
        case 80...100: return NuraColors.success
        case 60..<80: return .orange
        case 40..<60: return .yellow
        default: return NuraColors.error
        }
    }
    
    private var confidenceColor: Color {
        switch results.confidence {
        case 0.8...1.0: return NuraColors.success
        case 0.6..<0.8: return .orange
        default: return .yellow
        }
    }
    
    private var isDark: Bool { 
        appearanceManager.colorSchemePreference == "dark" || 
        (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark) 
    }
}

// MARK: - Camera Capture
struct CameraCaptureView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UIImagePickerController
    var onCapture: (UIImage?) -> Void
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraCaptureView
        init(_ parent: CameraCaptureView) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            let image = info[.originalImage] as? UIImage
            picker.dismiss(animated: true) { self.parent.onCapture(image) }
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) { self.parent.onCapture(nil) }
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// MARK: - Photo Quality Components

struct PhotoQualityTipsView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                
                Text("Tips for Best Results")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("• Take clear selfies of your FACE only")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Text("• Use a well-lit room (natural light is best)")
                    .font(.caption)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.85))
                
                Text("• Remove glasses, hats, and heavy makeup")
                    .font(.caption)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.85))
                
                Text("• Keep your face centered and clearly visible")
                    .font(.caption)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.85))
                
                Text("• Take a front, left, and right side photo")
                    .font(.caption)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : Color.primary.opacity(0.85))
                
                Text("⚠️ Photos must show your face clearly for skin analysis")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(isDark ? NuraColors.cardDark.opacity(0.5) : Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var isDark: Bool { 
        appearanceManager.colorSchemePreference == "dark" || 
        (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark) 
    }
}

struct PhotoValidationView: View {
    let images: [UIImage]
    let validationResults: [Int: PhotoValidationResult]
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: overallValidationIcon)
                    .foregroundColor(overallValidationColor)
                    .font(.caption)
                
                Text("Photo Quality Check")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("📸 \(images.count) photos uploaded")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                // Show validation results for each photo
                ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                    HStack(spacing: 6) {
                        let result = validationResults[index] ?? PhotoValidationResult(isValid: false, message: "Validating...")
                        
                        Image(systemName: result.isValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(result.isValid ? .green : .orange)
                            .font(.caption2)
                        
                        Text("Photo \(index + 1): \(result.message)")
                            .font(.caption)
                            .foregroundColor(result.isValid ? .green : .orange)
                    }
                }
                
                // Overall assessment
                HStack(spacing: 6) {
                    Image(systemName: overallValidationIcon)
                        .foregroundColor(overallValidationColor)
                        .font(.caption2)
                    
                    Text(overallValidationMessage)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(overallValidationColor)
                }
                
                // Helpful tip
                if overallValidationColor == .orange {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                        
                        Text("Tip: Better lighting and clear face visibility improve analysis accuracy")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(isDark ? NuraColors.cardDark.opacity(0.5) : overallValidationColor.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var isDark: Bool { 
        appearanceManager.colorSchemePreference == "dark" || 
        (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark) 
    }
    
    private var overallValidationColor: Color {
        let validCount = validationResults.values.filter { $0.isValid }.count
        if validCount == images.count { return .green }
        if validCount > 0 { return .orange }
        return .red
    }
    
    private var overallValidationIcon: String {
        let validCount = validationResults.values.filter { $0.isValid }.count
        if validCount == images.count { return "checkmark.circle.fill" }
        if validCount > 0 { return "exclamationmark.triangle.fill" }
        return "xmark.circle.fill"
    }
    
    private var overallValidationMessage: String {
        let validCount = validationResults.values.filter { $0.isValid }.count
        if validCount == images.count { return "All photos are ready for analysis" }
        if validCount > 0 { return "Some photos need improvement" }
        return "Photos need significant improvement"
    }
}

struct PhotoValidationResult {
    let isValid: Bool
    let message: String
}

private struct ConditionOverlayRegion: Identifiable {
    enum HighlightStyle {
        case acne
        case oily
        case contour
    }

    let id = UUID()
    let conditionName: String
    let areaName: String
    let color: Color
    let normalizedRect: CGRect
    let style: HighlightStyle
}

struct SkinIssueHighlightsView: View {
    let images: [UIImage]
    let conditions: [SkinCondition]

    @EnvironmentObject var appearanceManager: AppearanceManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImageIndex: Int = 0
    @State private var faceLayouts: [Int: FaceOverlayLayout] = [:]

    private let issueColors: [Color] = [
        Color(red: 0.89, green: 0.36, blue: 0.36),
        Color(red: 0.95, green: 0.62, blue: 0.20),
        Color(red: 0.34, green: 0.67, blue: 0.99),
        Color(red: 0.51, green: 0.42, blue: 0.93),
        Color(red: 0.31, green: 0.78, blue: 0.64),
        Color(red: 0.98, green: 0.44, blue: 0.70)
    ]

    enum PhotoPose {
        case front
        case sideLeft
        case sideRight
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                if images.isEmpty {
                    VStack(spacing: 8) {
                        Text("No photos available yet.")
                            .font(.headline)
                        Text("Add and analyze 3 photos to view detailed highlights.")
                            .font(.caption)
                            .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(Array(images.prefix(3).enumerated()), id: \.offset) { index, image in
                            LuxeHighlightedImageSlide(
                                image: image,
                                title: photoTitle(for: index),
                                index: index,
                                total: min(images.count, 3),
                                regions: overlayRegions(for: index)
                            )
                            .padding(.horizontal, 14)
                            .padding(.top, 8)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .frame(maxHeight: .infinity)
                }

                issueLegendCard
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }
            .background(
                LinearGradient(
                    colors: isDark
                    ? [Color(red: 0.11, green: 0.09, blue: 0.16), Color(red: 0.15, green: 0.11, blue: 0.20)]
                    : [Color(red: 0.95, green: 0.93, blue: 0.98), Color(red: 0.92, green: 0.89, blue: 0.97)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Issue Highlights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await computeFaceLayouts()
        }
    }

    private var issueLegendCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Issue Colors")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)

            if conditions.isEmpty {
                Text("No visible concerns were flagged in this analysis.")
                    .font(.caption)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
            } else {
                ForEach(Array(conditions.enumerated()), id: \.element.id) { index, condition in
                    HStack(spacing: 9) {
                        Circle()
                            .fill(issueColors[index % issueColors.count])
                            .frame(width: 10, height: 10)
                        Text(condition.name.capitalized)
                            .font(.caption)
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                        Spacer()
                        Text(condition.severity.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(isDark ? NuraColors.cardDark.opacity(0.9) : .white.opacity(0.9))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(isDark ? 0.14 : 0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.08), radius: 10, x: 0, y: 5)
    }

    private func overlayRegions(for imageIndex: Int) -> [ConditionOverlayRegion] {
        guard !conditions.isEmpty else { return [] }
        let fallbackPose = pose(for: imageIndex)
        let layout = faceLayouts[imageIndex] ?? FaceOverlayLayout(
            faceRect: CGRect(x: 0.18, y: 0.16, width: 0.64, height: 0.72),
            pose: fallbackPose,
            browLineY: nil
        )

        var regions: [ConditionOverlayRegion] = []
        for (conditionIndex, condition) in conditions.enumerated() {
            let color = issueColors[conditionIndex % issueColors.count]
            let areas = sanitizedAffectedAreas(for: condition)
            let style = highlightStyle(for: condition.name)
            for area in areas {
                for rect in normalizedRects(for: area, layout: layout) {
                    regions.append(
                        ConditionOverlayRegion(
                            conditionName: condition.name,
                            areaName: area,
                            color: color,
                            normalizedRect: rect,
                            style: style
                        )
                    )
                }
            }
        }
        return regions
    }

    private func sanitizedAffectedAreas(for condition: SkinCondition) -> [String] {
        let conditionName = condition.name.lowercased()
        let isOily = conditionName.contains("oily") || conditionName.contains("oil") || conditionName.contains("sebum")
        let isScar = conditionName.contains("scar")
        let isAcneLike = conditionName.contains("acne") || conditionName.contains("blemish") || conditionName.contains("breakout")

        var sourceAreas = condition.affectedAreas
        if sourceAreas.isEmpty {
            sourceAreas = ["face"]
        }

        var cleaned: [String] = []
        for raw in sourceAreas {
            let area = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

            // Never draw overlays on eyebrow/eyelid labels.
            if area.contains("brow") || area.contains("eyebrow") || area.contains("eyelid") {
                continue
            }

            if area == "face" {
                if isOily {
                    cleaned.append(contentsOf: ["nose", "left cheek", "right cheek"])
                } else if isScar || isAcneLike {
                    cleaned.append(contentsOf: ["left cheek", "right cheek", "chin"])
                } else {
                    cleaned.append("face")
                }
                continue
            }

            // Oily/Scar overlays on forehead tend to look like eyebrow highlights.
            if (isOily || isScar) && (area.contains("forehead") || area.contains("t-zone")) {
                continue
            }

            cleaned.append(area)
        }

        let deduped = Array(Set(cleaned))
        if !deduped.isEmpty {
            return deduped
        }

        if isOily {
            return ["nose", "left cheek", "right cheek"]
        }
        if isScar || isAcneLike {
            return ["left cheek", "right cheek", "chin"]
        }
        return ["face"]
    }

    private func pose(for index: Int) -> PhotoPose {
        switch index {
        case 0: return .front
        case 1: return .sideLeft
        case 2: return .sideRight
        default: return .front
        }
    }

    private func highlightStyle(for conditionName: String) -> ConditionOverlayRegion.HighlightStyle {
        let value = conditionName.lowercased()
        if value.contains("acne") || value.contains("pimple") || value.contains("blemish") || value.contains("breakout") || value.contains("blackhead") || value.contains("whitehead") {
            return .acne
        }
        if value.contains("oily") || value.contains("oil") || value.contains("sebum") || value.contains("shine") {
            return .oily
        }
        return .contour
    }

    private func photoTitle(for index: Int) -> String {
        switch index {
        case 0: return "Photo 1 (Front)"
        case 1: return "Photo 2 (Side)"
        case 2: return "Photo 3 (Side)"
        default: return "Photo \(index + 1)"
        }
    }

    private func normalizedRects(for area: String, layout: FaceOverlayLayout) -> [CGRect] {
        let value = area.lowercased()
        let isLeftNamed = value.contains("left")
        let isRightNamed = value.contains("right")
        let isGenericCheek = value.contains("cheek") && !isLeftNamed && !isRightNamed
        let isGenericEye = value.contains("eye") && !isLeftNamed && !isRightNamed
        let isGenericTemple = value.contains("temple") && !isLeftNamed && !isRightNamed

        if layout.pose == .sideLeft && isRightNamed { return [] }
        if layout.pose == .sideRight && isLeftNamed { return [] }

        if value.contains("forehead") || value.contains("t-zone") {
            // Forehead band: upper-mid forehead only (avoid eyebrows).
            let base = faceRelativeRect(0.26, 0.10, 0.48, 0.12, layout: layout)
            if let browY = layout.browLineY {
                var adjusted = base
                let maxAllowedY = browY - 0.032
                if adjusted.maxY > maxAllowedY {
                    adjusted.size.height = max(0.04, maxAllowedY - adjusted.minY)
                }
                return [adjusted]
            }
            return [base]
        }
        if value.contains("left cheek") {
            return [faceRelativeRect(0.12, 0.40, 0.24, 0.21, layout: layout)]
        }
        if value.contains("right cheek") {
            return [faceRelativeRect(0.64, 0.40, 0.24, 0.21, layout: layout)]
        }
        if isGenericCheek {
            if layout.pose == .sideLeft {
                return [faceRelativeRect(0.14, 0.40, 0.30, 0.22, layout: layout)]
            }
            if layout.pose == .sideRight {
                return [faceRelativeRect(0.56, 0.40, 0.30, 0.22, layout: layout)]
            }
            return [
                faceRelativeRect(0.12, 0.40, 0.24, 0.21, layout: layout),
                faceRelativeRect(0.64, 0.40, 0.24, 0.21, layout: layout)
            ]
        }
        if value.contains("nose") {
            return [faceRelativeRect(0.43, 0.35, 0.14, 0.24, layout: layout)]
        }
        if value.contains("chin") {
            return [faceRelativeRect(0.34, 0.73, 0.32, 0.16, layout: layout)]
        }
        if value.contains("jaw") {
            return [faceRelativeRect(0.22, 0.69, 0.56, 0.20, layout: layout)]
        }
        if value.contains("under eye") || value.contains("under-eye") {
            if layout.pose == .sideLeft {
                return [faceRelativeRect(0.24, 0.31, 0.20, 0.10, layout: layout)]
            }
            if layout.pose == .sideRight {
                return [faceRelativeRect(0.56, 0.31, 0.20, 0.10, layout: layout)]
            }
            return [
                faceRelativeRect(0.25, 0.31, 0.19, 0.10, layout: layout),
                faceRelativeRect(0.56, 0.31, 0.19, 0.10, layout: layout)
            ]
        }
        if isGenericEye || value.contains("eye") {
            if layout.pose == .sideLeft {
                return [faceRelativeRect(0.24, 0.28, 0.22, 0.12, layout: layout)]
            }
            if layout.pose == .sideRight {
                return [faceRelativeRect(0.54, 0.28, 0.22, 0.12, layout: layout)]
            }
            return [
                faceRelativeRect(0.24, 0.28, 0.20, 0.12, layout: layout),
                faceRelativeRect(0.56, 0.28, 0.20, 0.12, layout: layout)
            ]
        }
        if isGenericTemple || value.contains("temple") {
            if layout.pose == .sideLeft {
                return [faceRelativeRect(0.10, 0.24, 0.18, 0.16, layout: layout)]
            }
            if layout.pose == .sideRight {
                return [faceRelativeRect(0.72, 0.24, 0.18, 0.16, layout: layout)]
            }
            return [
                faceRelativeRect(0.10, 0.24, 0.16, 0.16, layout: layout),
                faceRelativeRect(0.74, 0.24, 0.16, 0.16, layout: layout)
            ]
        }
        if value.contains("mouth") || value.contains("lip") {
            return [faceRelativeRect(0.36, 0.59, 0.28, 0.11, layout: layout)]
        }
        if value.contains("face") {
            if layout.pose == .sideLeft {
                return [faceRelativeRect(0.05, 0.08, 0.65, 0.84, layout: layout)]
            }
            if layout.pose == .sideRight {
                return [faceRelativeRect(0.30, 0.08, 0.65, 0.84, layout: layout)]
            }
            return [faceRelativeRect(0.10, 0.08, 0.80, 0.84, layout: layout)]
        }

        return [faceRelativeRect(0.10, 0.10, 0.80, 0.82, layout: layout)]
    }

    private func faceRelativeRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, layout: FaceOverlayLayout) -> CGRect {
        let r = layout.faceRect
        let rect = CGRect(
            x: r.minX + (x * r.width),
            y: r.minY + (y * r.height),
            width: w * r.width,
            height: h * r.height
        )
        return clamp(rect)
    }

    private func clamp(_ rect: CGRect) -> CGRect {
        let minX = max(0.0, min(1.0, rect.minX))
        let minY = max(0.0, min(1.0, rect.minY))
        let maxX = max(minX, min(1.0, rect.maxX))
        let maxY = max(minY, min(1.0, rect.maxY))
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    private func computeFaceLayouts() async {
        var updated: [Int: FaceOverlayLayout] = [:]
        for (index, image) in Array(images.prefix(3).enumerated()) {
            if let layout = await detectFaceLayout(in: image, fallbackPose: pose(for: index)) {
                updated[index] = layout
            }
        }
        await MainActor.run {
            faceLayouts = updated
        }
    }

    private func detectFaceLayout(in image: UIImage, fallbackPose: PhotoPose) async -> FaceOverlayLayout? {
        guard let cgImage = image.cgImage else { return nil }
        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { req, _ in
                let observations = (req.results as? [VNFaceObservation]) ?? []
                guard let face = observations.max(by: {
                    $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height
                }) else {
                    continuation.resume(returning: nil)
                    return
                }

                let pose: PhotoPose
                if let yaw = face.yaw?.doubleValue {
                    if yaw > 0.20 {
                        pose = .sideLeft
                    } else if yaw < -0.20 {
                        pose = .sideRight
                    } else {
                        pose = .front
                    }
                } else {
                    pose = fallbackPose
                }

                let faceTopLeftRect = CGRect(
                    x: face.boundingBox.minX,
                    y: 1.0 - face.boundingBox.maxY,
                    width: face.boundingBox.width,
                    height: face.boundingBox.height
                )
                var padded = faceTopLeftRect.insetBy(dx: -0.015, dy: -0.012)
                padded = clamp(padded)

                let browY = eyebrowLineTopLeftY(face: face)
                continuation.resume(returning: FaceOverlayLayout(faceRect: padded, pose: pose, browLineY: browY))
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    private func eyebrowLineTopLeftY(face: VNFaceObservation) -> CGFloat? {
        guard let landmarks = face.landmarks else { return nil }
        let points = (landmarks.leftEyebrow?.normalizedPoints ?? []) + (landmarks.rightEyebrow?.normalizedPoints ?? [])
        guard !points.isEmpty else { return nil }

        let ysTopLeft = points.map { point -> CGFloat in
            let globalBottomY = face.boundingBox.minY + (CGFloat(point.y) * face.boundingBox.height)
            return 1.0 - globalBottomY
        }
        return ysTopLeft.reduce(0, +) / CGFloat(ysTopLeft.count)
    }

    private var isDark: Bool {
        appearanceManager.colorSchemePreference == "dark" ||
        (appearanceManager.colorSchemePreference == "system" && UITraitCollection.current.userInterfaceStyle == .dark)
    }
}

private struct FaceOverlayLayout {
    let faceRect: CGRect
    let pose: SkinIssueHighlightsView.PhotoPose
    let browLineY: CGFloat?
}

private struct LuxeHighlightedImageSlide: View {
    let image: UIImage
    let title: String
    let index: Int
    let total: Int
    let regions: [ConditionOverlayRegion]

    var body: some View {
        GeometryReader { outer in
            let cardSize = CGSize(width: max(120, outer.size.width - 12), height: outer.size.height)

            VStack(spacing: 10) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(index + 1)/\(total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                DetailedHighlightedImageCard(
                    image: image,
                    regions: regions
                )
                .frame(width: cardSize.width, height: max(260, outer.size.height - 44))
            }
            .padding(.horizontal, 6)
        }
    }
}

private struct DetailedHighlightedImageCard: View {
    let image: UIImage
    let regions: [ConditionOverlayRegion]

    var body: some View {
        GeometryReader { geometry in
            let imageRect = fittedImageRect(containerSize: geometry.size, imageSize: image.size)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.06), Color.black.opacity(0.12)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                ForEach(regions) { region in
                    let mapped = CGRect(
                        x: imageRect.origin.x + (region.normalizedRect.origin.x * imageRect.size.width),
                        y: imageRect.origin.y + (region.normalizedRect.origin.y * imageRect.size.height),
                        width: region.normalizedRect.size.width * imageRect.size.width,
                        height: region.normalizedRect.size.height * imageRect.size.height
                    )
                    IssueRegionOverlay(region: region, rect: mapped)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 8)
        }
    }

    private func fittedImageRect(containerSize: CGSize, imageSize: CGSize) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0, containerSize.width > 0, containerSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }

        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        if imageAspect > containerAspect {
            let width = containerSize.width
            let height = width / imageAspect
            return CGRect(x: 0, y: (containerSize.height - height) / 2, width: width, height: height)
        } else {
            let height = containerSize.height
            let width = height * imageAspect
            return CGRect(x: (containerSize.width - width) / 2, y: 0, width: width, height: height)
        }
    }
}

private struct IssueRegionOverlay: View {
    let region: ConditionOverlayRegion
    let rect: CGRect

    var body: some View {
        ZStack {
            switch region.style {
            case .acne:
                ForEach(0..<9, id: \.self) { idx in
                    let point = seededPoint(index: idx)
                    let dotSize = 3.0 + CGFloat((idx % 3))
                    Circle()
                        .fill(region.color.opacity(0.20))
                        .overlay(Circle().stroke(region.color.opacity(0.82), lineWidth: 0.8))
                        .frame(width: dotSize, height: dotSize)
                        .position(
                            x: rect.minX + point.x * rect.width,
                            y: rect.minY + point.y * rect.height
                        )
                }
                organicStroke(width: 1.6, opacity: 0.70)

            case .oily:
                ForEach(0..<11, id: \.self) { idx in
                    let x = rect.minX + (CGFloat(idx) / 10.0) * rect.width
                    let y = rect.minY + (0.25 + 0.5 * abs(sin(CGFloat(idx) * 0.7))) * rect.height
                    Path { path in
                        path.move(to: CGPoint(x: x - 7, y: y - 5))
                        path.addQuadCurve(
                            to: CGPoint(x: x + 7, y: y + 5),
                            control: CGPoint(x: x, y: y + 11)
                        )
                    }
                    .stroke(region.color.opacity(0.65), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
                }
                organicStroke(width: 2.0, opacity: 0.8)

            case .contour:
                organicStroke(width: 2.2, opacity: 0.92)
                organicStroke(scale: 0.9, width: 1.0, opacity: 0.42)
            }
        }
    }

    private func organicStroke(scale: CGFloat = 1.0, width: CGFloat, opacity: CGFloat) -> some View {
        Path { path in
            let insetX = rect.width * (1 - scale) / 2
            let insetY = rect.height * (1 - scale) / 2
            let w = rect.width * scale
            let h = rect.height * scale
            let origin = CGPoint(x: rect.minX + insetX, y: rect.minY + insetY)

            let p1 = CGPoint(x: origin.x + 0.06 * w, y: origin.y + 0.30 * h)
            let p2 = CGPoint(x: origin.x + 0.18 * w, y: origin.y + 0.08 * h)
            let p3 = CGPoint(x: origin.x + 0.50 * w, y: origin.y + 0.05 * h)
            let p4 = CGPoint(x: origin.x + 0.83 * w, y: origin.y + 0.10 * h)
            let p5 = CGPoint(x: origin.x + 0.94 * w, y: origin.y + 0.36 * h)
            let p6 = CGPoint(x: origin.x + 0.90 * w, y: origin.y + 0.68 * h)
            let p7 = CGPoint(x: origin.x + 0.72 * w, y: origin.y + 0.90 * h)
            let p8 = CGPoint(x: origin.x + 0.42 * w, y: origin.y + 0.94 * h)
            let p9 = CGPoint(x: origin.x + 0.14 * w, y: origin.y + 0.81 * h)

            path.move(to: p1)
            path.addQuadCurve(to: p3, control: p2)
            path.addQuadCurve(to: p5, control: p4)
            path.addQuadCurve(to: p7, control: p6)
            path.addQuadCurve(to: p9, control: p8)
            path.addQuadCurve(to: p1, control: CGPoint(x: origin.x - 0.02 * w, y: origin.y + 0.52 * h))
        }
        .stroke(region.color.opacity(opacity), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func seededPoint(index: Int) -> CGPoint {
        let seedText = "\(region.conditionName)-\(region.areaName)-\(index)"
        let hash = abs(seedText.hashValue)
        let x = CGFloat((hash % 1000)) / 1000.0
        let y = CGFloat((hash / 1000 % 1000)) / 1000.0
        return CGPoint(x: 0.08 + x * 0.84, y: 0.08 + y * 0.84)
    }
}

#Preview {
    SkinAnalysisView()
} 