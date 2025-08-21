import Foundation
import UIKit
import Supabase

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
    
    private let chatGPTService = ChatGPTServiceManager()
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
        isAnalyzing = true
        errorMessage = nil
        uploadedImages = images
        startAnalysisProgress()
        
        Task {
            do {
                print("🔍 SkinAnalysisManager: Starting ChatGPT Vision API analysis...")
                // Analyze images using ChatGPT Vision API
                let result = try await chatGPTService.analyzeSkinImages(images, userTier: userTierManager.tier)
                
                print("🔍 SkinAnalysisManager: Analysis completed successfully")
                await MainActor.run {
                    self.analysisResults = result
                    self.analysisProgress = 1.0
                    self.stopAnalysisProgress()
                    self.isAnalyzing = false
                    
                    // Increment analysis count for tier tracking
                    self.userTierManager.incrementAnalysisCount()
                    
                    // Send notification when analysis is complete
                    LocalNotificationService.shared.sendSkinAnalysisCompleteNotification()
                    NotificationCenter.default.post(name: .nuraAnalysisCompleted, object: result)
                }
                
            } catch {
                print("❌ SkinAnalysisManager: Analysis failed with error: \(error)")
                print("❌ SkinAnalysisManager: Error details: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.stopAnalysisProgress()
                    self.analysisProgress = 0.0
                    self.isAnalyzing = false
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
            self.recommendations = recs
            print("✅ SkinAnalysisManager: Loaded cached recommendations from disk")
            return
        }
        // Backward-compatibility: try legacy UserDefaults cache once
        if let data = UserDefaults.standard.data(forKey: recommendationsCacheKey),
           let recs = try? JSONDecoder().decode(SkincareRecommendations.self, from: data) {
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
            reloadStartTime = Date() // Set start time for timer
            let oldRecs = self.recommendations
            let startTs = Date()
            // Build a lightweight pseudo-prompt by serializing current results
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let resultsData = try encoder.encode(results)
            let resultsJSON = String(data: resultsData, encoding: .utf8) ?? "{}"
            
            let prompt = """
            You are a board-certified dermatologist. Generate skincare routines aligned with best practices. Return STRICT JSON only, no prose, matching this schema:
            {
              "morningRoutine": [{
                "id":"uuid-optional",
                "name":"string",
                "description":"short action sentence",
                "category":"cleanser|toner|serum|moisturizer|sunscreen|treatment|mask",
                "duration":60,
                "frequency":"daily|twice_daily|nightly|two_to_three_per_week|weekly|as_needed",
                "stepTime":"morning|evening|anytime",
                "conflictsWith":["retinoid","strong_exfoliant","benzoyl_peroxide", "vitamin_c"],
                "requiresSPF":true,
                "tips":["short tip"]
              }],
              "eveningRoutine": [<same object as above>],
              "weeklyTreatments": [<same object as above>],
              "lifestyleTips": ["string"],
              "productRecommendations": [],
              "progressTracking": {"skinHealthScore": <0-1>, "improvementAreas": ["string"], "nextCheckIn": "ISODate", "goals": ["string"]}
            }
            Hard rules:
            - Do NOT include sunscreen steps at night (stepTime == evening should never requireSPF).
            - Avoid stacking conflicting actives in the same routine; set appropriate conflicts in conflictsWith.
            - Cap strong actives (retinoids, strong exfoliants, clay masks) to weekly or two_to_three_per_week where appropriate.
            - Use concise descriptions.
            Reply with JSON only. Analysis JSON:
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
            
            // Try decoding full SkincareRecommendations
            if let data = jsonString.data(using: .utf8) {
                print("📦 Attempting JSON decode: bytes=\(data.count)")
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
                    // Retry with sanitized JSON if truncated or unbalanced
                    let sanitized = sanitizePossiblyTruncatedJSON(jsonString)
                    if sanitized != jsonString, let sData = sanitized.data(using: .utf8), let recsTry = try? JSONDecoder().decode(SkincareRecommendations.self, from: sData) {
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
                            print("📋 Routines summary → morning: \(recs.morningRoutine.map{ $0.name }.joined(separator: ", ")), evening: \(recs.eveningRoutine.map{ $0.name }.joined(separator: ", ")), weekly: \(recs.weeklyTreatments.map{ $0.name }.joined(separator: ", "))) ")
                            self.isReloading = false
                            print("⏱️ Total regenerate latency: \(String(format: "%.2fs", Date().timeIntervalSince(startTs)))")
                            NotificationCenter.default.post(name: .nuraRecommendationsUpdated, object: recs)
                        }
                        return
                    }
                    // One-time retry with stricter JSON-mode instruction if still invalid
                    print("🔁 Retrying once with stricter JSON enforcement…")
                    let stricterPrompt = "Return strict JSON only with keys morningRoutine, eveningRoutine, weeklyTreatments, lifestyleTips, productRecommendations, progressTracking. No commentary. Ensure valid JSON and close all arrays/objects. Limit morning to 4, evening to 4, weekly to 2 items.\n" + prompt
                    let retryRaw = try await makeTextOnlyRequest(model: model, prompt: stricterPrompt)
                    let retryJSON = extractJSONFromResponse(retryRaw)
                    if let rData = retryJSON.data(using: .utf8), let recs2 = try? JSONDecoder().decode(SkincareRecommendations.self, from: rData) {
                        var recs = recs2
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
                            print("✅ SkinAnalysisManager: Cached recommendations (disk) [retry]")
                            self.isReloading = false
                            NotificationCenter.default.post(name: .nuraRecommendationsUpdated, object: recs)
                        }
                        return
                    }
                    // Attempt to find first JSON object substring explicitly
                    if let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") {
                        let inner = String(raw[start...end])
                        print("🔍 Trying inner JSON slice (first 300): \(inner.prefix(300))…")
                        if let innerData = inner.data(using: .utf8) {
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
            
            // Fallback: extract a simple recommendations string array and convert to routines
            var simpleRecs = extractStringArray(named: "recommendations", from: jsonString)
            print("🔎 Fallback array under key 'recommendations' → count: \(simpleRecs.count)")
            if simpleRecs.isEmpty, let data = jsonString.data(using: .utf8) {
                if let any = try? JSONSerialization.jsonObject(with: data, options: []),
                   let dict = any as? [String: Any] {
                    print("🔑 Top-level keys: \(Array(dict.keys))")
                    if let rawArray = dict["recommendations"] as? [Any] {
                        simpleRecs = rawArray.compactMap { $0 as? String }.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                        print("🔎 JSONSerialization path produced \(simpleRecs.count) items: \(simpleRecs.prefix(10))")
                    } else if let morning = dict["morningRoutine"] as? [String],
                              let evening = dict["eveningRoutine"] as? [String] {
                        let weekly = dict["weeklyTreatments"] as? [String] ?? []
                        simpleRecs = morning + evening + weekly
                        print("🔎 Parsed string arrays → morning: \(morning.count), evening: \(evening.count), weekly: \(weekly.count)")
                    }
                } else {
                    print("ℹ️ JSONSerialization could not parse jsonString")
                }
            }
            if simpleRecs.isEmpty {
                // Last-ditch: scan for a bracketed array by key name, case-insensitive
                if let range = jsonString.range(of: "\"recommendations\"", options: [.caseInsensitive]) {
                    let tail = jsonString[range.upperBound...]
                    if let start = tail.firstIndex(of: "["), let end = tail[start...].lastIndex(of: "]") {
                        let slice = tail[start...end]
                        let inner = slice.dropFirst().dropLast()
                        let parts = inner.split(separator: ",")
                        simpleRecs = parts.map { String($0).replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
                        print("🔎 Bracket scan produced \(simpleRecs.count) items: \(simpleRecs.prefix(10))")
                    } else {
                        print("ℹ️ Bracket scan failed to find [ ... ] after key")
                    }
                } else {
                    print("ℹ️ Could not find 'recommendations' key for bracket scan")
                }
            }
            if !simpleRecs.isEmpty {
                let recs = buildMinimalRecommendations(from: simpleRecs)
                print("🧱 Building minimal recommendations from \(simpleRecs.count) lines…")
                await MainActor.run {
                    self.recommendations = recs
                    self.recommendationsUpdatedAt = Date()
                    self.recommendationsChangeLog = self.buildChangeLog(old: oldRecs, new: recs)
                    self.saveRecommendationsToDisk(recs)
                    print("✅ SkinAnalysisManager: Cached minimal recommendations (disk)")
                    print("📋 Routines summary → morning: \(recs.morningRoutine.map{ $0.name }.joined(separator: ", ")), evening: \(recs.eveningRoutine.map{ $0.name }.joined(separator: ", ")), weekly: \(recs.weeklyTreatments.map{ $0.name }.joined(separator: ", "))) ")
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
                .cleanser: 0, .toner: 1, .serum: 2, .treatment: 3, .moisturizer: 4, .sunscreen: 5, .mask: 6
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
            return result
        }
        let morning = filterAndAdjust(recs.morningRoutine, isEvening: false)
        let evening = filterAndAdjust(recs.eveningRoutine, isEvening: true)
        let weekly = recs.weeklyTreatments // cadence enforcement can be layered later with history
        return SkincareRecommendations(morningRoutine: morning, eveningRoutine: evening, weeklyTreatments: weekly, lifestyleTips: recs.lifestyleTips, productRecommendations: recs.productRecommendations, progressTracking: recs.progressTracking)
    }
}
