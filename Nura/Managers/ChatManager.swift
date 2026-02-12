import Foundation
import Supabase

class ChatManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var memory: ChatMemory = ChatMemory(morningRoutine: [], eveningRoutine: [], weeklyTreatments: [], analysisNotes: [], lastUpdated: Date())
    
    private let userDefaults = UserDefaults.standard
    private let messagesKey = "nura_chat_messages_v1"
    private let memoryKey = "nura_chat_memory_v1"
    
    private let maxHistoryMessages = 16 // frugal token use while preserving flow
    
    // Location for SkinAnalysisManager disk cache (duplicated path to avoid tight coupling)
    private var recommendationsCacheURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Nura", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("recommendations.json")
    }

    init() {
        loadPersistedState()
        if messages.isEmpty {
            messages.append(ChatMessage(
                id: UUID(),
                content: "Hi, I’m Nura. Your personal skin concierge. I’m here to help you with all things skin—routine, products, and confidence. What’s on your mind today?",
                isUser: false,
                timestamp: Date()
            ))
            persistMessages()
        }
    }
    
    func sendMessage(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let userMessage = ChatMessage(
            id: UUID(),
            content: trimmed,
            isUser: true,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.messages.append(userMessage)
            self.persistMessages()
            self.isLoading = true
            self.errorMessage = nil
        }
        
        Task { [weak self] in
            guard let self else { return }
            do {
                // Skin type intent: if the user asks about their skin type, answer instantly using diary trends
                if Self.isSkinTypeQuery(trimmed) {
                    let response = self.composeSkinTypeAnswer()
                    await MainActor.run {
                        self.isLoading = false
                        self.messages.append(ChatMessage(id: UUID(), content: response, isUser: false, timestamp: Date()))
                        self.persistMessages()
                    }
                    return
                }
                // Opportunistically sync memory from disk-cached recommendations before sending
                self.syncMemoryFromRecommendationsIfAvailable()
                let reply = try await self.requestChatCompletion(userPrompt: trimmed)
                await MainActor.run {
                    self.isLoading = false
                    let visible = self.extractAndApplyMemory(from: reply)
                    var aiMessage = ChatMessage(
                        id: UUID(),
                        content: visible,
                        isUser: false,
                        timestamp: Date()
                    )
                    // 1) Only attach product cards when the user explicitly asked for products this turn
                    // Prevent product search when the message came from barcode scan (contains a sentinel tag)
                    let isBarcodeQuery = trimmed.contains("[barcode_query]")
                    let userWantsProducts = !isBarcodeQuery && ProductSearchManager.shared.detectProductQuery(trimmed) != nil
                    let explicitNames = userWantsProducts ? ProductSearchManager.shared.extractProductNames(from: visible) : []
                    if userWantsProducts && !explicitNames.isEmpty {
                        print("🔎 Explicit product mentions detected: \(explicitNames)")
                        aiMessage.productResults = []
                        self.messages.append(aiMessage)
                        self.persistMessages()
                        let targetIndex = self.messages.count - 1
                        Task {
                            let results = await ProductSearchManager.shared.searchProducts(forNames: explicitNames)
                            await MainActor.run {
                                if self.messages.indices.contains(targetIndex) {
                                    if results.isEmpty {
                                        // Fallback: run category search off the user's prompt
                                        if let query = ProductSearchManager.shared.detectProductQuery(trimmed) {
                                            Task { @MainActor in
                                                let catResults = await ProductSearchManager.shared.searchProducts(query: query)
                                                if self.messages.indices.contains(targetIndex) {
                                                    self.messages[targetIndex].productResults = catResults
                                                    print("🧩 Fallback attached \(catResults.count) category results to AI message")
                                                    self.persistMessages()
                                                }
                                            }
                                        } else {
                                            print("⚠️ No explicit-name results and no category intent; leaving text only")
                                        }
                                    } else {
                                        self.messages[targetIndex].productResults = results
                                        print("🧩 Attached \(results.count) explicit-name product results to AI message")
                                        self.persistMessages()
                                    }
                                }
                            }
                        }
                        return
                    }
                    // 2) Otherwise, detect product intent from the user's message and run a category search
                    if let query = ProductSearchManager.shared.detectProductQuery(trimmed) {
                        print("🔎 Product intent detected for query=\(query.normalizedQuery) cat=\(query.categoryHint ?? "-")")
                        aiMessage.productResults = [] // placeholder; will be filled async for UI stability
                        self.messages.append(aiMessage)
                        self.persistMessages()
                        Task { @MainActor in
                            let results = await ProductSearchManager.shared.searchProducts(query: query)
                            if let lastIndex = self.messages.indices.last {
                                self.messages[lastIndex].productResults = results
                                print("🧩 Attached \(results.count) product results to last AI message")
                                self.persistMessages()
                            }
                        }
                        return
                    }
                    // 3) No product search – append plain AI message
                    self.messages.append(aiMessage)
                    self.persistMessages()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to get response from AI assistant"
                }
            }
        }
    }
    
    // MARK: - Skin Type Handling
    private static func isSkinTypeQuery(_ text: String) -> Bool {
        let l = text.lowercased()
        let phrases = [
            "what's my skin type", "what is my skin type", "do i have", "my skin type", "am i oily", "am i dry", "combination skin", "sensitive skin type"
        ]
        return phrases.contains { l.contains($0) }
    }
    
    private func composeSkinTypeAnswer() -> String {
        // Pull recent diary trends from SkinDiaryManager via NotificationCenter cache or UserDefaults
        // We read SkinDiaryManager entries from its stored UserDefaults to avoid tight coupling
        let ud = UserDefaults.standard
        if let data = ud.data(forKey: "skin_diary_entries"),
           let entries = try? JSONDecoder().decode([SkinDiaryEntry].self, from: data),
           !entries.isEmpty {
            // Analyze last 14 days
            let lastTwoWeeks = entries.filter { Date().timeIntervalSince($0.date) <= 14*24*3600 }
            let sample = lastTwoWeeks.isEmpty ? Array(entries.prefix(14)) : lastTwoWeeks
            let counts = sample.reduce(into: [String: Int]()) { acc, e in
                let mood = e.primaryMood
                acc[mood, default: 0] += 1
            }
            // Determine dominant mood
            let sorted = counts.sorted { $0.value > $1.value }
            let top = sorted.first?.key ?? "Clear"
            var hint = ""
            switch top.lowercased() {
            case "oily": hint = "Your recent logs trend oily. Focus on gentle foaming cleansers and non-comedogenic moisturizers."
            case "dry": hint = "Recent logs skew dry. Prioritize hydrating cleansers and ceramide-rich moisturizers."
            case "sensitive": hint = "Logs show sensitivity. Choose fragrance-free, minimal-ingredient formulas."
            default: hint = "You're trending clear most days. Maintain balance with a gentle cleanser and SPF."
            }
            return "Here's what I'm seeing from your Recent Skin Diary: you most often logged ‘\(top)’. \(hint)\n\nKeep using the ‘Recent Skin Diary’ nightly (6 PM–midnight). The more you log, the smarter and more personalized your answers get."
        } else {
            return "I don’t have enough of your diary data yet to infer your skin type. Start using the ‘Recent Skin Diary’ each evening (6 PM–midnight). With consistent logs, I’ll detect your trend (oily, dry, combination, sensitive) and tailor product picks and routines for you."
        }
    }

    private func requestChatCompletion(userPrompt: String) async throws -> String {
        // No need to check API key - Supabase proxy handles authentication
        
        // Build system prompt with current memory (includes productFeedback as 5th key)
        let memoryText = """
        You maintain concise, to-the-point skin coaching. Keep answers practical, in plain language. Avoid fluff.
        You remember the user's routine, analysis notes, and product feedback. Update memory gently when the user gives new info.
        Current memory (arrays may be empty):
        morningRoutine: \(memory.morningRoutine)
        eveningRoutine: \(memory.eveningRoutine)
        weeklyTreatments: \(memory.weeklyTreatments)
        analysisNotes: \(memory.analysisNotes)
        productFeedback: \(memory.productFeedback)
        Response rules:
        - Be brief and actionable.
        - If the user asks for a routine change or shares symptoms/preferences, incorporate them.
        - If memory has information, use it confidently and summarize what we know; do not say we have no info.
        - If memory is empty, ask for needed details.
        - If the user mentions they tried a product and liked/disliked it, or had a skin reaction, add it to productFeedback as a concise string (e.g. "CeraVe Cleanser: loved, months" or "Niacinamide serum: broke out, redness").
        - When recommending products, factor in productFeedback: prefer ingredients from loved products, avoid ingredients from products that caused breakouts or irritation.
        - When recommending products, include a hidden structured block with ingredient data using this exact format:
          <products>[{"name":"Product Name","brand":"Brand","ingredients":["ingredient1","ingredient2"],"category":"cleanser"}]</products>
          Only include this block when you mention specific product names. The block must be valid JSON array. Do not mention this block in visible text.
        - At the END of your message, include a hidden memory block using this exact format:
          <memory>{"morningRoutine":[...],"eveningRoutine":[...],"weeklyTreatments":[...],"analysisNotes":[...],"productFeedback":[...]}</memory>
        - The memory block must be valid JSON with exactly those five keys. Do not mention the memory block in the visible text.
        """
        
        let systemMessage = ChatGPTMessage(
            role: "system",
            content: [ChatGPTContent(type: "text", text: memoryText, imageURL: nil)]
        )
        
        // Convert recent conversation to ChatGPT messages (frugal history)
        let recent = Array(messages.suffix(maxHistoryMessages))
        var history: [ChatGPTMessage] = recent.map { msg in
            let role = msg.isUser ? "user" : "assistant"
            return ChatGPTMessage(role: role, content: [ChatGPTContent(type: "text", text: msg.content, imageURL: nil)])
        }
        history.insert(systemMessage, at: 0)
        history.append(ChatGPTMessage(role: "user", content: [ChatGPTContent(type: "text", text: userPrompt, imageURL: nil)]))
        
        // Convert to the format expected by Supabase proxy
        let messagesDict: [[String: Any]] = history.map { message in
            let contentAny: Any
            if message.content.count == 1 && message.content.first?.type == "text" {
                contentAny = message.content.first?.text ?? ""
            } else {
                contentAny = message.content.map { contentItem -> [String: Any] in
                    if contentItem.type == "text" {
                        return ["type": "text", "text": contentItem.text ?? ""]
                    } else if contentItem.type == "image_url" {
                        return ["type": "image_url", "image_url": ["url": contentItem.imageURL?.url ?? ""]]
                    } else {
                        return ["type": "text", "text": ""]
                    }
                }
            }
            
            return [
                "role": message.role as Any,
                "content": contentAny
            ]
        }
        
        // Use Supabase proxy instead of direct OpenAI call
        let responseString: String = try await SupabaseProxyManager.shared.makeOpenAIRequest(
            model: APIConfig.fastTextModel,
            messages: messagesDict,
            maxTokens: APIConfig.maxTokensPerRequest,
            temperature: 0.3
        )
        
        // Parse the response from Supabase proxy
        guard let data = responseString.data(using: .utf8) else {
            throw NSError(domain: "ChatManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }
        
        let openAIResponse = try JSONDecoder().decode(ChatGPTVisionResponse.self, from: data)
        guard let content = openAIResponse.choices.first?.message.content else {
            throw NSError(domain: "ChatManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Empty response"])
        }
        return content
    }
    
    // MARK: - Memory ingestion APIs
    func absorb(_ recs: SkincareRecommendations?) {
        guard let recs else { return }
        let morning = recs.morningRoutine.map { $0.name }
        let evening = recs.eveningRoutine.map { $0.name }
        let weekly = recs.weeklyTreatments.map { $0.name }
        let notes: [String] = Array(recs.lifestyleTips.prefix(4))
        mergeMemory(with: ChatMemoryUpdate(morningRoutine: morning, eveningRoutine: evening, weeklyTreatments: weekly, analysisNotes: notes))
    }

    func absorbAnalysisSummary(_ result: SkinAnalysisResult?) {
        guard let result else { return }
        // Create concise notes such as "acne (moderate)", "dark spots (mild)"
        let notes = result.conditions.prefix(5).map { "\($0.name) (\($0.severity.rawValue))" }
        mergeMemory(with: ChatMemoryUpdate(morningRoutine: nil, eveningRoutine: nil, weeklyTreatments: nil, analysisNotes: notes))
        memory.lastAnalysisDate = result.analysisDate
        persistMemory()
    }

    @discardableResult
    private func syncMemoryFromRecommendationsIfAvailable() -> Bool {
        guard let data = try? Data(contentsOf: recommendationsCacheURL), let recs = try? JSONDecoder().decode(SkincareRecommendations.self, from: data) else {
            return false
        }
        let before = memory
        absorb(recs)
        return before.morningRoutine != memory.morningRoutine || before.eveningRoutine != memory.eveningRoutine || before.weeklyTreatments != memory.weeklyTreatments || before.analysisNotes != memory.analysisNotes
    }

    // Extract <memory>{...}</memory> and <products>[...]</products> blocks from GPT response.
    // Memory block is merged into stored memory; products block enriches ProductSearchManager results with GPT-provided ingredients.
    // Both blocks are stripped from the visible text shown to the user.
    private func extractAndApplyMemory(from fullText: String) -> String {
        var text = fullText
        
        // 1. Extract and apply <memory> block
        let memoryPattern = #"<memory>(\{[\s\S]*?\})</memory>"#
        if let memoryRegex = try? NSRegularExpression(pattern: memoryPattern, options: []) {
            let range = NSRange(location: 0, length: (text as NSString).length)
            if let match = memoryRegex.firstMatch(in: text, options: [], range: range), match.numberOfRanges > 1 {
                let jsonRange = match.range(at: 1)
                if let swiftRange = Range(jsonRange, in: text) {
                    let jsonString = String(text[swiftRange])
                    if let data = jsonString.data(using: .utf8), let update = try? JSONDecoder().decode(ChatMemoryUpdate.self, from: data) {
                        mergeMemory(with: update)
                    }
                }
                // Remove memory block from visible text
                text = memoryRegex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            }
        }
        
        // 2. Extract and apply <products> block — GPT-provided ingredient data for recommended products
        let productsPattern = #"<products>(\[[\s\S]*?\])</products>"#
        if let productsRegex = try? NSRegularExpression(pattern: productsPattern, options: []) {
            let range = NSRange(location: 0, length: (text as NSString).length)
            if let match = productsRegex.firstMatch(in: text, options: [], range: range), match.numberOfRanges > 1 {
                let jsonRange = match.range(at: 1)
                if let swiftRange = Range(jsonRange, in: text) {
                    let jsonString = String(text[swiftRange])
                    parseAndCacheGPTProductIngredients(jsonString)
                }
                // Remove products block from visible text
                text = productsRegex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            }
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Parse GPT-provided product ingredient data and cache it for use by ProductSearchManager.
    /// Format: [{"name":"Product Name","brand":"Brand","ingredients":["ing1","ing2"],"category":"cleanser"}]
    private func parseAndCacheGPTProductIngredients(_ jsonString: String) {
        struct GPTProduct: Decodable {
            let name: String
            let brand: String?
            let ingredients: [String]?
            let category: String?
        }
        
        guard let data = jsonString.data(using: .utf8),
              let products = try? JSONDecoder().decode([GPTProduct].self, from: data) else {
            print("⚠️ ChatManager: Failed to decode <products> block")
            return
        }
        
        print("🧬 ChatManager: Parsed \(products.count) products with GPT-provided ingredients")
        for product in products {
            let ingredients = product.ingredients ?? []
            print("  → \(product.name) [\(product.brand ?? "?")] ingredients=\(ingredients.prefix(5))")
            // Store ingredient data in UserDefaults keyed by normalized product name
            // This allows ProductSearchManager and FitEvaluator to look up GPT-sourced ingredients
            let key = "nura.gpt_ingredients.\(product.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))"
            if let encoded = try? JSONEncoder().encode(ingredients) {
                UserDefaults.standard.set(encoded, forKey: key)
            }
        }
    }
    
    private func mergeMemory(with update: ChatMemoryUpdate) {
        func merge(_ current: inout [String], _ new: [String]?) {
            guard let new else { return }
            let combined = (current + new).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            // Deduplicate while preserving order
            var seen: Set<String> = []
            current = combined.filter { seen.insert($0.lowercased()).inserted }
            if current.count > 12 { current = Array(current.prefix(12)) }
        }
        merge(&memory.morningRoutine, update.morningRoutine)
        merge(&memory.eveningRoutine, update.eveningRoutine)
        merge(&memory.weeklyTreatments, update.weeklyTreatments)
        merge(&memory.analysisNotes, update.analysisNotes)
        merge(&memory.productFeedback, update.productFeedback)
        memory.lastUpdated = Date()
        persistMemory()
    }
    
    func clearChat() {
        messages.removeAll()
        messages.append(ChatMessage(
            id: UUID(),
            content: "Hi! I am your AI skin assistant. I can help you with skincare questions, analyze your skin concerns, and provide personalized advice. What would you like to know?",
            isUser: false,
            timestamp: Date()
        ))
        persistMessages()
    }
    
    func resetChatAndMemory() {
        // Clear memory
        memory = ChatMemory(morningRoutine: [], eveningRoutine: [], weeklyTreatments: [], analysisNotes: [], lastUpdated: Date(), lastAnalysisDate: nil)
        persistMemory()
        // Reset chat to the initial greeting
        clearChat()
    }
    
    // MARK: - Persistence
    private func loadPersistedState() {
        if let data = userDefaults.data(forKey: messagesKey), let saved = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            self.messages = saved
        }
        if let data = userDefaults.data(forKey: memoryKey), let saved = try? JSONDecoder().decode(ChatMemory.self, from: data) {
            self.memory = saved
        }
    }
    
    private func persistMessages() {
        if let data = try? JSONEncoder().encode(messages) {
            userDefaults.set(data, forKey: messagesKey)
        }
    }
    
    private func persistMemory() {
        if let data = try? JSONEncoder().encode(memory) {
            userDefaults.set(data, forKey: memoryKey)
        }
    }
}
