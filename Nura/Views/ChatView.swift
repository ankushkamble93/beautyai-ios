import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @EnvironmentObject var routineOverrideManager: RoutineOverrideManager
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @State private var showNuraProSheet = false
    @State private var showGlobalChatSheet = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                if userTierManager.tier == .free {
                    freeTierChat
                } else {
                    RecommendedProductsView()
                        .environmentObject(chatManager)
                        .environmentObject(appearanceManager)
                        .environmentObject(userTierManager)
                        .environmentObject(skinAnalysisManager)
                        .environmentObject(routineOverrideManager)
                }
                // Global Ask Nura bubble (visible across pushes, including product detail)
                if userTierManager.tier != .free {
                    let isDark = appearanceManager.isDarkMode
                    Button(action: { showGlobalChatSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "message.fill")
                            Text("Ask Nura")
                                .font(.callout).fontWeight(.semibold)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(isDark ? NuraColors.cardDark : Color(red: 0.976, green: 0.965, blue: 0.949))
                        .cornerRadius(24)
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                    .padding(20)
                    .padding(.bottom, 36)
                    .sheet(isPresented: $showGlobalChatSheet) {
                        MiniChatSheet()
                            .environmentObject(chatManager)
                            .environmentObject(appearanceManager)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
        }
        .id(appearanceManager.colorSchemePreference)
    }
    
    // MARK: - Free tier: existing chat (with paywall overlay)
    private var freeTierChat: some View {
        let isDark = appearanceManager.isDarkMode
        return VStack {
            // Title
            ZStack(alignment: .topTrailing) {
                HStack {
                    Spacer()
                    Text("Skin Concierge")
                        .font(.largeTitle).fontWeight(.bold)
                        .padding(.top, 8)
                    Spacer()
                }
                Menu {
                    Button(role: .destructive) {
                        chatManager.resetChatAndMemory()
                    } label: {
                        Label("Reset Chat & Memory", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .padding(.top, 8)
                        .padding(.trailing, 16)
                }
            }
            Spacer().frame(height: 12)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if chatManager.messages.isEmpty {
                            Group {
                                MessageBubble(message: ChatMessage(id: UUID(), content: "Hi, I’m Nura. Your personal skin concierge. I’m here to help you with all things skin—routine, products, and confidence. What’s on your mind today?", isUser: false, timestamp: Date()))
                                    .padding(.top, 36)
                                MessageBubble(message: ChatMessage(id: UUID(), content: "Hi Nura! What’s the best way to keep my skin hydrated during winter?", isUser: true, timestamp: Date()))
                                MessageBubble(message: ChatMessage(id: UUID(), content: "Great question! In winter, use a gentle cleanser, layer a hydrating serum with hyaluronic acid, and seal it in with a rich moisturizer. Want product suggestions?", isUser: false, timestamp: Date()))
                                MessageBubble(message: ChatMessage(id: UUID(), content: "Yes, please! My skin gets dry and flaky.", isUser: true, timestamp: Date()))
                                MessageBubble(message: ChatMessage(id: UUID(), content: "Try a fragrance-free moisturizer with ceramides, like CeraVe or Vanicream. And don’t forget SPF, even on cloudy days!", isUser: false, timestamp: Date()))
                            }
                        } else {
                            ForEach(chatManager.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                                if let results = message.productResults, !results.isEmpty {
                                    ProductCardList(products: results)
                                        .padding(.horizontal)
                                }
                            }
                        }
                        if chatManager.isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: NuraColors.primary))
                                    .scaleEffect(0.8)
                                Text("AI is thinking...")
                                    .font(.caption)
                                    .foregroundColor(NuraColors.textSecondary)
                            }
                            .padding()
                            .background(NuraColors.card.opacity(0.1))
                            .cornerRadius(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 10)
                }
                .onChange(of: chatManager.messages.count) { oldValue, newValue in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(chatManager.messages.last?.id, anchor: .bottom)
                    }
                }
            }
            // Error message
            if let errorMessage = chatManager.errorMessage {
                Text(errorMessage)
                    .foregroundColor(NuraColors.error)
                    .font(.caption)
                    .padding(.horizontal)
            }
            // Last analyzed chip
            if let last = chatManager.memory.lastAnalysisDate {
                HStack {
                    Text("Last analyzed on \(formatDateTime(last))")
                        .font(.caption)
                        .foregroundColor(NuraColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            appearanceManager.isDarkMode ? NuraColors.cardDark : NuraColors.card
                        )
                        .cornerRadius(14)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("Type your skin wish... 🪄", text: $messageText, axis: .vertical)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 20)
                        .background(isDark ? NuraColors.cardDark : Color(red: 0.976, green: 0.965, blue: 0.949))
                        .cornerRadius(24)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...4)
                        .submitLabel(.send)
                        .onSubmit { sendMessage() }
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? (isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary) : (isDark ? NuraColors.primaryDark : NuraColors.primary))
                            .cornerRadius(20)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatManager.isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(isDark ? NuraColors.cardDark : NuraColors.card)
        }
        .overlay { freeTierPaywall }
    }
    
    private var freeTierPaywall: some View {
        VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark) {
            GeometryReader { geo in
                VStack {
                    Spacer()
                    VStack(spacing: 24) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(NuraColors.primary)
                            .padding(.bottom, 8)
                        Text("Unlock Nura AI Chat ✨")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        VStack(alignment: .center, spacing: 12) {
                            HStack(alignment: .top, spacing: 8) {
                                Text("📸")
                                Text("Personalized advice from your selfies")
                                    .foregroundColor(.white)
                                    .font(.body)
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("🌦️")
                                Text("Tips tailored to your local weather & skin type")
                                    .foregroundColor(.white)
                                    .font(.body)
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("🤖")
                                Text("24/7 expert answers, curated for you")
                                    .foregroundColor(.white)
                                    .font(.body)
                            }
                            HStack(alignment: .top, spacing: 8) {
                                Text("💎")
                                Text("Feel confident in your skin, every day")
                                    .foregroundColor(.white)
                                    .font(.body)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, 12)
                        Text("Upgrade to Nura Premium to unlock your personal AI skin coach. Your best skin is just a tap away.")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.976, green: 0.965, blue: 0.949))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                        HStack(spacing: 16) {
                            Button(action: { showNuraProSheet = true }) {
                                Text("Unlock Premium")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 40)
                                    .background(NuraColors.primary)
                                    .cornerRadius(24)
                                    .shadow(color: NuraColors.primary.opacity(0.18), radius: 8, x: 0, y: 2)
                            }
                        }
                        .padding(.top, 24)
                    }
                    .frame(maxWidth: 420)
                    .padding(.horizontal, 24)
                    Spacer()
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .transition(.opacity)
        .sheet(isPresented: $showNuraProSheet) {
            NuraProView()
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        chatManager.sendMessage(trimmedMessage)
        messageText = ""
        isTextFieldFocused = false
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Premium: Recommended Products

// MARK: - Product Recommendations by Routine Step
struct RoutineStepProducts: Identifiable {
    let id: UUID
    let step: SkincareStep
    let products: [ProductSearchResult]
    
    init(step: SkincareStep, products: [ProductSearchResult] = []) {
        self.id = step.id
        self.step = step
        self.products = products
    }
}

private struct RecommendedProductsView: View {
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var routineOverrideManager: RoutineOverrideManager
    
    @State private var isLoading: Bool = false
    @State private var showChatSheet: Bool = false
    @State private var morningStepProducts: [RoutineStepProducts] = []
    @State private var eveningStepProducts: [RoutineStepProducts] = []
    @State private var weeklyStepProducts: [RoutineStepProducts] = []
    
    var body: some View {
        let isDark = appearanceManager.isDarkMode
        return ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(spacing: 18) {
                    // Header
                    VStack(spacing: 6) {
                        Text("Product Recommendations")
                            .font(.largeTitle).fontWeight(.bold)
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                            .padding(.top, 8)
                        Text("Based on your latest skin analysis")
                            .font(.caption)
                            .foregroundColor(isDark ? NuraColors.textSecondaryDark : .secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Empty state if no analysis yet
                    if skinAnalysisManager.getCachedAnalysisResults() == nil {
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill((isDark ? Color.purple.opacity(0.12) : Color.purple.opacity(0.08)))
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.purple.opacity(0.25), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.35), Color.blue.opacity(0.25)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 64, height: 64)
                                    Image(systemName: "person.crop.circle.fill")
                                        .font(.system(size: 46))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 120)
                            .padding(.horizontal, 24)
                            
                            Text("No analysis yet")
                                .font(.title3).fontWeight(.semibold)
                                .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                            Text("Analyze your skin to unlock personalized product picks.")
                                .font(.caption)
                                .foregroundColor(isDark ? NuraColors.textSecondaryDark : .secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) { Image(systemName: "sparkles").foregroundColor(.yellow); Text("Personalized product matches").font(.caption).foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary) }
                                HStack(spacing: 8) { Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(.green); Text("Track improvements over time").font(.caption).foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary) }
                                HStack(spacing: 8) { Image(systemName: "wand.and.stars").foregroundColor(.purple); Text("Build a routine in one tap").font(.caption).foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary) }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(isDark ? NuraColors.cardDark : Color(.systemBackground))
                            .cornerRadius(14)
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                            
                            Button(action: { NotificationCenter.default.post(name: .nuraSwitchTab, object: 1) }) {
                                Text("Analyze Now")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 22)
                                    .padding(.vertical, 12)
                                    .background(LinearGradient(gradient: Gradient(colors: [NuraColors.primary, .purple]), startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(24)
                                    .shadow(color: NuraColors.primary.opacity(0.25), radius: 10, x: 0, y: 6)
                            }
                        }
                        .padding(.top, 12)
                        .padding()
                        .background(isDark ? NuraColors.cardDark : Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                        .padding(.horizontal)
                    } else {
                        if let last = skinAnalysisManager.getCachedAnalysisResults()?.analysisDate {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill").foregroundColor(.blue)
                                Text("Analyzed on \(formatDate(last)) • Confidence \(Int((skinAnalysisManager.getCachedAnalysisResults()?.confidence ?? 0.85) * 100))%")
                                    .font(.caption)
                                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : .secondary)
                                Spacer()
                                Button(action: refreshRecommendations) {
                                    HStack(spacing: 6) {
                                        if isLoading {
                                            let remaining = max(0, Int((skinAnalysisManager.reloadCountdownTime)))
                                            if remaining > 0 {
                                                Image(systemName: "arrow.clockwise.circle.fill")
                                                Text("Refreshing (\(remaining)s)")
                                            } else {
                                                ProgressView()
                                                    .scaleEffect(0.7)
                                                Text("Refreshing")
                                            }
                                        } else {
                                            Image(systemName: "arrow.clockwise")
                                            Text("Refresh")
                                        }
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(isDark ? Color.blue.opacity(0.12) : Color.blue.opacity(0.08))
                                    .cornerRadius(10)
                                }
                                .disabled(isLoading || !userTierManager.canPerformAnalysis())
                            }
                            .padding(.horizontal)

                        }
                        
                        CategorySection(title: "Morning Routine", icon: "sun.max.fill", stepProducts: morningStepProducts, reasonBuilder: reason, recommendationText: getRecommendationText(), onTriggerLoading: {
                            Task { @MainActor in
                                await load()
                            }
                        })
                        .environmentObject(appearanceManager)
                        .environmentObject(userTierManager)
                        .environmentObject(routineOverrideManager)
                        CategorySection(title: "Evening Routine", icon: "moon.stars.fill", stepProducts: eveningStepProducts, reasonBuilder: reason, recommendationText: getRecommendationText(), onTriggerLoading: {
                            Task { @MainActor in
                                await load()
                            }
                        })
                        .environmentObject(appearanceManager)
                        .environmentObject(userTierManager)
                        .environmentObject(routineOverrideManager)
                        CategorySection(title: "Weekly Treatments", icon: "calendar", stepProducts: weeklyStepProducts, reasonBuilder: reason, recommendationText: getRecommendationText(), onTriggerLoading: {
                            Task { @MainActor in
                                await load()
                            }
                        })
                        .environmentObject(appearanceManager)
                        .environmentObject(userTierManager)
                        .environmentObject(routineOverrideManager)
                    }
                }
                .padding()
            }
            // Bubble now handled at parent ChatView for persistence across navigation
        }
        // Removed onAppear trigger - product loading now happens after skin analysis
        .onReceive(skinAnalysisManager.$recommendations) { recommendations in
            // Only trigger product search if we have actual recommendations AND it's an explicit refresh
            // This prevents premature API calls when loading cached recommendations
            if recommendations != nil && !recommendations!.morningRoutine.isEmpty && skinAnalysisManager.isExplicitRefresh {
                load()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .nuraTriggerProductLoading)) { _ in
            // Trigger product loading when skin analysis is complete
            print("🚀 ChatView: Received product loading trigger from skin analysis")
            load()
        }
        .background(isDark ? NuraColors.backgroundDark : Color(red: 0.98, green: 0.97, blue: 0.95))
    }
    
    private func isGeneric(_ name: String) -> Bool {
        let l = name.lowercased()
        let brands = ["cerave","la roche","la roche-posay","supergoop","the ordinary","paula's choice","neutrogena","eucerin","tatcha","bioderma","vichy","olay","avene","cosrx","drunk elephant","zo"]
        let containsBrand = brands.contains { l.contains($0) }
        return !containsBrand
    }
    
    private func isArticleLike(_ name: String) -> Bool {
        let l = name.lowercased()
        let banned = ["skincare products:","ingredients","must-have","guide","best ","top ","how to","what is","explained"]
        return banned.contains { l.contains($0) }
    }
    
    private func ensureAmazonURL(for title: String, dest: String?) -> String? {
        if let d = dest, let host = URL(string: d)?.host, host.contains("amazon.") { return d }
        return ProductSearchManager.amazonSearchURL(for: title)?.absoluteString
    }
    
    private func verifiedOnly(_ products: [ProductSearchResult]) -> [ProductSearchResult] {
        products.compactMap { p in
            guard !isArticleLike(p.name) else { return nil }
            guard let brand = p.brand?.trimmingCharacters(in: .whitespacesAndNewlines), !brand.isEmpty else { return nil }
            let hasBrandInName = p.name.lowercased().contains(brand.lowercased())
            guard hasBrandInName, p.name.split(separator: " ").count >= 3 else { return nil }
            
            // Store original URL BEFORE it gets overridden
            let originalURL = p.destinationURL
            let fixedDest = ensureAmazonURL(for: p.name, dest: p.destinationURL)
            
            // Store original URL in benefits array for the new button (temporary solution)
            var updatedBenefits = p.benefits
            if let originalURL = originalURL, 
               let originalHost = URL(string: originalURL)?.host?.lowercased(),
               !originalHost.contains("amazon") {
                updatedBenefits.append("ORIGINAL_URL:\(originalURL)")
            }
            return ProductSearchResult(id: p.id, name: p.name, brand: p.brand, priceText: p.priceText, benefits: updatedBenefits, imageURL: p.imageURL, destinationURL: fixedDest, ingredients: p.ingredients, productType: p.productType, description: p.description)
        }
    }
    
    private func load() {
        print("🚀 [load] Starting product loading process")
        Task { @MainActor in
            isLoading = true
            defer { 
                isLoading = false
                print("✅ [load] Product loading process completed")
            }
            guard let recs = skinAnalysisManager.recommendations else { 
                print("❌ [load] No recommendations available")
                return 
            }
            let pm = ProductSearchManager.shared
            
            print("🔄 [load] Loading morning routine products...")
            // Load products for each routine step individually
            morningStepProducts = await loadProductsForSteps(recs.morningRoutine, productManager: pm)
            print("🔄 [load] Morning products loaded: \(morningStepProducts.map { $0.products.count })")
            
            print("🔄 [load] Loading evening routine products...")
            eveningStepProducts = await loadProductsForSteps(recs.eveningRoutine, productManager: pm)
            print("🔄 [load] Evening products loaded: \(eveningStepProducts.map { $0.products.count })")
            
            print("🔄 [load] Loading weekly treatment products...")
            weeklyStepProducts = await loadProductsForSteps(recs.weeklyTreatments, productManager: pm)
            print("🔄 [load] Weekly products loaded: \(weeklyStepProducts.map { $0.products.count })")
        }
    }
    
    private func loadWithoutProductSearch() {
        // Load routine steps without triggering product search API calls
        // This is used for initial display without hitting Google API limits
        guard let recs = skinAnalysisManager.recommendations else { return }
        
        morningStepProducts = recs.morningRoutine.map { RoutineStepProducts(step: $0, products: []) }
        eveningStepProducts = recs.eveningRoutine.map { RoutineStepProducts(step: $0, products: []) }
        weeklyStepProducts = recs.weeklyTreatments.map { RoutineStepProducts(step: $0, products: []) }
    }
    
    private func loadProductsIfNeeded() {
        print("🔄 [loadProductsIfNeeded] Starting product loading check")
        
        // Load routine steps first
        loadWithoutProductSearch()
        
        // If we have recommendations but no products loaded yet, trigger product loading
        guard let recs = skinAnalysisManager.recommendations else { 
            print("❌ [loadProductsIfNeeded] No recommendations available")
            return 
        }
        
        // Check if any step has products loaded
        let hasProducts = morningStepProducts.contains { !$0.products.isEmpty } ||
                         eveningStepProducts.contains { !$0.products.isEmpty } ||
                         weeklyStepProducts.contains { !$0.products.isEmpty }
        
        print("🔍 [loadProductsIfNeeded] Has products: \(hasProducts)")
        print("🔍 [loadProductsIfNeeded] Morning routine count: \(recs.morningRoutine.count)")
        print("🔍 [loadProductsIfNeeded] Morning step products count: \(morningStepProducts.map { $0.products.count })")
        
        // If no products are loaded and we have recommendations, load them immediately
        if !hasProducts && !recs.morningRoutine.isEmpty {
            print("🚀 [loadProductsIfNeeded] Triggering product loading...")
            Task { @MainActor in
                isLoading = true
                await load()
                isLoading = false
                print("✅ [loadProductsIfNeeded] Product loading completed")
            }
        } else {
            print("⏭️ [loadProductsIfNeeded] Skipping product loading - hasProducts: \(hasProducts), morningRoutine: \(!recs.morningRoutine.isEmpty)")
        }
    }
    
    
    private func loadProductsForSteps(_ steps: [SkincareStep], productManager: ProductSearchManager) async -> [RoutineStepProducts] {
        var stepProducts: [RoutineStepProducts] = []
        
        for step in steps {
            // Search for products specific to this step
            let products = await searchProductsForStep(step, productManager: productManager)
            let verifiedProducts = verifiedOnly(products)
            let limitedProducts = Array(verifiedProducts.prefix(3)) // Limit to 3 products per step
            
            stepProducts.append(RoutineStepProducts(step: step, products: limitedProducts))
        }
        
        return stepProducts
    }
    
    private func searchProductsForStep(_ step: SkincareStep, productManager: ProductSearchManager) async -> [ProductSearchResult] {
        var allProducts: [ProductSearchResult] = []
        var searchedQueries: Set<String> = [] // Track queries to prevent duplicates
        
        // Search by step name if it's a specific product
        if !isGeneric(step.name) {
            let normalizedStepName = step.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if searchedQueries.insert(normalizedStepName).inserted {
                let explicitProducts = await productManager.searchProducts(forNames: [step.name])
                allProducts.append(contentsOf: explicitProducts)
            }
        }
        
        // Search by category and step name (only if different from step name)
        let categoryQueryText = "\(step.name) \(step.category.rawValue)"
        let normalizedCategoryQuery = categoryQueryText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if searchedQueries.insert(normalizedCategoryQuery).inserted {
            let categoryQuery = ProductSearchManager.ProductQuery(
                rawText: categoryQueryText,
                normalizedQuery: categoryQueryText,
                categoryHint: step.category.rawValue
            )
            let categoryProducts = await productManager.searchProducts(query: categoryQuery)
            allProducts.append(contentsOf: categoryProducts)
        }
        
        // Search by category-specific keywords (only unique ones)
        let categoryKeywords = getKeywordsForCategory(step.category)
        for keyword in categoryKeywords {
            let normalizedKeyword = keyword.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if searchedQueries.insert(normalizedKeyword).inserted {
                let keywordQuery = ProductSearchManager.ProductQuery(
                    rawText: keyword,
                    normalizedQuery: keyword,
                    categoryHint: step.category.rawValue
                )
                let keywordProducts = await productManager.searchProducts(query: keywordQuery)
                allProducts.append(contentsOf: keywordProducts)
            }
        }
        
        // Deduplicate results by product name and brand to ensure variety
        return deduplicateProductsByNameAndBrand(allProducts)
    }
    
    private func deduplicateProductsByNameAndBrand(_ products: [ProductSearchResult]) -> [ProductSearchResult] {
        var seen: Set<String> = []
        var deduped: [ProductSearchResult] = []
        
        for product in products {
            // Create a unique key from normalized name and brand
            let normalizedName = product.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let normalizedBrand = (product.brand ?? "").lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let key = "\(normalizedName)|\(normalizedBrand)"
            
            if seen.insert(key).inserted {
                deduped.append(product)
            }
        }
        
        return deduped
    }
    
    private func getKeywordsForCategory(_ category: SkincareStep.StepCategory) -> [String] {
        switch category {
        case .cleanser:
            return ["gentle cleanser", "foaming cleanser", "gel cleanser", "cream cleanser"]
        case .serum:
            return ["vitamin c serum", "niacinamide serum", "hyaluronic acid serum", "retinol serum"]
        case .moisturizer:
            return ["moisturizer", "cream", "lotion", "hydrating cream"]
        case .sunscreen:
            return ["sunscreen", "spf", "mineral sunscreen", "chemical sunscreen"]
        case .treatment:
            return ["treatment", "acne treatment", "spot treatment"]
        case .toner:
            return ["toner", "essence", "facial mist"]
        case .mask:
            return ["face mask", "clay mask", "sheet mask"]
        case .exfoliant, .aha, .bha:
            return ["exfoliant", "peel", "scrub", "chemical exfoliant"]
        case .clay:
            return ["clay mask", "bentonite clay", "kaolin clay"]
        }
    }
    
    private func refreshRecommendations() {
        Task { @MainActor in
            isLoading = true
            await skinAnalysisManager.regenerateRecommendations()
            // Reset loading state after recommendations are regenerated
            isLoading = false
            // The load() will be triggered automatically by the onReceive listener
            // since regenerateRecommendations() sets isExplicitRefresh = true
        }
    }
    
    private func reason(for product: ProductSearchResult) -> String {
        print("🔄 [reason] Generating reason for product: \(product.name)")
        let conditions = skinAnalysisManager.getCachedAnalysisResults()?.conditions.map { $0.name }.prefix(2).joined(separator: ", ") ?? "your skin profile"
        let reasonText = "Recommended for \(conditions)."
        print("🔄 [reason] Generated reason: \(reasonText)")
        return reasonText
    }
    
    private func getRecommendationText() -> String? {
        guard let conditions = skinAnalysisManager.getCachedAnalysisResults()?.conditions.map({ $0.name }).joined(separator: ", "), !conditions.isEmpty else {
            return nil
        }
        return "Recommended for \(conditions)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date)
    }
}

private struct CategorySection: View {
    let title: String
    let icon: String
    let stepProducts: [RoutineStepProducts]
    let reasonBuilder: (ProductSearchResult) -> String
    let recommendationText: String?
    let onTriggerLoading: () -> Void
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager
    @EnvironmentObject var routineOverrideManager: RoutineOverrideManager
    
    var body: some View {
        let isDark = appearanceManager.isDarkMode
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon).foregroundColor(.orange)
                Text(title).font(.title2).fontWeight(.bold)
                    .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                Spacer()
            }
            
            // Show recommendation text under the section header
            if let recommendationText = recommendationText, !recommendationText.isEmpty {
                Text(recommendationText)
                    .font(.caption2)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : .secondary)
                    .padding(.horizontal, 4)
            }
            
            if stepProducts.isEmpty {
                Text("No recommendations yet. Try refreshing.")
                    .font(.caption)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : .secondary)
            } else {
                // Display rows for each routine step (vertical layout)
                VStack(spacing: 16) {
                    ForEach(stepProducts) { stepProduct in
                        RoutineStepRow(
                            stepProduct: stepProduct,
                            reasonBuilder: reasonBuilder,
                            onTriggerLoading: onTriggerLoading
                        )
                        .environmentObject(appearanceManager)
                        .environmentObject(userTierManager)
                        .environmentObject(routineOverrideManager)
                    }
                }
            }
        }
        .padding()
        .background(isDark ? NuraColors.cardDark : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

private struct RoutineStepRow: View {
    let stepProduct: RoutineStepProducts
    let reasonBuilder: (ProductSearchResult) -> String
    let onTriggerLoading: () -> Void
    @State private var currentProductIndex: Int = 0
    @State private var isDragging: Bool = false
    @State private var showProductDetail: Bool = false
    @State private var selectedProduct: ProductSearchResult? = nil
    @State private var isLoadingProducts: Bool = false
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var skinAnalysisManager: SkinAnalysisManager
    @EnvironmentObject var userTierManager: UserTierManager
    @EnvironmentObject var routineOverrideManager: RoutineOverrideManager
    
    // MARK: - Computed Properties
    
    private var stepNameColor: Color {
        let isDark = appearanceManager.isDarkMode
        return isDark ? NuraColors.textPrimaryDark : .primary
    }
    
    private var noProductsTextColor: Color {
        let isDark = appearanceManager.isDarkMode
        return isDark ? NuraColors.textSecondaryDark : .secondary
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 25)
            .onChanged { value in
                // Only set dragging if the user has moved significantly
                if abs(value.translation.width) > 15 || abs(value.translation.height) > 15 {
                    isDragging = true
                }
            }
            .onEnded { value in
                // Only set dragging flag if there was significant movement
                let significantMovement = abs(value.translation.width) > 15 || abs(value.translation.height) > 15
                if significantMovement {
                    // Shorter delay for better responsiveness
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isDragging = false
                    }
                } else {
                    // Reset immediately for taps
                    isDragging = false
                }
            }
    }
    
    var body: some View {
        return HStack(alignment: .top, spacing: 16) {
            // Left side: Step information (centered vertically and horizontally)
            VStack {
                Text(stepProduct.step.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(stepNameColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 120, height: 120, alignment: .center)
            
            // Right side: Swipable product cards
            if stepProduct.products.isEmpty {
                if isLoadingProducts {
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading products...")
                            .font(.caption)
                            .foregroundColor(noProductsTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 100)
                } else {
                    Text("No products found")
                        .font(.caption)
                        .foregroundColor(noProductsTextColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .frame(height: 100)
                }
            } else {
                VStack(spacing: 8) {
                    // Swipable product cards
                    TabView(selection: $currentProductIndex) {
                        ForEach(Array(stepProduct.products.enumerated()), id: \.offset) { index, product in
                            VStack(alignment: .leading, spacing: 6) {
                                Button(action: {
                                    // Only navigate if not dragging (to prevent swipe conflicts)
                                    if !isDragging {
                                        print("🖱️ [Product Click] User clicked product: '\(product.name)'")
                                        print("🖱️ [Product Click] Product imageURL: '\(product.imageURL ?? "nil")'")
                                        print("🖱️ [Product Click] Is dragging: \(isDragging)")
                                        
                                        Task {
                                            // Ensure products are loaded before showing detail view
                                            print("🔄 [Product Click] Calling ensureProductsLoaded...")
                                            let productsLoaded = await ensureProductsLoaded()
                                            print("🔄 [Product Click] ensureProductsLoaded result: \(productsLoaded)")
                                            
                                            await MainActor.run {
                                                if productsLoaded && !product.name.isEmpty {
                                                    print("✅ [Product Click] Products loaded, showing detail view")
                                                    selectedProduct = product
                                                    showProductDetail = true
                                                } else {
                                                    print("❌ [Product Click] Products not loaded, triggering loading and retrying...")
                                                    // Show loading state and trigger loading
                                                    isLoadingProducts = true
                                                    
                                                    // Wait a bit for loading to complete, then retry
                                                    Task {
                                                        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                                                        await MainActor.run {
                                                            isLoadingProducts = false
                                                            // Check if the product is now available
                                                            if !product.name.isEmpty && product.imageURL != nil && !product.imageURL!.isEmpty {
                                                                print("✅ [Product Click] Retry successful, showing detail view")
                                                                selectedProduct = product
                                                                showProductDetail = true
                                                            } else {
                                                                print("❌ [Product Click] Retry failed, product still incomplete")
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }) {
                                    CompactProductCard(product: product)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .simultaneousGesture(dragGesture)
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 120)
                    
                    // Page indicator dots
                    if stepProduct.products.count > 1 {
                        HStack(spacing: 4) {
                            ForEach(0..<stepProduct.products.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentProductIndex ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $showProductDetail) {
            // Log sheet presentation details
            let _ = {
                print("🔄 [Sheet] Sheet is being presented")
                print("🔄 [Sheet] selectedProduct: \(selectedProduct?.name ?? "nil")")
                print("🔄 [Sheet] showProductDetail: \(showProductDetail)")
            }()
            
            if let product = selectedProduct, !product.name.isEmpty {
                // Log successful product detail view presentation
                let _ = {
                    print("✅ [Sheet] Showing ProductDetailView for: \(product.name)")
                }()
                
                ProductDetailView(product: product, reason: reasonBuilder(product))
                    .environmentObject(appearanceManager)
                    .environmentObject(userTierManager)
                    .environmentObject(routineOverrideManager)
            } else {
                // Log loading state presentation
                let _ = {
                    print("❌ [Sheet] Showing loading state - product: \(selectedProduct?.name ?? "nil")")
                }()
                
                // Show loading state if product data is incomplete
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading product details...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("If this hasn't loaded in 5 seconds, please swipe out of the page and retry clicking the product again.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func ensureProductsLoaded() async -> Bool {
        print("🔍 [ensureProductsLoaded] Starting validation for step: \(stepProduct.step.name)")
        print("🔍 [ensureProductsLoaded] Products count: \(stepProduct.products.count)")
        
        // Check if products exist and have complete data
        guard !stepProduct.products.isEmpty else {
            print("❌ [ensureProductsLoaded] No products found for step: \(stepProduct.step.name)")
            // Try to trigger product loading for this specific step
            await triggerProductLoadingForStep()
            return false
        }
        
        // Log each product's data completeness
        for (index, product) in stepProduct.products.enumerated() {
            print("🔍 [ensureProductsLoaded] Product \(index): name='\(product.name)', imageURL='\(product.imageURL ?? "nil")'")
        }
        
        // Validate that products have complete data (name, imageURL, etc.)
        let hasCompleteProducts = stepProduct.products.allSatisfy { product in
            let isValid = !product.name.isEmpty && 
                         product.imageURL != nil && 
                         !product.imageURL!.isEmpty
            print("🔍 [ensureProductsLoaded] Product '\(product.name)' validity: \(isValid)")
            return isValid
        }
        
        if !hasCompleteProducts {
            print("⚠️ [ensureProductsLoaded] Products incomplete, triggering loading...")
            await triggerProductLoadingForStep()
        }
        
        print("✅ [ensureProductsLoaded] All products complete: \(hasCompleteProducts)")
        return hasCompleteProducts
    }
    
    private func triggerProductLoadingForStep() async {
        print("🚀 [triggerProductLoadingForStep] Triggering loading for step: \(stepProduct.step.name)")
        
        // Use the callback to trigger loading in the parent view
        await MainActor.run {
            print("🔄 [triggerProductLoadingForStep] Calling parent loading callback...")
            onTriggerLoading()
        }
    }
}

private struct CompactProductCard: View {
    let product: ProductSearchResult
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        let isDark = appearanceManager.isDarkMode
        VStack(alignment: .leading, spacing: 6) {
            // Product image
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDark ? NuraColors.cardDark : Color(.secondarySystemBackground))
                    .frame(height: 60)
                
                if let urlStr = product.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .font(.caption)
                                .foregroundColor(isDark ? NuraColors.textSecondaryDark : .secondary)
                        case .empty:
                            ProgressView()
                                .scaleEffect(0.7)
                        @unknown default:
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .font(.caption)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : .secondary)
                }
            }
            
            // Product name
            Text(product.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Price only (removed brand/company name)
            if let price = product.priceText {
                Text(price)
                    .font(.caption2)
                    .foregroundColor(isDark ? NuraColors.textSecondaryDark : .secondary)
            }
        }
        .padding(8)
        .background(isDark ? NuraColors.cardDark : Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

private struct ProductDetailView: View {
    let product: ProductSearchResult
    let reason: String
    @EnvironmentObject var appearanceManager: AppearanceManager
    @EnvironmentObject var userTierManager: UserTierManager
    @EnvironmentObject var routineOverrideManager: RoutineOverrideManager
    
    var body: some View {
        let isDark = appearanceManager.isDarkMode
        
        // Log product details
        let _ = {
            print("🔄 [ProductDetailView] Creating ProductDetailView for: \(product.name)")
            print("🔄 [ProductDetailView] Product imageURL: \(product.imageURL ?? "nil")")
            print("🔄 [ProductDetailView] Reason: \(reason)")
        }()
        
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ZStack {
                    LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.15), Color.blue.opacity(0.10)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(height: 220)
                        .cornerRadius(18)
                    if let urlStr = product.imageURL, let url = URL(string: urlStr.replacingOccurrences(of: "_thumbnail", with: "")) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image): image.resizable().scaledToFit()
                            case .failure: Image(systemName: "photo").resizable().scaledToFit().foregroundColor(.secondary)
                            case .empty: ProgressView()
                            @unknown default: ProgressView()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                    }
                }
                Text(product.name).font(.title2).fontWeight(.bold)
                if let brand = product.brand { Text("Company: \(brand)").foregroundColor(.secondary) }
                
                // Product description
                if let description = product.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundColor(isDark ? NuraColors.textPrimaryDark : .primary)
                        .padding(.vertical, 8)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Why this fits you").font(.headline)
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(reasonBulletPoints(from: reason), id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 8) { Image(systemName: "checkmark.seal.fill").foregroundColor(.green); Text(bullet).font(.subheadline).foregroundColor(.secondary) }
                        }
                        if let ings = product.ingredients, !ings.isEmpty {
                            let trimmed = ings.prefix(6).joined(separator: ", ")
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "leaf.fill").foregroundColor(.green)
                                Text("Key ingredients: \(trimmed)").font(.subheadline).foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background((isDark ? NuraColors.cardDark : Color(.systemBackground)).opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15), lineWidth: 1))
                .cornerRadius(12)
                
                // Button layout: Shop button on top (matching width of bottom buttons), Save and Amazon below
                VStack(spacing: 12) {
                    // Save to Routine and Amazon buttons (invisible, used for width calculation)
                    HStack(spacing: 16) {
                        // Save to Routine button (invisible, for width reference)
                        HStack(spacing: 8) { Image(systemName: "plus.circle.fill"); Text("Save to Routine").fontWeight(.semibold) }
                            .foregroundColor(.clear)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.clear)
                            .cornerRadius(24)
                        
                        // Amazon button (invisible, for width reference)
                        HStack(spacing: 8) { Image(systemName: "cart.fill"); Text("Amazon").fontWeight(.semibold) }
                            .foregroundColor(.clear)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Color.clear)
                            .cornerRadius(24)
                    }
                    .opacity(0) // Make invisible
                    .overlay(
                        // Shop on original retailer button (matching width of invisible buttons)
                        Group {
                            if let originalURL = getOriginalRetailerURL(for: product), let url = URL(string: originalURL) {
                                Link(destination: url) {
                                    HStack(spacing: 8) { 
                                        Image(systemName: "bag.fill")
                                        Text("Shop on \(getRetailerName(from: originalURL))").fontWeight(.semibold) 
                                    }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                        .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                                        .cornerRadius(24)
                                        .shadow(color: Color.blue.opacity(0.25), radius: 8, x: 0, y: 4)
                                }
                            } else {
                                // Debug: Show a placeholder to see if the condition is being evaluated (simulator only)
                                #if targetEnvironment(simulator)
                                Text("DEBUG: No original URL found")
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                #endif
                            }
                        }
                    )
                    
                    // Save to Routine and Amazon buttons below with spacing
                    HStack(spacing: 16) {
                        // Save to Routine button
                        Button(action: { routineOverrideManager.save(product: product, inferredFrom: product.name) }) {
                            HStack(spacing: 8) { Image(systemName: "plus.circle.fill"); Text("Save to Routine").fontWeight(.semibold) }
                                .foregroundColor(.white)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(LinearGradient(gradient: Gradient(colors: [NuraColors.primary, .purple]), startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(24)
                                .shadow(color: NuraColors.primary.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        
                        // Amazon button
                        if let dest = product.destinationURL, let url = URL(string: dest) {
                            Link(destination: url) {
                                HStack(spacing: 8) { Image(systemName: "cart.fill"); Text("Amazon").fontWeight(.semibold) }
                                    .foregroundColor(isDark ? .black : .white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]), startPoint: .leading, endPoint: .trailing))
                                    .cornerRadius(24)
                                    .shadow(color: Color.orange.opacity(0.25), radius: 8, x: 0, y: 4)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                
                // Feature ratings: centered vertical stack with separators
                VStack(spacing: 6) {
                    ForEach(Array(getProductFeatures(for: product).enumerated()), id: \.offset) { index, feature in
                        RatingRow(text: feature.text, systemIcon: feature.icon)
                        if index < getProductFeatures(for: product).count - 1 {
                            Divider().opacity(0.15)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.top, 2)

                // Removed bottom ingredients section (consolidated into Why this fits you)
            }
            .padding()
        }
        .navigationTitle("Product Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func reasonBulletPoints(from text: String) -> [String] {
        let lowered = text.replacingOccurrences(of: "Recommended for ", with: "")
        let parts = lowered.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        if parts.isEmpty { return [text] }
        return parts
    }
    
    private func getRetailerName(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host?.lowercased() else {
            return "Store"
        }
        
        // Extract retailer name from common domains
        if host.contains("amazon") {
            return "Amazon"
        } else if host.contains("target") {
            return "Target"
        } else if host.contains("sephora") {
            return "Sephora"
        } else if host.contains("ulta") {
            return "Ulta"
        } else if host.contains("walmart") {
            return "Walmart"
        } else if host.contains("cvs") {
            return "CVS"
        } else if host.contains("walgreens") {
            return "Walgreens"
        } else if host.contains("dermstore") {
            return "Dermstore"
        } else if host.contains("skinstore") {
            return "SkinStore"
        } else if host.contains("beautylish") {
            return "Beautylish"
        } else if host.contains("cultbeauty") {
            return "Cult Beauty"
        } else if host.contains("lookfantastic") {
            return "Lookfantastic"
        } else if host.contains("spacenk") {
            return "Space NK"
        } else if host.contains("boots") {
            return "Boots"
        } else if host.contains("superdrug") {
            return "Superdrug"
        } else if host.contains("asos") {
            return "ASOS"
        } else if host.contains("hollandandbarrett") {
            return "Holland & Barrett"
        } else if host.contains("feelunique") {
            return "Feelunique"
        } else {
            // For unknown domains, try to extract a meaningful name from the host
            let components = host.components(separatedBy: ".")
            if let firstComponent = components.first, firstComponent != "www" {
                return firstComponent.capitalized
            }
            return "Store"
        }
    }
    
    private func getOriginalRetailerURL(for product: ProductSearchResult) -> String? {
        // Extract original URL from benefits array where we stored it
        for benefit in product.benefits {
            if benefit.hasPrefix("ORIGINAL_URL:") {
                let originalURL = String(benefit.dropFirst("ORIGINAL_URL:".count))
                print("DEBUG: Found original URL: \(originalURL)")
                return originalURL
            }
        }
        print("DEBUG: No original URL found in benefits: \(product.benefits)")
        return nil
    }
    
    private func getProductFeatures(for product: ProductSearchResult) -> [(text: String, icon: String)] {
        var features: [(text: String, icon: String)] = []
        
        // Analyze product name and benefits for personalized features
        let productName = product.name.lowercased()
        let benefits = product.benefits.map { $0.lowercased() }
        let productType = product.productType?.lowercased() ?? ""
        
        // Derm-friendly: Check for dermatologist-recommended brands or gentle ingredients
        let dermFriendlyBrands = ["cerave", "la roche-posay", "eucerin", "avene", "bioderma", "vichy", "neutrogena", "zo skin health"]
        let gentleIngredients = ["ceramide", "hyaluronic", "niacinamide", "gentle", "sensitive", "fragrance-free"]
        
        if dermFriendlyBrands.contains(where: { productName.contains($0) }) ||
           gentleIngredients.contains(where: { productName.contains($0) || benefits.contains(where: { $0.contains($0) }) }) {
            features.append((text: "Derm-friendly", icon: "hand.raised.fill"))
        }
        
        // Popular: Check for well-known brands or high ratings
        let popularBrands = ["the ordinary", "paula's choice", "drunk elephant", "tatcha", "supergoop", "olay", "zo skin health"]
        if popularBrands.contains(where: { productName.contains($0) }) {
            features.append((text: "Popular", icon: "star.fill"))
        }
        
        // Fast shipping: Check for Amazon availability or express delivery indicators
        if product.destinationURL?.contains("amazon") == true {
            features.append((text: "Fast shipping", icon: "bolt.fill"))
        }
        
        // SPF protection: ONLY for sunscreen products or products explicitly containing SPF
        // Be very strict - only show SPF protection for actual sunscreens
        let sunscreenKeywords = ["spf", "sunscreen", "sun screen", "uv protection", "broad spectrum"]
        let isSunscreen = productType == "sunscreen" || 
                         sunscreenKeywords.contains(where: { productName.contains($0) }) ||
                         benefits.contains(where: { benefit in sunscreenKeywords.contains(where: { benefit.contains($0) }) })
        
        if isSunscreen {
            features.append((text: "SPF protection", icon: "sun.max.fill"))
        }
        
        // Anti-aging: Check for retinol, vitamin C, or anti-aging ingredients
        let antiAgingIngredients = ["retinol", "vitamin c", "peptide", "niacinamide", "glycolic", "lactic"]
        if antiAgingIngredients.contains(where: { ingredient in productName.contains(ingredient) || benefits.contains(where: { benefit in benefit.contains(ingredient) }) }) {
            features.append((text: "Anti-aging", icon: "sparkles"))
        }
        
        // Hydrating: Check for hydrating ingredients
        let hydratingIngredients = ["hyaluronic", "glycerin", "ceramide", "moisturizing", "hydrating"]
        if hydratingIngredients.contains(where: { ingredient in productName.contains(ingredient) || benefits.contains(where: { benefit in benefit.contains(ingredient) }) }) {
            features.append((text: "Hydrating", icon: "drop.fill"))
        }
        
        // Exfoliating: Check for exfoliating ingredients (for cleansers, treatments)
        let exfoliatingIngredients = ["salicylic", "glycolic", "lactic", "aha", "bha", "exfoliating"]
        if exfoliatingIngredients.contains(where: { ingredient in productName.contains(ingredient) || benefits.contains(where: { benefit in benefit.contains(ingredient) }) }) {
            features.append((text: "Exfoliating", icon: "sparkles"))
        }
        
        // Gentle: Check for gentle/soothing ingredients (for cleansers, sensitive skin)
        let gentleKeywords = ["gentle", "soothing", "calming", "sensitive", "mild"]
        if gentleKeywords.contains(where: { keyword in productName.contains(keyword) || benefits.contains(where: { benefit in benefit.contains(keyword) }) }) {
            features.append((text: "Gentle", icon: "leaf.fill"))
        }
        
        // If no specific features found, use default ones based on product type
        if features.isEmpty {
            if productType == "cleanser" {
                features = [
                    (text: "Derm-friendly", icon: "hand.raised.fill"),
                    (text: "Gentle", icon: "leaf.fill"),
                    (text: "Fast shipping", icon: "bolt.fill")
                ]
            } else if productType == "sunscreen" {
                features = [
                    (text: "SPF protection", icon: "sun.max.fill"),
                    (text: "Derm-friendly", icon: "hand.raised.fill"),
                    (text: "Fast shipping", icon: "bolt.fill")
                ]
            } else {
                features = [
                    (text: "Derm-friendly", icon: "hand.raised.fill"),
                    (text: "Popular", icon: "star.fill"),
                    (text: "Fast shipping", icon: "bolt.fill")
                ]
            }
        }
        
        // Limit to 3 features for clean UI
        return Array(features.prefix(3))
    }
}

// Simple flexible chips layout
private struct FlexibleChips: View {
    let chips: [(String, String, Color)]
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
            ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                HStack(spacing: 6) {
                    Image(systemName: chip.1)
                    Text(chip.0).font(.caption)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(chip.2)
                .cornerRadius(10)
            }
        }
    }
}

// Simple rating row used in vertical stack
private struct RatingRow: View {
    let text: String
    let systemIcon: String
    var body: some View {
        HStack(spacing: 8) {
            Spacer()
            Image(systemName: systemIcon)
            Text(text).font(.caption)
            Spacer()
        }
        .padding(.vertical, 6)
    }
}

private struct MiniChatSheet: View {
    @EnvironmentObject var chatManager: ChatManager
    @EnvironmentObject var appearanceManager: AppearanceManager
    @State private var text: String = ""
    @FocusState private var focused: Bool
    
    var body: some View {
        let isDark = appearanceManager.isDarkMode
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(chatManager.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .onChange(of: chatManager.messages.count) { oldValue, newValue in
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo(chatManager.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                Divider()
                HStack(spacing: 10) {
                    TextField("Ask about a product...", text: $text, axis: .vertical)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(isDark ? NuraColors.cardDark : Color(red: 0.976, green: 0.965, blue: 0.949))
                        .cornerRadius(20)
                        .focused($focused)
                        .lineLimit(1...4)
                        .submitLabel(.send)
                        .onSubmit { send() }
                    Button(action: send) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(8)
                            .background(isDark ? NuraColors.primaryDark : NuraColors.primary)
                            .cornerRadius(18)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Ask Nura")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            chatManager.resetChatAndMemory()
                        } label: {
                            Label("Reset Chat & Memory", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        chatManager.sendMessage(trimmed)
        text = ""
        focused = false
    }
}

// Existing MessageBubble, MarkdownText and helpers remain unchanged below

struct MessageBubble: View {
    let message: ChatMessage
    @EnvironmentObject var appearanceManager: AppearanceManager
    
    var body: some View {
        let isDark = appearanceManager.isDarkMode
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isDark ? NuraColors.cardDark : Color(red: 0.976, green: 0.965, blue: 0.949)) // #F9F6F2
                        .foregroundColor(isDark ? NuraColors.textPrimaryDark : .black)
                        .font(.callout)
                        .cornerRadius(20)
                        .cornerRadius(4, corners: [.topLeft, .topRight, .bottomLeft])
                        .contextMenu {
                            Button("Copy") { UIPasteboard.general.string = message.content }
                        }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(isDark ? NuraColors.primaryDark : NuraColors.primary)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        // 5. Make the AI response bubble use a blue iMessage color with light markdown rendering
                        MarkdownText(text: message.content)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(isDark ? NuraColors.primaryDark : Color(red: 0.29, green: 0.56, blue: 0.89))
                            .foregroundColor(isDark ? NuraColors.textPrimaryDark : .white)
                            .font(.callout)
                            .cornerRadius(20)
                            .cornerRadius(4, corners: [.topLeft, .topRight, .bottomRight])
                            .contextMenu {
                                Button("Copy") { UIPasteboard.general.string = message.content }
                            }
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(isDark ? NuraColors.textSecondaryDark : NuraColors.textSecondary)
                        .padding(.leading, 24)
                }
                
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Lightweight Markdown renderer: supports **bold** and bullet points only
struct MarkdownText: View {
    let text: String
    
    var body: some View {
        let attributed = MarkdownText.parse(text)
        Text(attributed)
    }
    
    static func parse(_ input: String) -> AttributedString {
        var working = input
        // Replace markdown bullets "- " with a dot prefix
        working = working.replacingOccurrences(of: "\n- ", with: "\n• ")
        
        var attributed = AttributedString(working)
        
        // Parse **bold** - find and replace all instances
        while let startRange = attributed.range(of: "**") {
            if let endRange = attributed[startRange.upperBound...].range(of: "**") {
                let boldRange = startRange.upperBound..<endRange.lowerBound
                attributed[boldRange].inlinePresentationIntent = .stronglyEmphasized
                
                // Remove the ** markers
                attributed.removeSubrange(endRange)
                attributed.removeSubrange(startRange)
            } else {
                break
            }
        }
        
        return attributed
    }
}

// Add VisualEffectBlur for blur overlay
import UIKit
struct VisualEffectBlur<Content: View>: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    var content: () -> Content
    class Coordinator {
        var hostingController: UIHostingController<Content>?
        init(hostingController: UIHostingController<Content>? = nil) {
            self.hostingController = hostingController
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        let hosting = UIHostingController(rootView: content())
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.contentView.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: view.contentView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.contentView.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: view.contentView.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.contentView.bottomAnchor)
        ])
        context.coordinator.hostingController = hosting
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        context.coordinator.hostingController?.rootView = content()
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatManager())
} 