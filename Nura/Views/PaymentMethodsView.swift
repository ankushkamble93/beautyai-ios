import SwiftUI
import PassKit
import Supabase

struct PaymentMethodsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var userTierManager: UserTierManager
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
    
    // Plan selection
    @State private var selectedPlan: SubscriptionPlan? = nil
    @State private var showCardEntry: Bool = false
    @State private var billingCycle: BillingCycle = .monthly
    
    // Current active plan (will be nil if user has no active subscription)
    @State private var currentActivePlan: SubscriptionPlan? = nil
    @State private var currentBillingCycle: BillingCycle = .monthly
    
    // Computed property to get current plan from UserTierManager (which reads from Supabase premium field)
    private var currentPlanFromTier: SubscriptionPlan? {
        guard userTierManager.tier != .free else { return nil }
        
        switch userTierManager.tier {
        case .pro:
            return SubscriptionPlan.allPlans.first { $0.name == "Nura Pro" }
        case .proUnlimited:
            return SubscriptionPlan.allPlans.first { $0.name == "Nura Pro Unlimited" }
        case .free:
            return nil
        }
    }
    @State private var nextBillingDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var showCancelAlert: Bool = false
    @State private var showPlanManagement: Bool = false
    @State private var isCancellingSubscription: Bool = false
    @State private var showCancellationSuccess: Bool = false
    
    // Date formatter for billing date
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    // Initial plan from navigation
    let initialPlan: SubscriptionPlan?
    let initialBillingCycle: BillingCycle?
    
    init(initialPlan: SubscriptionPlan? = nil, initialBillingCycle: BillingCycle? = nil) {
        self.initialPlan = initialPlan
        self.initialBillingCycle = initialBillingCycle
    }
    
    // Card input fields
    @State private var cardNumber: String = ""
    @State private var expiry: String = ""
    @State private var cvv: String = ""
    @State private var cardholder: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var zipcode: String = ""
    @State private var showBrand: Bool = false
    @State private var detectedBrand: CardBrand? = nil
    
    // Saved cards
    @State private var savedCards: [SavedCard] = [
        SavedCard(brand: .visa, last4: "4242", cardholder: "Jane Doe", expiry: "12/26", address: "123 Main St", city: "New York", country: "USA", zipcode: "10001"),
        SavedCard(brand: .mastercard, last4: "4444", cardholder: "Jane Doe", expiry: "09/25", address: "456 Elm St", city: "San Francisco", country: "USA", zipcode: "94102")
    ]
    @State private var expandedCardID: UUID? = nil
    @State private var showDeleteAlert: UUID? = nil
    @State private var isApplePayAvailable: Bool = false
    
    // Simple validation (replace with real API for production)
    func isValidCity(_ city: String) -> Bool { city.count > 1 }
    func isValidCountry(_ country: String) -> Bool { country.count > 1 }
    func isValidZip(_ zip: String) -> Bool { zip.count >= 4 && zip.count <= 10 }
    
    // Check Apple Pay availability
    private func checkApplePayAvailability() {
        isApplePayAvailable = PKPaymentAuthorizationController.canMakePayments()
    }
    
    // Handle Apple Pay payment
    private func handleApplePay() {
        guard let selectedPlan = selectedPlan else {
            print("Please select a plan first")
            return
        }
        
        // Check if Apple Pay is available before proceeding
        guard PKPaymentAuthorizationController.canMakePayments() else {
            print("Apple Pay is not available on this device")
            return
        }
        
        // Create payment request
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.nura.app" // Replace with your merchant ID
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.currencyCode = "USD"
        
        // Add payment item based on selected plan and billing cycle
        let price: Double = {
            if selectedPlan.price == 0.00 { return 0.00 }
            switch billingCycle {
            case .monthly:
                return selectedPlan.price
            case .yearly:
                switch selectedPlan.name {
                case "Nura Pro":
                    return 59.99
                case "Nura Pro Unlimited":
                    return 79.99
                default:
                    return selectedPlan.price
                }
            }
        }()
        
        let paymentItem = PKPaymentSummaryItem(label: selectedPlan.name, amount: NSDecimalNumber(value: price))
        let totalItem = PKPaymentSummaryItem(label: "Nura", amount: NSDecimalNumber(value: price))
        request.paymentSummaryItems = [paymentItem, totalItem]
        
        // Present payment controller
        let paymentController = PKPaymentAuthorizationController(paymentRequest: request)
        paymentController.delegate = PaymentHandler.shared
        
        paymentController.present { presented in
            if presented {
                print("Apple Pay presented successfully")
            } else {
                print("Failed to present Apple Pay")
            }
        }
    }
    
    // Handle manual card payment
    private func handleManualCardPayment() {
        guard let selectedPlan = selectedPlan else {
            print("Please select a plan first")
            return
        }
        
        // Validate card details here
        let price = getPlanPrice(for: selectedPlan, cycle: billingCycle)
        print("Processing manual card payment for \(selectedPlan.name) at \(price)")
        // Add your payment processing logic here
    }
    
    // Get plan price based on billing cycle
    private func getPlanPrice(for plan: SubscriptionPlan, cycle: BillingCycle) -> String {
        if plan.price == 0.00 {
            return "Free"
        }
        
        switch cycle {
        case .monthly:
            return "$\(String(format: "%.2f", plan.price))"
        case .yearly:
            switch plan.name {
            case "Nura Pro":
                return "$59.99"
            case "Nura Pro Unlimited":
                return "$79.99"
            default:
                return "$\(String(format: "%.2f", plan.price))"
            }
        }
    }
    
    // Plan management functions
    private func cancelSubscription() async {
        guard let userId = userTierManager.currentUserProfile?.id else {
            print("❌ No user ID available for subscription cancellation")
            return
        }
        
        await MainActor.run {
            isCancellingSubscription = true
        }
        
        do {
            print("🔄 Cancelling subscription for user: \(userId)")
            
            // Update the premium field (which is the actual field used in your Supabase database)
            try await AuthenticationManager.shared.client
                .from("profiles")
                .update(["premium": "free"])
                .eq("id", value: userId)
                .execute()
            
            print("✅ Subscription cancelled successfully in Supabase")
            
            // Update local state
            await MainActor.run {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    currentActivePlan = nil
                    showCancelAlert = false
                    isCancellingSubscription = false
                }
                
                // Show success banner after a brief delay to ensure smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showCancellationSuccess = true
                    }
                    
                    // Auto-hide the banner after 4 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showCancellationSuccess = false
                        }
                    }
                }
            }
            
            // Refresh user tier manager to reflect the change
            userTierManager.updatePremiumStatus()
            
        } catch {
            print("❌ Error cancelling subscription: \(error)")
            await MainActor.run {
                isCancellingSubscription = false
            }
            // In a production app, you might want to show an error alert here
        }
    }
    


    var body: some View {
        ZStack {
            // Enhanced background with dynamic gradients and patterns
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        colorScheme == .dark ? Color.black : Color(.systemGray6),
                        colorScheme == .dark ? Color(.systemGray6).opacity(0.3) : Color.white.opacity(0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Subtle radial gradient overlay
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.purple.opacity(0.08),
                        Color.blue.opacity(0.05),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 100,
                    endRadius: 400
                )
                
                // Animated floating elements
                ForEach(0..<6, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.1),
                                    Color.blue.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 60...120))
                        .offset(
                            x: CGFloat.random(in: -50...350),
                            y: CGFloat.random(in: -50...800)
                        )
                        .blur(radius: 20)
                        .opacity(0.6)
                }
            }
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Success Banner (appears after subscription cancellation)
                    if showCancellationSuccess {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Membership Cancelled")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.green)
                                    Text("You've been moved to the Free plan")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.green.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showCancellationSuccess = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                        .foregroundColor(.green.opacity(0.6))
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.green.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }
                    
                    // Enhanced Header
                    VStack(spacing: 8) {
                        Text("Choose Your Plan")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.top, 20)
                        
                        Text("Select the perfect plan for your skincare journey")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Current Plan Management Section (only shows if user has an active subscription)
                    // In production, this would be populated from Supabase based on user's subscription status
                    if let activePlan = currentActivePlan {
                        VStack(spacing: 20) {
                            Text("Current Plan")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 16) {
                                // Current Plan Card
                                VStack(spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack(spacing: 8) {
                                                Text(activePlan.displayName)
                                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                                
                                                // Active badge
                                                Text("ACTIVE")
                                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.green)
                                                    .cornerRadius(6)
                                            }
                                            
                                            Text(activePlan.description)
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(getPlanPrice(for: activePlan, cycle: currentBillingCycle))
                                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                                .foregroundColor(.purple)
                                            Text(currentBillingCycle == .monthly ? "per month" : "per year")
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    // Next billing info and cancel button row
                                    HStack {
                                        HStack(spacing: 4) {
                                            Image(systemName: "calendar")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("Next billing: \(nextBillingDate, formatter: dateFormatter)")
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        
                                        // Cancel button (only for paid plans)
                                        if activePlan.name != "Free" {
                                            Button(action: { showCancelAlert = true }) {
                                                HStack(spacing: 4) {
                                                    if isCancellingSubscription {
                                                        ProgressView()
                                                            .scaleEffect(0.6)
                                                            .foregroundColor(.red.opacity(0.8))
                                                    } else {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .font(.caption)
                                                            .foregroundColor(.red.opacity(0.8))
                                                    }
                                                    Text(isCancellingSubscription ? "Cancelling..." : "Cancel")
                                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                                        .foregroundColor(.red.opacity(0.8))
                                                }
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .fill(Color.red.opacity(0.1))
                                                )
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            .disabled(isCancellingSubscription)
                                        }
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    Color.green.opacity(0.1),
                                                    Color.blue.opacity(0.05)
                                                ]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 16)
                    }
                    
                    // Enhanced Plan Selection Bubbles
                    VStack(spacing: 20) {
                        Text("Available Plans")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 20)
                        
                        // Billing Cycle Toggle
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Text("Monthly")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(billingCycle == .monthly ? .primary : .secondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(billingCycle == .monthly ? Color.purple.opacity(0.1) : Color.clear)
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            billingCycle = .monthly
                                        }
                                    }
                                
                                // Toggle Switch
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(billingCycle == .yearly ? Color.purple : Color.gray.opacity(0.3))
                                        .frame(width: 50, height: 30)
                                    
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 26, height: 26)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                        .offset(x: billingCycle == .yearly ? 10 : -10)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: billingCycle)
                                }
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        billingCycle = billingCycle == .monthly ? BillingCycle.yearly : BillingCycle.monthly
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text("Yearly")
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .foregroundColor(billingCycle == .yearly ? .primary : .secondary)
                                        
                                        // Save badge for yearly
                                        if billingCycle == .yearly {
                                            Text("SAVE")
                                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.green)
                                                .cornerRadius(8)
                                                .transition(.scale.combined(with: .opacity))
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(billingCycle == .yearly ? Color.purple.opacity(0.1) : Color.clear)
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        billingCycle = .yearly
                                    }
                                }
                            }
                            
                            // Savings message
                            if billingCycle == .yearly {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                    Text("Save up to 35% with yearly billing")
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.green.opacity(0.1))
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        HStack(spacing: 16) {
                            ForEach(SubscriptionPlan.allPlans, id: \.id) { plan in
                                PlanBubbleView(
                                    plan: plan,
                                    isSelected: selectedPlan?.id == plan.id,
                                    billingCycle: billingCycle,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedPlan = plan
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    
                                        // Enhanced Payment Methods Section (only show if plan is selected)
                    if let selectedPlan = selectedPlan {
                        VStack(spacing: 24) {
                            // Enhanced Plan Summary
                            VStack(spacing: 12) {
                                Text("Selected Plan")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(selectedPlan.displayName)
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        Text(selectedPlan.description)
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(getPlanPrice(for: selectedPlan, cycle: billingCycle))
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                            .foregroundColor(.purple)
                                        Text(selectedPlan.price == 0.00 ? "Forever" : (billingCycle == .monthly ? "per month" : "per year"))
                                            .font(.system(size: 12, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(cardBackground)
                                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                )
                            }
                            
                            // Enhanced Apple Pay Section (only show for paid plans)
                            if selectedPlan.price > 0.00 {
                                VStack(spacing: 20) {
                                    Text("Quick & Secure")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                    
                                    Button(action: handleApplePay) {
                                        HStack {
                                            Image(systemName: "applelogo")
                                                .font(.title2)
                                            Text(isApplePayAvailable ? "Pay with Apple Pay" : "Apple Pay (Not Available)")
                                                .font(.headline)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(isApplePayAvailable ? Color.black : Color.gray)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(!isApplePayAvailable)
                                    
                                    HStack {
                                        Spacer()
                                        Text("or")
                                            .font(.system(size: 14, weight: .medium, design: .rounded))
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 12)
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Enhanced Manual Card Entry Section (only show for paid plans)
                            if selectedPlan.price > 0.00 {
                                VStack(spacing: 20) {
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            showCardEntry.toggle()
                                        }
                                    }) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "creditcard")
                                                .font(.title3)
                                                .foregroundColor(.purple)
                                            Text(showCardEntry ? "Hide Card Details" : "Add Card Manually")
                                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                            Spacer()
                                            Image(systemName: showCardEntry ? "chevron.up" : "chevron.down")
                                                .font(.caption)
                                                .foregroundColor(.purple)
                                        }
                                        .padding(20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(cardBackground)
                                                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                
                                if showCardEntry {
                                    // Card input form
                    VStack(spacing: 20) {
                        ZStack(alignment: .topTrailing) {
                            VStack(spacing: 18) {
                                HStack(alignment: .center, spacing: 12) {
                                    ZStack(alignment: .trailing) {
                                        TextField("Card number", text: $cardNumber)
                                            .keyboardType(.numberPad)
                                            .font(.system(size: 18, weight: .medium, design: .rounded))
                                            .onChange(of: cardNumber) { oldValue, newValue in
                                                let brand = CardBrand.detect(from: newValue)
                                                withAnimation(.easeInOut(duration: 0.25)) {
                                                    detectedBrand = brand
                                                    showBrand = brand != nil && !newValue.isEmpty
                                                }
                                            }
                                            .padding(.vertical, 12)
                                            .padding(.leading, 16)
                                            .padding(.trailing, 44)
                                            .background(cardBackground)
                                            .cornerRadius(12)
                                            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                        if let brand = detectedBrand, showBrand {
                                            CardBrandIcon(brand: brand)
                                                .transition(.scale.combined(with: .opacity))
                                                .padding(.trailing, 18)
                                                .animation(.easeInOut(duration: 0.25), value: detectedBrand)
                                        }
                                    }
                                }
                                HStack(spacing: 12) {
                                    TextField("MM/YY", text: $expiry)
                                        .keyboardType(.numbersAndPunctuation)
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(cardBackground)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                    TextField("CVV", text: $cvv)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(cardBackground)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                }
                                TextField("Cardholder name", text: $cardholder)
                                    .autocapitalization(.words)
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(cardBackground)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                TextField("Address", text: $address)
                                    .autocapitalization(.words)
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(cardBackground)
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                HStack(spacing: 12) {
                                    TextField("City", text: $city)
                                        .autocapitalization(.words)
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(cardBackground)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isValidCity(city) || city.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                                        )
                                    TextField("Country", text: $country)
                                        .autocapitalization(.words)
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(cardBackground)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isValidCountry(country) || country.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                                        )
                                    TextField("Zip code", text: $zipcode)
                                        .keyboardType(.numbersAndPunctuation)
                                        .font(.system(size: 16, weight: .regular, design: .rounded))
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(cardBackground)
                                        .cornerRadius(12)
                                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isValidZip(zipcode) || zipcode.isEmpty ? Color.clear : Color.red, lineWidth: 1)
                                        )
                                }
                            }
                            .padding(20)
                        }
                        .background(cardBackground)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                                        
                                        // Enhanced Pay with card button
                                        Button(action: handleManualCardPayment) {
                        HStack {
                            Spacer()
                                                Text(selectedPlan.price == 0.00 ? "Start Free Plan" : "Pay \(getPlanPrice(for: selectedPlan, cycle: billingCycle))")
                                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                                    .padding(.vertical, 18)
                            Spacer()
                        }
                        .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(
                                                        LinearGradient(
                                                            gradient: Gradient(colors: [Color.purple, Color.blue, Color.purple.opacity(0.8)]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                        )
                        .foregroundColor(.white)
                                            .shadow(color: Color.purple.opacity(0.3), radius: 12, x: 0, y: 6)
                                        }
                                        .padding(.horizontal, 20)
                                    }
                                    .transition(.move(edge: .top).combined(with: .opacity))
                                }
                            }
                            .padding(.horizontal, 8)
                        }
                        }
                    }
                    
                    // Enhanced Saved Cards Section
                    if !savedCards.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Saved Cards")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .padding(.top, 8)
                            ForEach(savedCards) { card in
                                SavedCardView(card: card, expanded: expandedCardID == card.id, onTap: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                        expandedCardID = expandedCardID == card.id ? nil : card.id
                                    }
                                }, onDelete: {
                                    showDeleteAlert = card.id
                                }, cardBackground: cardBackground)
                                .alert(isPresented: Binding<Bool>(
                                    get: { showDeleteAlert == card.id },
                                    set: { newValue in if !newValue { showDeleteAlert = nil } }
                                )) {
                                    Alert(
                                        title: Text("Delete Card"),
                                        message: Text("Are you sure you want to delete this card?"),
                                        primaryButton: .destructive(Text("Delete")) {
                                            withAnimation {
                                                savedCards.removeAll { $0.id == card.id }
                                                if expandedCardID == card.id { expandedCardID = nil }
                                            }
                                        },
                                        secondaryButton: .cancel()
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            checkApplePayAvailability()
            
            // Set current active plan based on UserTierManager (Supabase premium field)
            currentActivePlan = currentPlanFromTier
            
            // Set initial plan and billing cycle if provided
            if let initialPlan = initialPlan {
                selectedPlan = initialPlan
            }
            if let initialBillingCycle = initialBillingCycle {
                billingCycle = initialBillingCycle
            }
        }
        .alert("Cancel Subscription", isPresented: $showCancelAlert) {
            Button("Keep Subscription", role: .cancel) { }
            Button("Cancel Subscription", role: .destructive) {
                Task {
                    await cancelSubscription()
                }
            }
        } message: {
            Text("Your subscription will be cancelled and you'll be moved to the Free plan at the end of your current billing period (\(nextBillingDate, formatter: dateFormatter)). You'll keep all premium features until then.")
        }
    }
}

// MARK: - Subscription Plan Model

struct SubscriptionPlan: Identifiable {
    let id = UUID()
    let name: String
    let displayName: String
    let description: String
    let price: Double
    let features: [String]
    let isPopular: Bool
    
    static let allPlans: [SubscriptionPlan] = [
        SubscriptionPlan(
            name: "Free",
            displayName: "Free",
            description: "Essential skincare tracking",
            price: 0.00,
            features: ["Skin diary", "Basic analysis", "Routine tracking"],
            isPopular: false
        ),
        SubscriptionPlan(
            name: "Nura Pro",
            displayName: "Nura Pro",
            description: "Advanced AI-powered insights",
            price: 7.99,
            features: ["Everything in Free", "AI skin analysis", "Personalized recommendations", "Priority support"],
            isPopular: true
        ),
        SubscriptionPlan(
            name: "Nura Pro Unlimited",
            displayName: "Nura Pro ∞",
            description: "Complete skincare ecosystem",
            price: 9.99,
            features: ["Everything in Pro", "Expert consultations", "Custom formulations", "Exclusive products"],
            isPopular: false
        )
    ]
}

// MARK: - Plan Bubble View

struct PlanBubbleView: View {
    @Environment(\.colorScheme) private var colorScheme
    let plan: SubscriptionPlan
    let isSelected: Bool
    let billingCycle: BillingCycle
    let onTap: () -> Void
    
    private var bubbleBackground: LinearGradient {
        if isSelected {
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color.purple.opacity(0.9),
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? Color(.systemGray6) : .white,
                    colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var titleColor: Color {
        isSelected ? .white : (colorScheme == .dark ? .white : .black)
    }
    
    private var priceColor: Color {
        isSelected ? .white.opacity(0.9) : .purple
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Popular badge
                if plan.isPopular {
                    Text("MOST POPULAR")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(6)
                        .padding(.top, 8)
                } else {
                    Spacer()
                        .frame(height: 16)
                }
                
                // Plan title section
                VStack(spacing: 4) {
                    Text(plan.displayName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(titleColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.top, 4)
                
                // Price section
                VStack(spacing: 2) {
                    Text(plan.price == 0.00 ? "Free" : (billingCycle == .monthly ? "$\(String(format: "%.2f", plan.price))" : (plan.name == "Nura Pro" ? "$59.99" : "$79.99")))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(priceColor)
                    
                    Text(plan.price == 0.00 ? "Forever" : (billingCycle == .monthly ? "per month" : "per year"))
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                }
                .frame(height: 35)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.top, 6)
                
                Spacer()
            }
            .padding(12)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(bubbleBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected 
                        ? Color.purple.opacity(0.3) 
                        : (colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray4)),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected 
                ? Color.purple.opacity(0.4) 
                : (colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08)),
                radius: isSelected ? 12 : 6,
                x: 0,
                y: isSelected ? 6 : 3
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    }
}

// MARK: - Apple Pay Payment Handler

class PaymentHandler: NSObject, PKPaymentAuthorizationControllerDelegate {
    static let shared = PaymentHandler()
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController, didAuthorizePayment payment: PKPayment, handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        // Handle the payment authorization here
        // This is where you would send the payment token to your server
        print("Payment authorized: \(payment.token)")
        
        // For now, we'll just complete successfully
        // In a real app, you'd validate the payment with your server first
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
    }
    
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss()
    }
}

// MARK: - Card Brand Detection

enum CardBrand: String, CaseIterable {
    case visa, mastercard, amex, discover, diners, jcb, unionpay, unknown
    
    static func detect(from number: String) -> CardBrand? {
        let trimmed = number.replacingOccurrences(of: " ", with: "")
        if trimmed.hasPrefix("4") { return .visa }
        if trimmed.hasPrefix("5") { return .mastercard }
        if trimmed.hasPrefix("3") && trimmed.count > 1 && ["4", "7"].contains(trimmed[trimmed.index(trimmed.startIndex, offsetBy: 1)].description) { return .amex }
        if trimmed.hasPrefix("6") { return .discover }
        if trimmed.hasPrefix("3") && trimmed.count > 1 && ["6"].contains(trimmed[trimmed.index(trimmed.startIndex, offsetBy: 1)].description) { return .diners }
        if trimmed.hasPrefix("35") { return .jcb }
        if trimmed.hasPrefix("62") { return .unionpay }
        return nil
    }
}

struct CardBrandIcon: View {
    let brand: CardBrand
    var body: some View {
        switch brand {
        case .visa:
            Image("VisaLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 24)
                .shadow(radius: 1)
        case .mastercard:
            Image("MastercardLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 24)
                .shadow(radius: 1)
        case .amex:
            Image("AmexLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 24)
                .shadow(radius: 1)
        case .discover:
            Image("DiscoverLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 24)
                .shadow(radius: 1)
        case .diners:
            Image("DinersLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 24)
                .shadow(radius: 1)
        case .jcb:
            Image("JCBLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 24)
                .shadow(radius: 1)
        case .unionpay:
            Image("UnionPayLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 38, height: 24)
                .shadow(radius: 1)
        case .unknown:
            Image(systemName: "questionmark.circle")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Saved Card Model & View

struct SavedCard: Identifiable {
    let id = UUID()
    let brand: CardBrand
    let last4: String
    let cardholder: String
    let expiry: String
    let address: String
    let city: String
    let country: String
    let zipcode: String
}

struct SavedCardView: View {
    let card: SavedCard
    let expanded: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let cardBackground: Color
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 14) {
                    CardBrandIcon(brand: card.brand)
                        .frame(width: 28, height: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("•••• " + card.last4)
                            .font(.headline)
                        Text(card.cardholder)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(card.expiry)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)
                }
                .padding(12)
                .background(cardBackground)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    HStack {
                        Text("Cardholder:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(card.cardholder)
                            .font(.caption)
                    }
                    HStack {
                        Text("Expiry:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(card.expiry)
                            .font(.caption)
                    }
                    HStack {
                        Text("Card ending:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(card.last4)
                            .font(.caption)
                    }
                    HStack(alignment: .top) {
                        Text("Address:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(card.address)
                            .font(.caption)
                    }
                    HStack(alignment: .top) {
                        Text("City:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(card.city)
                            .font(.caption)
                    }
                    HStack(alignment: .top) {
                        Text("Country:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(card.country)
                            .font(.caption)
                    }
                    HStack(alignment: .top) {
                        Text("Zip code:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(card.zipcode)
                            .font(.caption)
                    }
                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            Text("Delete")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .underline()
                        }
                        .padding(.trailing, 2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
                .background(cardBackground)
                .cornerRadius(12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: expanded)
    }
}

#Preview {
    PaymentMethodsView()
} 
