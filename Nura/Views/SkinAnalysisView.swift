import SwiftUI
import PhotosUI
import Vision

struct SkinAnalysisView: View {
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var showingImagePicker = false
    @State private var showingResults = false
    @State private var showPremiumBanner = false
    @State private var showLimitReachedBanner = false
    // Progress is now driven by SkinAnalysisManager.analysisProgress
    @State private var photoStates: [UUID: Bool] = [:] // Track individual photo states
    @State private var photoValidationResults: [Int: PhotoValidationResult] = [:] // Cache validation results
    @State private var imageToPhotosPickerMapping: [Int: PhotosPickerItem] = [:] // Map uploaded image index to PhotosPicker item
    @State private var showAnalyzeSuccess: Bool = false
    
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
                        
                        // Upload button
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
                            Task {
                                await loadImages(from: newValue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Analysis button with progress bar
                    if !skinAnalysisManager.uploadedImages.isEmpty {
                        VStack(spacing: 4) { // Reduced spacing from 8 to 4
                            let canAnalyzeNow: Bool = userTierManager.canPerformAnalysis() && skinAnalysisManager.uploadedImages.count >= 3
                            Button(action: {
                                if canAnalyzeNow {
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
                                VStack(spacing: 4) {
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
        }
    }
    
    private func removePhoto(at index: Int) {
        // Validate index bounds
        guard index >= 0 && index < skinAnalysisManager.uploadedImages.count else {
            print("⚠️ Invalid photo index: \(index), total photos: \(skinAnalysisManager.uploadedImages.count)")
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
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
                    print("⚠️ Vision framework error: \(error)")
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
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                print("🔍 Starting Vision framework face detection...")
                try handler.perform([request])
            } catch {
                print("⚠️ Vision framework error during perform: \(error)")
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

#Preview {
    SkinAnalysisView()
} 