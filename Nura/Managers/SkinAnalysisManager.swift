import Foundation
import UIKit
import Supabase
import Vision
import CoreML

struct LocalUserProfile: Codable {
    let age: Int
    let gender: String
    let skinType: String
    let race: String
    let location: String
    let concerns: [String]
    let allergies: [String]
    let currentProducts: [String]
}

struct LocalSkinAnalysisDecision {
    let result: SkinAnalysisResult
    let confidence: Double
    let shouldCallCloud: Bool
    let usedCoreML: Bool
}

final class LocalSkinAnalysisService {
    private let cloudEscalationThreshold: Double = 0.80
    private let optionalCoreMLModelNames: [String] = ["AcneDetection", "SkinConditionSegmentation", "SkinIssueSegmentation"]

    func analyze(images: [UIImage]) async -> LocalSkinAnalysisDecision? {
        guard !images.isEmpty else { return nil }

        var imageInsights: [LocalImageInsight] = []
        for image in images.prefix(3) {
            guard let insight = await inspectImage(image) else { continue }
            imageInsights.append(insight)
        }
        guard !imageInsights.isEmpty else { return nil }

        let faceCoverage = Double(imageInsights.count) / Double(min(images.count, 3))
        let avgAcne = imageInsights.map(\.acneScore).average
        let avgOil = imageInsights.map(\.oilScore).average
        let avgDryness = imageInsights.map(\.drynessScore).average
        let avgBrightness = imageInsights.map(\.brightness).average

        var conditions: [SkinCondition] = []
        if avgAcne >= 0.16 {
            conditions.append(
                SkinCondition(
                    name: "Acne",
                    severity: severity(for: avgAcne),
                    confidence: min(0.92, 0.50 + avgAcne * 1.8),
                    description: "Visible blemish clustering",
                    affectedAreas: dominantAreas(from: imageInsights, metric: { $0.acneByArea })
                )
            )
        }
        if avgOil >= 0.14 {
            conditions.append(
                SkinCondition(
                    name: "Oily Skin",
                    severity: severity(for: avgOil),
                    confidence: min(0.90, 0.48 + avgOil * 1.7),
                    description: "Excess shine in T-zone",
                    affectedAreas: dominantAreas(from: imageInsights, metric: { $0.oilByArea })
                )
            )
        }
        if avgDryness >= 0.22 {
            conditions.append(
                SkinCondition(
                    name: "Dryness",
                    severity: severity(for: avgDryness * 0.8),
                    confidence: min(0.84, 0.45 + avgDryness * 1.1),
                    description: "Low hydration texture signs",
                    affectedAreas: dominantAreas(from: imageInsights, metric: { $0.drynessByArea })
                )
            )
        }

        let coreML = await runOptionalCoreMLAcnePass(images: Array(images.prefix(3)))
        if coreML.used, coreML.acneProbability > 0.60 {
            if let acneIndex = conditions.firstIndex(where: { $0.name.lowercased().contains("acne") }) {
                let existing = conditions[acneIndex]
                let boostedConfidence = min(0.96, max(existing.confidence, coreML.acneProbability))
                let boostedSeverity: SkinCondition.Severity = coreML.acneProbability > 0.8 ? .moderate : existing.severity
                conditions[acneIndex] = SkinCondition(
                    id: existing.id,
                    name: existing.name,
                    severity: boostedSeverity,
                    confidence: boostedConfidence,
                    description: existing.description,
                    affectedAreas: existing.affectedAreas
                )
            } else {
                conditions.append(
                    SkinCondition(
                        name: "Acne",
                        severity: coreML.acneProbability > 0.8 ? .moderate : .mild,
                        confidence: coreML.acneProbability,
                        description: "Model-detected breakout pattern",
                        affectedAreas: ["cheek", "forehead"]
                    )
                )
            }
        }

        if conditions.isEmpty {
            conditions.append(
                SkinCondition(
                    name: "Healthy Skin Pattern",
                    severity: .mild,
                    confidence: max(0.55, faceCoverage * 0.8),
                    description: "No strong local concerns",
                    affectedAreas: ["face"]
                )
            )
        }

        let baseConfidence = min(
            0.95,
            (faceCoverage * 0.55) +
            (poseSpreadConfidence(from: imageInsights) * 0.20) +
            ((1.0 - abs(avgBrightness - 0.58)) * 0.20) +
            (coreML.used ? 0.08 : 0.0)
        )

        let skinHealthScore = max(35, min(96, Int(round(88 - (avgAcne * 38) - (avgOil * 24) - (avgDryness * 20)))))
        let provider: SkinAnalysisResult.AnalysisProvider = coreML.used ? .coreMLLocal : .visionLocal
        let result = SkinAnalysisResult(
            conditions: conditions,
            confidence: baseConfidence,
            analysisDate: Date(),
            recommendations: localRecommendations(for: conditions),
            skinHealthScore: skinHealthScore,
            analysisVersion: "2.0-local",
            routineGenerationTimestamp: nil,
            analysisProvider: provider,
            imageCount: min(images.count, 3),
            skinAgeYears: nil
        )

        let shouldEscalateToCloud = (!coreML.used) || (baseConfidence < cloudEscalationThreshold)

        return LocalSkinAnalysisDecision(
            result: result,
            confidence: baseConfidence,
            shouldCallCloud: shouldEscalateToCloud,
            usedCoreML: coreML.used
        )
    }

    private func inspectImage(_ image: UIImage) async -> LocalImageInsight? {
        guard let cgImage = image.cgImage else { return nil }
        guard let face = await detectPrimaryFace(in: cgImage) else { return nil }
        guard let rgba = makeRGBAContext(from: cgImage) else { return nil }
        defer { free(rgba.data) }

        let pose = classifyPose(yaw: face.yaw?.doubleValue)
        let areaMap = areaRects(for: face.boundingBox, pose: pose)
        var acneByArea: [String: Double] = [:]
        var oilByArea: [String: Double] = [:]
        var dryByArea: [String: Double] = [:]
        var brightnessByArea: [Double] = []

        for (name, rect) in areaMap {
            let stats = regionStats(in: rect, rgba: rgba, width: cgImage.width, height: cgImage.height)
            acneByArea[name] = stats.redSpotRatio
            oilByArea[name] = stats.highlightRatio
            dryByArea[name] = stats.lowSaturationRatio
            brightnessByArea.append(stats.meanLuma)
        }

        return LocalImageInsight(
            pose: pose,
            acneScore: Array(acneByArea.values).average,
            oilScore: Array(oilByArea.values).average,
            drynessScore: Array(dryByArea.values).average,
            brightness: brightnessByArea.average,
            acneByArea: acneByArea,
            oilByArea: oilByArea,
            drynessByArea: dryByArea
        )
    }

    private func detectPrimaryFace(in cgImage: CGImage) async -> VNFaceObservation? {
        await withCheckedContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { req, _ in
                let faces = (req.results as? [VNFaceObservation]) ?? []
                let primary = faces.sorted { $0.boundingBox.width * $0.boundingBox.height > $1.boundingBox.width * $1.boundingBox.height }.first
                continuation.resume(returning: primary)
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }

    private func classifyPose(yaw: Double?) -> LocalPose {
        let y = yaw ?? 0
        if y > 0.20 { return .left }
        if y < -0.20 { return .right }
        return .front
    }

    private func areaRects(for face: CGRect, pose: LocalPose) -> [String: CGRect] {
        func region(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
            CGRect(x: face.minX + face.width * x, y: face.minY + face.height * y, width: face.width * w, height: face.height * h)
        }
        switch pose {
        case .front:
            return [
                "forehead": region(0.22, 0.68, 0.56, 0.18),
                "left cheek": region(0.08, 0.34, 0.25, 0.24),
                "right cheek": region(0.67, 0.34, 0.25, 0.24),
                "nose": region(0.43, 0.33, 0.14, 0.25),
                "chin": region(0.34, 0.12, 0.32, 0.16)
            ]
        case .left:
            return [
                "forehead": region(0.15, 0.68, 0.50, 0.18),
                "left cheek": region(0.08, 0.34, 0.30, 0.26),
                "nose": region(0.35, 0.34, 0.14, 0.23),
                "chin": region(0.28, 0.12, 0.32, 0.16)
            ]
        case .right:
            return [
                "forehead": region(0.35, 0.68, 0.50, 0.18),
                "right cheek": region(0.62, 0.34, 0.30, 0.26),
                "nose": region(0.51, 0.34, 0.14, 0.23),
                "chin": region(0.40, 0.12, 0.32, 0.16)
            ]
        }
    }

    private func severity(for score: Double) -> SkinCondition.Severity {
        if score >= 0.34 { return .severe }
        if score >= 0.20 { return .moderate }
        return .mild
    }

    private func dominantAreas(from insights: [LocalImageInsight], metric: (LocalImageInsight) -> [String: Double]) -> [String] {
        var merged: [String: Double] = [:]
        for insight in insights {
            for (area, value) in metric(insight) {
                merged[area, default: 0] += value
            }
        }
        return merged.sorted(by: { $0.value > $1.value }).prefix(2).map(\.key)
    }

    private func localRecommendations(for conditions: [SkinCondition]) -> [String] {
        var tips: [String] = []
        if conditions.contains(where: { $0.name.lowercased().contains("acne") }) { tips.append("Use non-comedogenic cleanser and spot treatment.") }
        if conditions.contains(where: { $0.name.lowercased().contains("oily") }) { tips.append("Use lightweight gel moisturizer and niacinamide.") }
        if conditions.contains(where: { $0.name.lowercased().contains("dry") }) { tips.append("Add ceramide moisturizer and reduce harsh exfoliation.") }
        if tips.isEmpty { tips.append("Maintain consistent cleanser, moisturizer, and SPF routine.") }
        return Array(tips.prefix(3))
    }

    private func poseSpreadConfidence(from insights: [LocalImageInsight]) -> Double {
        switch Set(insights.map(\.pose)).count {
        case 3: return 1.0
        case 2: return 0.75
        default: return 0.55
        }
    }

    private func runOptionalCoreMLAcnePass(images: [UIImage]) async -> (used: Bool, acneProbability: Double) {
        guard let model = loadOptionalCoreMLModel() else { return (false, 0.0) }
        var probs: [Double] = []
        for image in images {
            guard let cg = image.cgImage else { continue }
            let result = await withCheckedContinuation { continuation in
                let request = VNCoreMLRequest(model: model) { req, _ in
                    if let classification = (req.results as? [VNClassificationObservation])?.first {
                        let acneLike = classification.identifier.lowercased().contains("acne")
                        continuation.resume(returning: acneLike ? Double(classification.confidence) : 1.0 - Double(classification.confidence))
                    } else {
                        continuation.resume(returning: 0.0)
                    }
                }
                let handler = VNImageRequestHandler(cgImage: cg, options: [:])
                do { try handler.perform([request]) } catch { continuation.resume(returning: 0.0) }
            }
            probs.append(result)
        }
        return (true, probs.average)
    }

    private func loadOptionalCoreMLModel() -> VNCoreMLModel? {
        for name in optionalCoreMLModelNames {
            if let compiledURL = Bundle.main.url(forResource: name, withExtension: "mlmodelc"),
               let model = try? MLModel(contentsOf: compiledURL),
               let vn = try? VNCoreMLModel(for: model) { return vn }
        }
        return nil
    }

    private func makeRGBAContext(from cgImage: CGImage) -> (data: UnsafeMutableRawPointer, bytesPerRow: Int)? {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerRow = width * 4
        guard let data = malloc(height * bytesPerRow) else { return nil }
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            free(data)
            return nil
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return (data, bytesPerRow)
    }

    private func regionStats(in normalizedRect: CGRect, rgba: (data: UnsafeMutableRawPointer, bytesPerRow: Int), width: Int, height: Int) -> RegionStats {
        let xMin = max(0, min(width - 1, Int(normalizedRect.minX * CGFloat(width))))
        let xMax = max(0, min(width - 1, Int(normalizedRect.maxX * CGFloat(width))))
        let yMin = max(0, min(height - 1, Int((1.0 - normalizedRect.maxY) * CGFloat(height))))
        let yMax = max(0, min(height - 1, Int((1.0 - normalizedRect.minY) * CGFloat(height))))
        guard xMax > xMin, yMax > yMin else {
            return RegionStats(meanLuma: 0.5, highlightRatio: 0, redSpotRatio: 0, lowSaturationRatio: 0)
        }

        let ptr = rgba.data.bindMemory(to: UInt8.self, capacity: height * rgba.bytesPerRow)
        let stepX = max(1, (xMax - xMin) / 32)
        let stepY = max(1, (yMax - yMin) / 32)
        var lumaTotal: Double = 0
        var sampleCount: Double = 0
        var brightCount: Double = 0
        var redSpotCount: Double = 0
        var lowSatCount: Double = 0

        for y in stride(from: yMin, through: yMax, by: stepY) {
            let rowStart = y * rgba.bytesPerRow
            for x in stride(from: xMin, through: xMax, by: stepX) {
                let i = rowStart + x * 4
                let r = Double(ptr[i])
                let g = Double(ptr[i + 1])
                let b = Double(ptr[i + 2])
                let maxC = max(r, max(g, b))
                let minC = min(r, min(g, b))
                let sat = maxC == 0 ? 0 : (maxC - minC) / maxC
                let luma = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
                sampleCount += 1
                lumaTotal += luma
                if luma > 0.90 { brightCount += 1 }
                if r > (g * 1.14), r > (b * 1.14), luma > 0.22, luma < 0.88 { redSpotCount += 1 }
                if sat < 0.17 && luma > 0.30 && luma < 0.75 { lowSatCount += 1 }
            }
        }

        let denom = max(1, sampleCount)
        return RegionStats(
            meanLuma: lumaTotal / denom,
            highlightRatio: brightCount / denom,
            redSpotRatio: redSpotCount / denom,
            lowSaturationRatio: lowSatCount / denom
        )
    }
}

private struct LocalImageInsight {
    let pose: LocalPose
    let acneScore: Double
    let oilScore: Double
    let drynessScore: Double
    let brightness: Double
    let acneByArea: [String: Double]
    let oilByArea: [String: Double]
    let drynessByArea: [String: Double]
}

private enum LocalPose: Hashable {
    case front
    case left
    case right
}

private struct RegionStats {
    let meanLuma: Double
    let highlightRatio: Double
    let redSpotRatio: Double
    let lowSaturationRatio: Double
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0.0 }
        return reduce(0, +) / Double(count)
    }
}

@MainActor
class SkinAnalysisManager: ObservableObject {
    @Published var isAnalyzing = false
    @Published var analysisResults: SkinAnalysisResult?
    @Published var uploadedImages: [UIImage] = []
    @Published var recommendations: SkincareRecommendations?
    @Published var isReloading: Bool = false
    @Published var reloadStartTime: Date? // Track when regeneration starts
    @Published var recommendationsUpdatedAt: Date?
    @Published var recommendationsChangeLog: [String] = []
    @Published var errorMessage: String?
    @Published var analysisProgress: Double = 0.0
    @Published var lastRecommendationsResponse: String? // raw content from model (for spike/debug)
    @Published var isExplicitRefresh: Bool = false // Track if this is an explicit refresh vs cache load
    
    private let chatGPTService = ChatGPTServiceManager()
    private let localSkinAnalysisService = LocalSkinAnalysisService()
    private let userTierManager: UserTierManager
    private var analysisTimer: Timer?
    
    // MARK: - Timer Computed Properties
    
    /// Calculate elapsed time since regeneration started
    var reloadElapsedTime: TimeInterval {
        guard let startTime = reloadStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    /// Calculate countdown time (starts from 15 seconds)
    var reloadCountdownTime: TimeInterval {
        let elapsed = reloadElapsedTime
        let countdown = 15.0 - elapsed
        return max(0, countdown)
    }
    
    init(userTierManager: UserTierManager) {
        self.userTierManager = userTierManager
        print("🔍 SkinAnalysisManager: Initialized")
        APIConfig.logConfiguration()
    }
    
    func uploadImages(_ images: [UIImage]) {
        print("🔍 SkinAnalysisManager: Starting image upload process")
        print("🔍 SkinAnalysisManager: Images count: \(images.count)")
        print("🔍 SkinAnalysisManager: ⚠️ IMPORTANT: This method should ONLY be called when user presses the 'Analyze' button")
        
        guard !images.isEmpty else {
            print("❌ SkinAnalysisManager: No images provided")
            errorMessage = "Please select at least one image for analysis"
            return
        }
        
        guard images.count <= 3 else {
            print("❌ SkinAnalysisManager: Too many images (\(images.count))")
            errorMessage = "Maximum 3 images allowed for analysis"
            return
        }
        
        // Check if user can perform analysis based on tier
        guard userTierManager.canPerformAnalysis() else {
            let limit = userTierManager.getDailyAnalysisLimit()
            let nextTime = userTierManager.getNextAnalysisTime()
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .short
            errorMessage = "Daily analysis limit reached (\(limit)/day). Next available: \(formatter.string(from: nextTime))"
            print("❌ SkinAnalysisManager: Daily analysis limit reached")
            return
        }
        
        print("🔍 SkinAnalysisManager: User can perform analysis, proceeding...")
        print("🔍 SkinAnalysisManager: ✅ Analysis triggered by user action (Analyze button pressed)")
        isAnalyzing = true
        errorMessage = nil
        uploadedImages = images
        startAnalysisProgress()
        
        Task<Void, Never> {
            var localDecisionForFallback: LocalSkinAnalysisDecision?
            do {
                print("🔍 SkinAnalysisManager: Running local Vision/CoreML analysis first...")
                let localDecision = await localSkinAnalysisService.analyze(images: images)
                localDecisionForFallback = localDecision
                if let localDecision = localDecision {
                    print("🔍 SkinAnalysisManager: Local confidence=\(String(format: "%.2f", localDecision.confidence)) usedCoreML=\(localDecision.usedCoreML)")
                    if !localDecision.usedCoreML {
                        print("🔍 SkinAnalysisManager: No bundled CoreML segmentation model found; using cloud for final analysis quality")
                    }
                } else {
                    print("⚠️ SkinAnalysisManager: Local analysis unavailable, escalating to cloud")
                }

                if let localDecision = localDecision, !localDecision.shouldCallCloud {
                    print("✅ SkinAnalysisManager: Local confidence high, skipping cloud AI")
                    await MainActor.run {
                        self.completeAnalysis(with: localDecision.result)
                    }
                    return
                }

                print("🔍 SkinAnalysisManager: Local confidence low, escalating to ChatGPT Vision API...")
                let cloudResult = try await chatGPTService.analyzeSkinImages(images, userTier: userTierManager.tier)
                let finalResult: SkinAnalysisResult
                if localDecision != nil {
                    // Preserve provider trace for analytics.
                    finalResult = SkinAnalysisResult(
                        conditions: cloudResult.conditions,
                        confidence: cloudResult.confidence,
                        analysisDate: cloudResult.analysisDate,
                        recommendations: cloudResult.recommendations,
                        skinHealthScore: cloudResult.skinHealthScore,
                        analysisVersion: cloudResult.analysisVersion,
                        routineGenerationTimestamp: cloudResult.routineGenerationTimestamp,
                        analysisProvider: .hybridLocalCloud,
                        imageCount: cloudResult.imageCount,
                        skinAgeYears: cloudResult.skinAgeYears
                    )
                } else {
                    finalResult = cloudResult
                }

                print("🔍 SkinAnalysisManager: Analysis completed successfully")
                await MainActor.run {
                    self.completeAnalysis(with: finalResult)
                }
                
            } catch {
                print("❌ SkinAnalysisManager: Analysis failed with error: \(error)")
                print("❌ SkinAnalysisManager: Error details: \(error.localizedDescription)")
                await MainActor.run {
                    if let localFallback = localDecisionForFallback {
                        print("⚠️ SkinAnalysisManager: Falling back to local analysis due to cloud failure")
                        self.completeAnalysis(with: localFallback.result)
                    } else {
                        self.errorMessage = error.localizedDescription
                        self.stopAnalysisProgress()
                        self.analysisProgress = 0.0
                        self.isAnalyzing = false
                    }
                }
            }
        }
    }
    
    // private func uploadImagesToStorage(_ images: [UIImage], completion: @escaping ([String]) -> Void) {
    //     let group = DispatchGroup()
    //     var imageURLs: [String] = []
    //     
    //     for (_, image) in images.enumerated() {
    //         group.enter()
    //             
    //         guard let imageData = image.jpegData(compressionQuality: 0.8) else {
    //             group.leave()
    //             continue
    //         }
    //             
    //         let imageName = "skin_analysis_\(Date().timeIntervalSince1970)_\(UUID().uuidString).jpg"
    //         let storageRef = storage.reference().child("skin_analysis/\(imageName)")
    //             
    //         storageRef.putData(imageData, metadata: nil) { _, error in
    //             if let error = error {
    //                 DispatchQueue.main.async {
    //                     self.errorMessage = "Failed to upload image: \(error.localizedDescription)"
    //                 }
    //                 group.leave()
    //                 return
    //             }
    //                 
    //             storageRef.downloadURL { url, error in
    //                 if let url = url {
    //                         imageURLs.append(url.absoluteString)
    //                 }
    //                 group.leave()
    //             }
    //         }
    //     }
    //         
    //     group.notify(queue: .main) {
    //         completion(imageURLs)
    //     }
        // }
    
    // MARK: - Helper Methods
    
    private func getUserProfile() -> LocalUserProfile {
        return LocalUserProfile(
            age: 25,
            gender: "female",
            skinType: "combination",
            race: "asian",
            location: "San Francisco, CA",
            concerns: ["acne", "dark spots"],
            allergies: ["fragrance"],
            currentProducts: ["cleanser", "moisturizer"]
        )
    }
    
    private func getWeatherData() -> WeatherData? {
        return WeatherData(
            temperature: 22.0,
            humidity: 65.0,
            uvIndex: 5.0,
            condition: "sunny"
        )
    }
    
    // MARK: - Caching and Retrieval
    
    /// Get cached analysis results if they're still valid (within 24 hours)
    func getCachedAnalysisResults() -> SkinAnalysisResult? {
        guard let results = analysisResults else { return nil }
        
        let cacheAge = Date().timeIntervalSince(results.analysisDate)
        let isCacheValid = cacheAge < APIConfig.analysisCacheDuration
        
        if !isCacheValid {
            // Clear expired cache
            analysisResults = nil
            return nil
        }
        
        return results
    }
    
    /// Clear cached analysis results
    func clearCachedResults() {
        analysisResults = nil
        errorMessage = nil
    }
    
    /// Check if user has recent analysis results
    func hasRecentAnalysis() -> Bool {
        return getCachedAnalysisResults() != nil
    }
    
    /// Get analysis status for display
    func getAnalysisStatus() -> AnalysisStatus {
        if isAnalyzing {
            return .analyzing
        } else if let results = getCachedAnalysisResults() {
            return .completed(results)
        } else if let error = errorMessage {
            return .error(error)
        } else {
            return .notStarted
        }
    }
    
    // MARK: - Analysis Status
    
    enum AnalysisStatus {
        case notStarted
        case analyzing
        case completed(SkinAnalysisResult)
        case error(String)
    }
    
    // MARK: - Recommendations Reload & Cache
    private let recommendationsCacheKey = "nura.recommendations.cache.v1" // legacy UserDefaults key
    private var recommendationsCacheURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Nura", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("recommendations.json")
    }
    private var recommendationsDebugURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Nura", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("recommendations_raw.txt")
    }
    
    private func saveRecommendationsToDisk(_ recs: SkincareRecommendations) {
        do {
            let data = try JSONEncoder().encode(recs)
            try data.write(to: recommendationsCacheURL, options: .atomic)
            print("✅ SkinAnalysisManager: Saved recommendations to disk at \(recommendationsCacheURL.path)")
        } catch {
            print("⚠️ SkinAnalysisManager: Failed saving recommendations to disk: \(error)")
        }
    }
    
    private func loadRecommendationsFromDisk() -> SkincareRecommendations? {
        do {
            let data = try Data(contentsOf: recommendationsCacheURL)
            return try JSONDecoder().decode(SkincareRecommendations.self, from: data)
        } catch {
            print("ℹ️ SkinAnalysisManager: No disk cache or failed to decode recommendations: \(error)")
            return nil
        }
    }
    
    func loadCachedRecommendations() {
        if let recs = loadRecommendationsFromDisk() {
            self.isExplicitRefresh = false // This is a cache load, not an explicit refresh
            self.recommendations = recs
            print("✅ SkinAnalysisManager: Loaded cached recommendations from disk")
            return
        }
        // Backward-compatibility: try legacy UserDefaults cache once
        if let data = UserDefaults.standard.data(forKey: recommendationsCacheKey),
           let recs = try? JSONDecoder().decode(SkincareRecommendations.self, from: data) {
            self.isExplicitRefresh = false // This is a cache load, not an explicit refresh
            self.recommendations = recs
            print("✅ SkinAnalysisManager: Loaded cached recommendations from UserDefaults (legacy)")
            // migrate to disk
            saveRecommendationsToDisk(recs)
            UserDefaults.standard.removeObject(forKey: recommendationsCacheKey)
        }
    }
    
    func regenerateRecommendations() async {
        print("🔄 SkinAnalysisManager: Regenerating recommendations via ChatGPT")
        // Use last analysis results to craft a prompt; if none, bail gracefully
        guard let results = self.analysisResults ?? self.getCachedAnalysisResults() else {
            print("⚠️ SkinAnalysisManager: No analysis results available to generate recommendations")
            return
        }
        
        do {
            isReloading = true
            isExplicitRefresh = true // This is an explicit refresh action
            reloadStartTime = Date() // Set start time for timer
            let oldRecs = self.recommendations
            let startTs = Date()
            // Build a lightweight pseudo-prompt by serializing current results
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let resultsData = try encoder.encode(results)
            let resultsJSON = String(data: resultsData, encoding: .utf8) ?? "{}"
            
            let prompt = """
            You are a board-certified dermatologist. Generate COMPLETE skincare routines. Return STRICT JSON only, no prose.
            
            CRITICAL: Keep responses under 4000 characters to avoid truncation.
            
            Schema:
            {
              "morningRoutine": [{
                "id":"step-1",
                "name":"Gentle Cleanser",
                "description":"Cleanse skin to remove impurities",
                "category":"cleanser",
                "duration":60,
                "frequency":"daily",
                "stepTime":"morning",
                "conflictsWith":[],
                "requiresSPF":false,
                "tips":["Use lukewarm water"]
              }, {
                "id":"step-2",
                "name":"Hydrating Serum",
                "description":"Apply serum for hydration",
                "category":"serum",
                "duration":30,
                "frequency":"daily",
                "stepTime":"morning",
                "conflictsWith":[],
                "requiresSPF":false,
                "tips":["Apply to damp skin"]
              }, {
                "id":"step-3",
                "name":"Moisturizer",
                "description":"Lock in hydration",
                "category":"moisturizer",
                "duration":45,
                "frequency":"daily",
                "stepTime":"morning",
                "conflictsWith":[],
                "requiresSPF":false,
                "tips":["Wait for serum to absorb"]
              }, {
                "id":"step-4",
                "name":"Sunscreen",
                "description":"Protect from UV damage",
                "category":"sunscreen",
                "duration":30,
                "frequency":"daily",
                "stepTime":"morning",
                "conflictsWith":[],
                "requiresSPF":true,
                "tips":["Apply generously"]
              }],
              "eveningRoutine": [<same structure with 3-4 steps>],
              "weeklyTreatments": [<same structure with 1-2 steps>],
              "lifestyleTips": ["Stay hydrated", "Get adequate sleep"],
              "productRecommendations": [{
                 "id":"prod-1",
                 "name":"CeraVe Cleanser",
                 "brand":"CeraVe",
                 "category":"cleanser",
                 "price":15,
                 "rating":4.5,
                 "description":"Gentle daily cleanser",
                 "ingredients":["ceramides"],
                 "benefits":["Hydrating"],
                 "imageURL":null,
                 "purchaseURL":null
              }],
              "progressTracking": {"skinHealthScore": 0.75, "improvementAreas": ["hydration"], "nextCheckIn": "2024-01-15", "goals": ["clear skin"]}
            }
            
            Rules:
            - Morning routine: 4 steps (cleanser, serum, moisturizer, sunscreen)
            - Evening routine: 3-4 steps (cleanser, treatment, moisturizer, optional mask)
            - Weekly treatments: 1-2 steps (exfoliant, mask, etc.)
            - Use detailed descriptions (5-8 words)
            - Include helpful tips for each step
            - Avoid sunscreen at night
            - Use simple string IDs like "step-1", "step-2" for steps and "prod-1", "prod-2" for products
            - Use only these frequency values: "daily", "twice_daily", "nightly", "weekly", "as_needed"
            - Use only these categories: "cleanser", "toner", "serum", "exfoliant", "bha", "aha", "treatment", "moisturizer", "sunscreen", "mask", "clay"
            - Use only these stepTimes: "morning", "evening", "anytime"
            
            Analysis JSON:
            \(resultsJSON)
            """
            
            chatGPTService.isProcessing = true
            defer { chatGPTService.isProcessing = false }
            
            // Use GPT model selection based on tier
            let model = APIConfig.fastTextModel
            print("📤 Sending text-only request to model=\(model). Prompt chars=\(prompt.count)")
            let raw = try await makeTextOnlyRequest(model: model, prompt: prompt)
            print("📝 Raw model response (first 500): \(raw.prefix(500))… totalChars=\(raw.count)")
            let jsonString = extractJSONFromResponse(raw)
            print("🧪 Extracted JSON-ish string (first 500): \(jsonString.prefix(500))… totalChars=\(jsonString.count)")
            self.lastRecommendationsResponse = raw
            do {
                if APIConfig.enableVerboseAIDebugLogging {
                    // Write artifacts in background to avoid UI blocking
                    let debugURL = self.recommendationsDebugURL
                    let jsonCopy = jsonString
                    let rawCopy = raw
                    Task.detached { @Sendable in
                        try? jsonCopy.data(using: .utf8)?.write(to: debugURL, options: .atomic)
                        let debugDir = debugURL.deletingLastPathComponent()
                        let rawURL = debugDir.appendingPathComponent("recommendations_response.txt")
                        try? rawCopy.data(using: .utf8)?.write(to: rawURL, options: .atomic)
                        print("🗂️ Wrote debug files to Application Support/Nura")
                    }
                }
            }
            
            // Preflight: if progressTracking.nextCheckIn is clearly a string, leave it — our tolerant decoder will handle it. Log the type for visibility.
            if let ptRange = jsonString.range(of: "\"progressTracking\"\\s*:\\s*\\{", options: .regularExpression) {
                let tail = jsonString[ptRange.upperBound...]
                if tail.range(of: "\"nextCheckIn\"\\s*:\\s*\"", options: .regularExpression) != nil {
                    print("🔎 Preflight: progressTracking.nextCheckIn appears to be a string; decoder will coerce ISO or seconds")
                }
            }
            
            // Preprocess JSON to convert string IDs to UUIDs before decoding
            let preprocessedJSON = preprocessJSONForUUIDConversion(jsonString)
            
            // Try decoding full SkincareRecommendations
            if let data = preprocessedJSON.data(using: .utf8) {
                print("📦 Attempting JSON decode: bytes=\(data.count)")
                print("🔍 Preprocessed JSON preview: \(String(preprocessedJSON.prefix(200)))...")
                do {
                    var recs = try JSONDecoder().decode(SkincareRecommendations.self, from: data)
                    print("✅ Decoded recs: morning=\(recs.morningRoutine.count), evening=\(recs.eveningRoutine.count), weekly=\(recs.weeklyTreatments.count)")
                    // Clamp routine lengths to reduce UI load
                    recs = SkincareRecommendations(
                        morningRoutine: Array(recs.morningRoutine.prefix(4)),
                        eveningRoutine: Array(recs.eveningRoutine.prefix(4)),
                        weeklyTreatments: Array(recs.weeklyTreatments.prefix(2)),
                        lifestyleTips: recs.lifestyleTips,
                        productRecommendations: recs.productRecommendations,
                        progressTracking: recs.progressTracking
                    )
                    recs = applyLocalRules(to: recs)
                    print("🧩 After rules: morning=\(recs.morningRoutine.count), evening=\(recs.eveningRoutine.count), weekly=\(recs.weeklyTreatments.count)")
                    await MainActor.run {
                        self.recommendations = recs
                        self.recommendationsUpdatedAt = Date()
                        self.recommendationsChangeLog = self.buildChangeLog(old: oldRecs, new: recs)
                        self.saveRecommendationsToDisk(recs)
                        print("✅ SkinAnalysisManager: Cached recommendations (disk)")
                        print("📋 Routines summary → morning: \(recs.morningRoutine.map{ $0.name }.joined(separator: ", ")), evening: \(recs.eveningRoutine.map{ $0.name }.joined(separator: ", ")), weekly: \(recs.weeklyTreatments.map{ $0.name }.joined(separator: ", ")) )")
                        self.isReloading = false
                        print("⏱️ Total regenerate latency: \(String(format: "%.2fs", Date().timeIntervalSince(startTs)))")
                        NotificationCenter.default.post(name: .nuraRecommendationsUpdated, object: recs)
                    }
                    return
                } catch {
                    print("ℹ️ JSON decode failed: \(error)")
                    print("🔍 Error details: \(error.localizedDescription)")
                    
                    // Enhanced truncation detection and recovery
                    if let truncatedData = detectAndRecoverTruncatedJSON(jsonString) {
                        print("🔧 Detected truncated JSON, attempting recovery...")
                        let preprocessedTruncated = preprocessJSONForUUIDConversion(truncatedData)
                        if let recoveredData = preprocessedTruncated.data(using: .utf8),
                           let recsTry = try? JSONDecoder().decode(SkincareRecommendations.self, from: recoveredData) {
                            print("✅ Recovered truncated JSON successfully")
                            var recs = recsTry
                            recs = SkincareRecommendations(
                                morningRoutine: Array(recs.morningRoutine.prefix(4)),
                                eveningRoutine: Array(recs.eveningRoutine.prefix(4)),
                                weeklyTreatments: Array(recs.weeklyTreatments.prefix(2)),
                                lifestyleTips: recs.lifestyleTips,
                                productRecommendations: recs.productRecommendations,
                                progressTracking: recs.progressTracking
                            )
                            recs = applyLocalRules(to: recs)
                            await MainActor.run {
                                self.recommendations = recs
                                self.recommendationsUpdatedAt = Date()
                                self.recommendationsChangeLog = self.buildChangeLog(old: oldRecs, new: recs)
                                self.saveRecommendationsToDisk(recs)
                                print("✅ SkinAnalysisManager: Cached recommendations (disk) [recovered]")
                                print("📋 Routines summary → morning: \(recs.morningRoutine.map{ $0.name }.joined(separator: ", ")), evening: \(recs.eveningRoutine.map{ $0.name }.joined(separator: ", ")), weekly: \(recs.weeklyTreatments.map{ $0.name }.joined(separator: ", ")) )")
                                self.isReloading = false
                                print("⏱️ Total regenerate latency: \(String(format: "%.2fs", Date().timeIntervalSince(startTs)))")
                                NotificationCenter.default.post(name: .nuraRecommendationsUpdated, object: recs)
                            }
                            return
                        }
                    }
                    
                    // Retry with sanitized JSON if truncated or unbalanced
                    let sanitized = sanitizePossiblyTruncatedJSON(jsonString)
                    if sanitized != jsonString {
                        let preprocessedSanitized = preprocessJSONForUUIDConversion(sanitized)
                        if let sData = preprocessedSanitized.data(using: .utf8), let recsTry = try? JSONDecoder().decode(SkincareRecommendations.self, from: sData) {
                            print("✅ Sanitized JSON decoded successfully (balanced braces)")
                            var recs = recsTry
                            recs = SkincareRecommendations(
                                morningRoutine: Array(recs.morningRoutine.prefix(4)),
                                eveningRoutine: Array(recs.eveningRoutine.prefix(4)),
                                weeklyTreatments: Array(recs.weeklyTreatments.prefix(2)),
                                lifestyleTips: recs.lifestyleTips,
                                productRecommendations: recs.productRecommendations,
                                progressTracking: recs.progressTracking
                            )
                            recs = applyLocalRules(to: recs)
                            await MainActor.run {
                                self.recommendations = recs
                                self.recommendationsUpdatedAt = Date()
                                self.recommendationsChangeLog = self.buildChangeLog(old: oldRecs, new: recs)
                                self.saveRecommendationsToDisk(recs)
                                print("✅ SkinAnalysisManager: Cached recommendations (disk) [sanitized]")
                                print("📋 Routines summary → morning: \(recs.morningRoutine.map{ $0.name }.joined(separator: ", ")), evening: \(recs.eveningRoutine.map{ $0.name }.joined(separator: ", ")), weekly: \(recs.weeklyTreatments.map{ $0.name }.joined(separator: ", ")) )")
                                self.isReloading = false
                                print("⏱️ Total regenerate latency: \(String(format: "%.2fs", Date().timeIntervalSince(startTs)))")
                                NotificationCenter.default.post(name: .nuraRecommendationsUpdated, object: recs)
                            }
                            return
                        }
                    }
                    // No retry needed - we've fixed the root cause with preprocessing
                    print("⚠️ All JSON processing attempts failed - this should be rare with the new preprocessing")
                    // Attempt to find first JSON object substring explicitly
                    if let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") {
                        let inner = String(raw[start...end])
                        print("🔍 Trying inner JSON slice (first 300): \(inner.prefix(300))…")
                        let preprocessedInner = preprocessJSONForUUIDConversion(inner)
                        if let innerData = preprocessedInner.data(using: .utf8) {
                            if var recs = try? JSONDecoder().decode(SkincareRecommendations.self, from: innerData) {
                                print("✅ Inner slice decoded: morning=\(recs.morningRoutine.count), evening=\(recs.eveningRoutine.count), weekly=\(recs.weeklyTreatments.count)")
                                recs = applyLocalRules(to: recs)
                                await MainActor.run {
                                    self.recommendations = recs
                                    self.recommendationsUpdatedAt = Date()
                                    self.recommendationsChangeLog = self.buildChangeLog(old: oldRecs, new: recs)
                                    self.saveRecommendationsToDisk(recs)
                                    print("✅ SkinAnalysisManager: Cached recommendations from inner JSON (disk)")
                                    print("📋 Routines summary → morning: \(recs.morningRoutine.map{ $0.name }.joined(separator: ", ")), evening: \(recs.eveningRoutine.map{ $0.name }.joined(separator: ", ")), weekly: \(recs.weeklyTreatments.map{ $0.name }.joined(separator: ", ")) )")
                                    self.isReloading = false
                                    print("⏱️ Total regenerate latency: \(String(format: "%.2fs", Date().timeIntervalSince(startTs)))")
                                    NotificationCenter.default.post(name: .nuraRecommendationsUpdated, object: recs)
                                }
                                return
                            } else {
                                print("❌ Inner JSON decode failed (bytes=\(innerData.count))")
                            }
                        } else {
                            print("❌ inner string could not convert to UTF-8 data")
                        }
                    } else {
                        print("ℹ️ No braces found to attempt inner JSON slice")
                    }
                }
            } else {
                print("ℹ️ Could not convert jsonString to UTF-8 data")
            }
            
            // Fallback: extract routine names from the actual JSON structure
            var simpleRecs: [String] = []
            if let data = jsonString.data(using: .utf8) {
                if let any = try? JSONSerialization.jsonObject(with: data, options: []),
                   let dict = any as? [String: Any] {
                    print("🔑 Top-level keys: \(Array(dict.keys))")
                    
                    // Try to extract routine names from the actual structure
                    if let morningRoutine = dict["morningRoutine"] as? [[String: Any]] {
                        let morningNames = morningRoutine.compactMap { $0["name"] as? String }
                        simpleRecs.append(contentsOf: morningNames)
                        print("🔎 Extracted morning routine names: \(morningNames)")
                    }
                    
                    if let eveningRoutine = dict["eveningRoutine"] as? [[String: Any]] {
                        let eveningNames = eveningRoutine.compactMap { $0["name"] as? String }
                        simpleRecs.append(contentsOf: eveningNames)
                        print("🔎 Extracted evening routine names: \(eveningNames)")
                    }
                    
                    if let weeklyTreatments = dict["weeklyTreatments"] as? [[String: Any]] {
                        let weeklyNames = weeklyTreatments.compactMap { $0["name"] as? String }
                        simpleRecs.append(contentsOf: weeklyNames)
                        print("🔎 Extracted weekly treatment names: \(weeklyNames)")
                    }
                    
                    // Legacy fallback for recommendations key
                    if simpleRecs.isEmpty, let rawArray = dict["recommendations"] as? [Any] {
                        simpleRecs = rawArray.compactMap { $0 as? String }.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        print("🔎 JSONSerialization path produced \(simpleRecs.count) items: \(simpleRecs.prefix(10))")
                    }
                } else {
                    print("ℹ️ JSONSerialization could not parse jsonString")
                }
            }
            if simpleRecs.isEmpty {
                print("ℹ️ No routine names could be extracted from the JSON structure")
            }
            if !simpleRecs.isEmpty {
                // Try to build more complete recommendations from the extracted data
                let recs = buildEnhancedRecommendations(from: simpleRecs, originalJSON: jsonString)
                print("🧱 Building enhanced recommendations from \(simpleRecs.count) lines…")
                await MainActor.run {
                    self.recommendations = recs
                    self.recommendationsUpdatedAt = Date()
                    self.recommendationsChangeLog = self.buildChangeLog(old: oldRecs, new: recs)
                    self.saveRecommendationsToDisk(recs)
                    print("✅ SkinAnalysisManager: Cached enhanced recommendations (disk)")
                    print("📋 Routines summary → morning: \(recs.morningRoutine.map{ $0.name }.joined(separator: ", ")), evening: \(recs.eveningRoutine.map{ $0.name }.joined(separator: ", ")), weekly: \(recs.weeklyTreatments.map{ $0.name }.joined(separator: ", ")) )")
                    self.isReloading = false
                }
                return
            }
            
            // Fallback 2: parse simple bullet lists from raw content
            let bulletLines = raw
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .compactMap { line -> String? in
                    // Accept formats like: "- item", "• item", "* item", "1) item", "1. item"
                    let prefixes = ["- ", "• ", "* ", "– ", "— "]
                    if let match = prefixes.first(where: { line.hasPrefix($0) }) {
                        return String(line.dropFirst(match.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    if let range = line.range(of: "^\\d+[)\\.]\\s+", options: .regularExpression) {
                        return String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    return nil
                }
            print("🔎 Bullet fallback produced \(bulletLines.count) items: \(bulletLines.prefix(15))")
            if !bulletLines.isEmpty {
                let recs = buildMinimalRecommendations(from: bulletLines)
                print("🧱 Building minimal recommendations from bullets…")
                await MainActor.run {
                    self.recommendations = recs
                    self.recommendationsUpdatedAt = Date()
                    self.recommendationsChangeLog = self.buildChangeLog(old: oldRecs, new: recs)
                    self.saveRecommendationsToDisk(recs)
                    print("✅ SkinAnalysisManager: Cached bullet-list recommendations (disk)")
                    print("📋 Routines summary → morning: \(recs.morningRoutine.map{ $0.name }.joined(separator: ", ")), evening: \(recs.eveningRoutine.map{ $0.name }.joined(separator: ", ")), weekly: \(recs.weeklyTreatments.map{ $0.name }.joined(separator: ", "))) ")
                    self.isReloading = false
                }
                return
            }
            
            print("❌ No recommendations parsed from any path; throwing decodingFailed")
            
        } catch {
            print("❌ SkinAnalysisManager: Failed to regenerate recommendations: \(error)")
            self.errorMessage = error.localizedDescription
            self.isReloading = false
        }
    }
    
    // MARK: - JSON Preprocessing for UUID Conversion
    
    /// Preprocesses JSON to convert string IDs to deterministic UUIDs before decoding
    private func preprocessJSONForUUIDConversion(_ jsonString: String) -> String {
        var processedJSON = jsonString
        
        // Validate JSON structure before processing
        guard processedJSON.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") &&
              processedJSON.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("}") else {
            print("⚠️ JSON preprocessing: Invalid JSON structure, returning original")
            return jsonString
        }
        
        // Convert string IDs to deterministic UUIDs for SkincareStep objects
        // Pattern: "id": "step-1" -> "id": "generated-uuid"
        let stepIdPattern = #""id"\s*:\s*"step-(\d+)""#
        if let regex = try? NSRegularExpression(pattern: stepIdPattern) {
            let matches = regex.matches(in: processedJSON, range: NSRange(location: 0, length: processedJSON.count))
            
            // Process matches in reverse order to avoid index shifting
            for match in matches.reversed() {
                if match.numberOfRanges > 1 {
                    let stepNumberRange = match.range(at: 1)
                    let stepNumber = (processedJSON as NSString).substring(with: stepNumberRange)
                    
                    // Generate deterministic UUID from step number
                    let deterministicUUID = generateDeterministicUUID(from: "step-\(stepNumber)")
                    
                    // Replace the string ID with the UUID
                    let replacement = "\"id\": \"\(deterministicUUID)\""
                    let fullMatchRange = match.range
                    processedJSON = (processedJSON as NSString).replacingCharacters(in: fullMatchRange, with: replacement)
                    
                    print("✅ SkincareStep: String ID 'step-\(stepNumber)' converted to deterministic UUID")
                }
            }
        }
        
        // Convert string IDs to deterministic UUIDs for ProductRecommendation objects
        // Pattern: "id": "prod-1" -> "id": "generated-uuid"
        let productIdPattern = #""id"\s*:\s*"prod-(\d+)""#
        if let regex = try? NSRegularExpression(pattern: productIdPattern) {
            let matches = regex.matches(in: processedJSON, range: NSRange(location: 0, length: processedJSON.count))
            
            // Process matches in reverse order to avoid index shifting
            for match in matches.reversed() {
                if match.numberOfRanges > 1 {
                    let prodNumberRange = match.range(at: 1)
                    let prodNumber = (processedJSON as NSString).substring(with: prodNumberRange)
                    
                    // Generate deterministic UUID from product number
                    let deterministicUUID = generateDeterministicUUID(from: "prod-\(prodNumber)")
                    
                    // Replace the string ID with the UUID
                    let replacement = "\"id\": \"\(deterministicUUID)\""
                    let fullMatchRange = match.range
                    processedJSON = (processedJSON as NSString).replacingCharacters(in: fullMatchRange, with: replacement)
                    
                    print("✅ ProductRecommendation: String ID 'prod-\(prodNumber)' converted to deterministic UUID")
                }
            }
        }
        
        // Validate the processed JSON is still valid
        if let data = processedJSON.data(using: .utf8) {
            do {
                _ = try JSONSerialization.jsonObject(with: data, options: [])
                print("✅ JSON preprocessing: Processed JSON is valid")
                return processedJSON
            } catch {
                print("⚠️ JSON preprocessing: Processed JSON is invalid (\(error.localizedDescription)), returning original")
                return jsonString
            }
        } else {
            print("⚠️ JSON preprocessing: Could not convert processed JSON to data, returning original")
            return jsonString
        }
    }
    
    /// Generates a deterministic UUID from a string seed
    private func generateDeterministicUUID(from seed: String) -> String {
        // Create a deterministic UUID by hashing the seed
        let data = seed.data(using: .utf8) ?? Data()
        let hash = data.withUnsafeBytes { bytes in
            var hash: UInt64 = 5381
            for byte in bytes {
                hash = ((hash << 5) &+ hash) &+ UInt64(byte)
            }
            return hash
        }
        
        // Convert hash to UUID format
        let uuidString = String(format: "%08X-%04X-%04X-%04X-%012X",
                               UInt32((hash >> 32) & 0xFFFFFFFF),
                               UInt16((hash >> 16) & 0xFFFF),
                               UInt16(hash & 0xFFFF),
                               UInt16((hash >> 48) & 0xFFFF),
                               UInt64(hash & 0xFFFFFFFFFFFF))
        
        return uuidString
    }
    
    // MARK: - JSON Truncation Detection and Recovery
    
    private func detectAndRecoverTruncatedJSON(_ jsonString: String) -> String? {
        print("🔍 Analyzing JSON for truncation patterns...")
        
        // Check if JSON appears to be truncated mid-object
        let patterns = [
            // Truncated in the middle of a string value
            "\"[^\"]*$",
            // Truncated in the middle of an array
            "\\[[^\\]]*$",
            // Truncated in the middle of an object
            "\\{[^}]*$",
            // Truncated after a comma
            ",\\s*$",
            // Truncated after a colon
            ":\\s*$"
        ]
        
        for pattern in patterns {
            if let range = jsonString.range(of: pattern, options: .regularExpression) {
                let truncatedPart = String(jsonString[range.lowerBound...])
                print("🔍 Detected truncation pattern: \(pattern)")
                print("🔍 Truncated content: \(truncatedPart)")
                
                // Try to find the last complete object/array and close it
                if let recovered = attemptTruncationRecovery(jsonString) {
                    print("✅ Successfully recovered truncated JSON")
                    return recovered
                }
            }
        }
        
        return nil
    }
    
    private func attemptTruncationRecovery(_ jsonString: String) -> String? {
        var recovered = jsonString
        
        // Count open braces and brackets
        var braceCount = 0
        var bracketCount = 0
        var inString = false
        var escape = false
        
        for char in jsonString {
            if char == "\\" { escape.toggle(); continue }
            if char == "\"" && !escape { inString.toggle() }
            if !inString {
                if char == "{" { braceCount += 1 }
                else if char == "}" { braceCount -= 1 }
                else if char == "[" { bracketCount += 1 }
                else if char == "]" { bracketCount -= 1 }
            }
            if char != "\\" { escape = false }
        }
        
        // Close any unclosed braces/brackets
        while bracketCount > 0 {
            recovered.append("]")
            bracketCount -= 1
        }
        
        while braceCount > 0 {
            recovered.append("}")
            braceCount -= 1
        }
        
        // Remove trailing commas before closing braces/brackets
        recovered = recovered.replacingOccurrences(of: ",\\s*([}\\]])", with: "$1", options: .regularExpression)
        
        // Validate the recovered JSON
        if let data = recovered.data(using: .utf8),
           let _ = try? JSONSerialization.jsonObject(with: data, options: []) {
            return recovered
        }
        
        return nil
    }
    
    // MARK: - JSON Sanitizer (balances braces/brackets and removes trailing commas)
    private func sanitizePossiblyTruncatedJSON(_ text: String) -> String {
        var result = text
        // Remove trailing commas before a closing } or ]
        let trailingCommaPattern = ",\\s*(\\}|\\])"
        result = result.replacingOccurrences(of: trailingCommaPattern, with: "$1", options: .regularExpression)
        // Balance braces/brackets
        var stack: [Character] = []
        var inString = false
        var escape = false
        for ch in result {
            if ch == "\\" { escape.toggle(); continue }
            if ch == "\"" && !escape { inString.toggle() }
            if !inString {
                if ch == "{" || ch == "[" { stack.append(ch) }
                else if ch == "}" { if let last = stack.last, last == "{" { stack.removeLast() } }
                else if ch == "]" { if let last = stack.last, last == "[" { stack.removeLast() } }
            }
            if ch != "\\" { escape = false }
        }
        while let open = stack.popLast() {
            result.append(open == "{" ? "}" : "]")
        }
        return result
    }
    
    private func buildChangeLog(old: SkincareRecommendations?, new: SkincareRecommendations) -> [String] {
        func names(_ steps: [SkincareStep]) -> Set<String> { Set(steps.map { $0.name }) }
        func line(title: String, old: [SkincareStep]?, new: [SkincareStep]) -> String? {
            let oldSet = names(old ?? [])
            let newSet = names(new)
            let added = newSet.subtracting(oldSet)
            let removed = oldSet.subtracting(newSet)
            if added.isEmpty && removed.isEmpty { return nil }
            let addedList = added.prefix(3).joined(separator: ", ")
            let removedList = removed.prefix(3).joined(separator: ", ")
            var parts: [String] = []
            if !added.isEmpty { parts.append("+ " + addedList) }
            if !removed.isEmpty { parts.append("− " + removedList) }
            return title + ": " + parts.joined(separator: "  ")
        }
        var items: [String] = []
        if let l = line(title: "Morning", old: old?.morningRoutine, new: new.morningRoutine) { items.append(l) }
        if let l = line(title: "Evening", old: old?.eveningRoutine, new: new.eveningRoutine) { items.append(l) }
        if let l = line(title: "Weekly", old: old?.weeklyTreatments, new: new.weeklyTreatments) { items.append(l) }
        if items.isEmpty { items.append("Routines updated") }
        return items
    }
    
    // Minimal text-only request using the same HTTP stack
    private func makeTextOnlyRequest(model: String, prompt: String) async throws -> String {
        struct TextMessage: Codable { let role: String; let content: String }
        struct ResponseFormat: Codable { let type: String }
        struct TextReq: Codable {
            let model: String; let messages: [TextMessage]; let temperature: Double; let top_p: Double; let max_tokens: Int; let seed: Int?; let response_format: ResponseFormat?
        }
        struct TextResp: Codable { struct Choice: Codable { struct Msg: Codable { let content: String }; let message: Msg }; let choices: [Choice] }
        
        // No need to check API key - Supabase proxy handles authentication
        let system = TextMessage(role: "system", content: "You are a skincare expert that returns strict JSON only.")
        let user = TextMessage(role: "user", content: prompt)
        
        // Convert to the format expected by Supabase proxy
        let messagesDict = [
            [
                "role": system.role,
                "content": system.content
            ],
            [
                "role": user.role,
                "content": user.content
            ]
        ]
        
        // Use Supabase proxy instead of direct OpenAI call
        let response = try await SupabaseProxyManager.shared.makeOpenAIRequest(
            model: model,
            messages: messagesDict,
            maxTokens: APIConfig.maxTokensPerRequest,
            temperature: 0.0
        )
        
        // Parse the response from Supabase proxy
        guard let data = response.data(using: .utf8) else {
            throw ChatGPTError.invalidResponse
        }
        
        print("📡 Supabase proxy response received")
        do {
            let decoded = try JSONDecoder().decode(TextResp.self, from: data)
            return decoded.choices.first?.message.content ?? "{}"
        } catch {
            // If decoding into the expected shape fails, fall back to returning the raw string body
            print("ℹ️ TextResp decode failed: \(error). Falling back to raw UTF-8 body for downstream parsing.")
            if let s = String(data: data, encoding: .utf8) {
                return s
            }
            throw error
        }
    }
    
    private func extractJSONFromResponse(_ response: String) -> String {
        // Strip common code fences and return the JSON object substring
        let content = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```JSON", with: "")
            .replacingOccurrences(of: "```Json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let startIndex = content.firstIndex(of: "{"), let endIndex = content.lastIndex(of: "}") {
            return String(content[startIndex...endIndex])
        }
        return content
    }
    
    private func extractStringArray(named key: String, from text: String) -> [String] {
        // Very lightweight extractor for: "key": ["a", "b", ...]
        let pattern = "\\\"\(key)\\\"\\s*:\\s*\\["
        guard let keyRange = text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) else { return [] }
        let tail = text[keyRange.upperBound...]
        guard let end = tail.firstIndex(of: "]") else { return [] }
        let arraySlice = tail[..<end]
        let items = arraySlice.split(separator: ",")
            .map { $0.replacingOccurrences(of: "\n", with: " ") }
            .map { $0.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return items
    }
    
    private func buildMinimalRecommendations(from lines: [String]) -> SkincareRecommendations {
        func makeStep(_ text: String, freq: SkincareStep.Frequency) -> SkincareStep {
            SkincareStep(
                id: UUID(),
                name: text,
                description: text,
                category: .treatment,
                duration: 60,
                frequency: freq,
                stepTime: freq == .daily ? .anytime : (freq == .weekly ? .anytime : .anytime),
                conflictsWith: [],
                requiresSPF: text.lowercased().contains("spf") || text.lowercased().contains("sunscreen"),
                tips: []
            )
        }
        let morning = lines.prefix(2).map { makeStep($0, freq: .daily) }
        let evening = Array(lines.dropFirst(2).prefix(1)).map { makeStep($0, freq: .daily) }
        let weekly = Array(lines.dropFirst(3)).map { makeStep($0, freq: .weekly) }
        let metrics = ProgressMetrics(skinHealthScore: 0.75, improvementAreas: [], nextCheckIn: Date().addingTimeInterval(7*24*3600), goals: [])
        return SkincareRecommendations(morningRoutine: morning, eveningRoutine: evening, weeklyTreatments: weekly, lifestyleTips: [], productRecommendations: [], progressTracking: metrics)
    }
    
    private func buildEnhancedRecommendations(from routineNames: [String], originalJSON: String) -> SkincareRecommendations {
        // Try to extract more detailed information from the original JSON
        var enhancedSteps: [SkincareStep] = []
        
        if let data = originalJSON.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            
            // Extract detailed step information from the original JSON
            if let morningRoutine = json["morningRoutine"] as? [[String: Any]] {
                for stepDict in morningRoutine {
                    guard let name = stepDict["name"] as? String, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                    
                    let description = stepDict["description"] as? String ?? name
                    let category = stepDict["category"] as? String ?? "treatment"
                    let duration = stepDict["duration"] as? Int ?? 60
                    let frequency = stepDict["frequency"] as? String ?? "daily"
                    let stepTime = stepDict["stepTime"] as? String ?? "morning"
                    let conflictsWith = stepDict["conflictsWith"] as? [String] ?? []
                    let requiresSPF = stepDict["requiresSPF"] as? Bool ?? false
                    let tips = stepDict["tips"] as? [String] ?? []
                    
                    let step = SkincareStep(
                        id: UUID(),
                        name: name,
                        description: description,
                        category: SkincareStep.StepCategory(rawValue: category.lowercased()) ?? .treatment,
                        duration: duration,
                        frequency: SkincareStep.Frequency(rawValue: frequency.lowercased()) ?? .daily,
                        stepTime: SkincareStep.StepTime(rawValue: stepTime.lowercased()) ?? .morning,
                        conflictsWith: conflictsWith,
                        requiresSPF: requiresSPF,
                        tips: tips
                    )
                    enhancedSteps.append(step)
                }
            }
            
            // Extract evening routine steps
            if let eveningRoutine = json["eveningRoutine"] as? [[String: Any]] {
                for stepDict in eveningRoutine {
                    guard let name = stepDict["name"] as? String, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                    
                    let description = stepDict["description"] as? String ?? name
                    let category = stepDict["category"] as? String ?? "treatment"
                    let duration = stepDict["duration"] as? Int ?? 60
                    let frequency = stepDict["frequency"] as? String ?? "daily"
                    let stepTime = stepDict["stepTime"] as? String ?? "evening"
                    let conflictsWith = stepDict["conflictsWith"] as? [String] ?? []
                    let requiresSPF = stepDict["requiresSPF"] as? Bool ?? false
                    let tips = stepDict["tips"] as? [String] ?? []
                    
                    let step = SkincareStep(
                        id: UUID(),
                        name: name,
                        description: description,
                        category: SkincareStep.StepCategory(rawValue: category.lowercased()) ?? .treatment,
                        duration: duration,
                        frequency: SkincareStep.Frequency(rawValue: frequency.lowercased()) ?? .daily,
                        stepTime: SkincareStep.StepTime(rawValue: stepTime.lowercased()) ?? .evening,
                        conflictsWith: conflictsWith,
                        requiresSPF: requiresSPF,
                        tips: tips
                    )
                    enhancedSteps.append(step)
                }
            }
            
            // Extract weekly treatment steps
            if let weeklyTreatments = json["weeklyTreatments"] as? [[String: Any]] {
                for stepDict in weeklyTreatments {
                    guard let name = stepDict["name"] as? String, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                    
                    let description = stepDict["description"] as? String ?? name
                    let category = stepDict["category"] as? String ?? "treatment"
                    let duration = stepDict["duration"] as? Int ?? 60
                    let frequency = stepDict["frequency"] as? String ?? "weekly"
                    let stepTime = stepDict["stepTime"] as? String ?? "anytime"
                    let conflictsWith = stepDict["conflictsWith"] as? [String] ?? []
                    let requiresSPF = stepDict["requiresSPF"] as? Bool ?? false
                    let tips = stepDict["tips"] as? [String] ?? []
                    
                    let step = SkincareStep(
                        id: UUID(),
                        name: name,
                        description: description,
                        category: SkincareStep.StepCategory(rawValue: category.lowercased()) ?? .treatment,
                        duration: duration,
                        frequency: SkincareStep.Frequency(rawValue: frequency.lowercased()) ?? .weekly,
                        stepTime: SkincareStep.StepTime(rawValue: stepTime.lowercased()) ?? .anytime,
                        conflictsWith: conflictsWith,
                        requiresSPF: requiresSPF,
                        tips: tips
                    )
                    enhancedSteps.append(step)
                }
            }
        }
        
        // If we couldn't extract detailed steps, fall back to minimal
        if enhancedSteps.isEmpty {
            return buildMinimalRecommendations(from: routineNames)
        }
        
        // Organize steps by their original structure
        let morningCount = enhancedSteps.filter { $0.stepTime == .morning }.count
        let eveningCount = enhancedSteps.filter { $0.stepTime == .evening }.count
        
        let morning = Array(enhancedSteps.prefix(morningCount))
        let evening = Array(enhancedSteps.dropFirst(morningCount).prefix(eveningCount))
        let weekly = Array(enhancedSteps.dropFirst(morningCount + eveningCount))
        
        let metrics = ProgressMetrics(skinHealthScore: 0.75, improvementAreas: [], nextCheckIn: Date().addingTimeInterval(7*24*3600), goals: [])
        return SkincareRecommendations(morningRoutine: morning, eveningRoutine: evening, weeklyTreatments: weekly, lifestyleTips: [], productRecommendations: [], progressTracking: metrics)
    }
    
    private func startAnalysisProgress() {
        analysisTimer?.invalidate()
        analysisProgress = 0.02
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] t in
            Task { @MainActor in
                guard let self = self else { return }
                if self.analysisProgress < 0.9 {
                    self.analysisProgress = min(self.analysisProgress + 0.02, 0.9)
                }
            }
        }
        RunLoop.main.add(analysisTimer!, forMode: .common)
    }
    
    private func stopAnalysisProgress() {
        analysisTimer?.invalidate()
        analysisTimer = nil
    }

    private func completeAnalysis(with result: SkinAnalysisResult) {
        self.analysisResults = result
        self.analysisProgress = 1.0
        self.stopAnalysisProgress()
        self.isAnalyzing = false

        // Increment analysis count for tier tracking
        self.userTierManager.incrementAnalysisCount()

        // Send notification when analysis is complete
        LocalNotificationService.shared.sendSkinAnalysisCompleteNotification()
        NotificationCenter.default.post(name: .nuraAnalysisCompleted, object: result)

        // Trigger product loading after analysis is complete
        NotificationCenter.default.post(name: .nuraTriggerProductLoading, object: nil)
    }
    
    // MARK: - Local Rules Engine
    private func applyLocalRules(to recs: SkincareRecommendations) -> SkincareRecommendations {
        func filterAndAdjust(_ steps: [SkincareStep], isEvening: Bool) -> [SkincareStep] {
            print("🧪 RulesEngine: Input steps=\(steps.count) isEvening=\(isEvening)")
            var kept: [SkincareStep] = []
            for step in steps {
                // Drop SPF at night
                if isEvening && step.requiresSPF { continue }
                kept.append(step)
            }
            // Remove conflicts: if two steps conflict, keep the first higher-priority category order
            // Priority order heuristic
            let priority: [SkincareStep.StepCategory: Int] = [
                .cleanser: 0, .toner: 1, .serum: 2, .exfoliant: 3, .bha: 3, .aha: 3, .treatment: 4, .moisturizer: 5, .sunscreen: 6, .mask: 7, .clay: 7
            ]
            var result: [SkincareStep] = []
            var presentTags: Set<String> = []
            for step in kept.sorted(by: { (priority[$0.category] ?? 99) < (priority[$1.category] ?? 99) }) {
                let conflicts = Set(step.conflictsWith.map { $0.lowercased() })
                if !presentTags.isDisjoint(with: conflicts) { continue }
                // Add tags derived from name/category for basic conflict detection
                var tags: Set<String> = []
                if step.name.lowercased().contains("retinol") || step.name.lowercased().contains("retinoid") { tags.insert("retinoid") }
                if step.name.lowercased().contains("salicylic") || step.name.lowercased().contains("bha") || step.name.lowercased().contains("exfoli") { tags.insert("strong_exfoliant") }
                if step.name.lowercased().contains("benzoyl") { tags.insert("benzoyl_peroxide") }
                if step.name.lowercased().contains("vitamin c") || step.name.lowercased().contains("ascorbic") { tags.insert("vitamin_c") }
                presentTags.formUnion(tags)
                result.append(step)
            }
            print("🧪 RulesEngine: Output steps=\(result.count) (removed=\(kept.count - result.count))")
            // Skin-age guidance: if estimated skin age suggests aging > chronological, bias to retinoid/antioxidant presence
            if let skinAge = analysisResults?.skinAgeYears {
                // Heuristic: if skinAge exceeds chronological by 5+, ensure an evening retinoid when safe
                let onboardingAgeString = AuthenticationManager.shared.getOnboardingAnswers()?.age ?? ""
                let assumedChrono = Int(onboardingAgeString.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 28
                if skinAge - assumedChrono >= 5 {
                    let hasRetinoid = result.contains { $0.name.lowercased().contains("retinol") || $0.name.lowercased().contains("retinoid") }
                    if !hasRetinoid && isEvening {
                        let retinoid = SkincareStep(
                            name: "Retinoid Treatment",
                            description: "Apply a pea-sized amount of retinoid to clean, dry skin.",
                            category: .treatment,
                            duration: 60,
                            frequency: .nightly,
                            stepTime: .evening,
                            conflictsWith: ["strong_exfoliant", "vitamin_c"],
                            requiresSPF: false,
                            tips: ["Start 2-3x/week if sensitive and increase as tolerated"]
                        )
                        result.append(retinoid)
                    }
                }
            }
            return result
        }
        let morning = filterAndAdjust(recs.morningRoutine, isEvening: false)
        let evening = filterAndAdjust(recs.eveningRoutine, isEvening: true)
        let weekly = recs.weeklyTreatments // cadence enforcement can be layered later with history
        return SkincareRecommendations(morningRoutine: morning, eveningRoutine: evening, weeklyTreatments: weekly, lifestyleTips: recs.lifestyleTips, productRecommendations: recs.productRecommendations, progressTracking: recs.progressTracking)
    }
}
