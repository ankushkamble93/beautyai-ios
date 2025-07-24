import SwiftUI

struct PaymentMethodsView: View {
    @Environment(\.colorScheme) private var colorScheme
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
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
    @State private var savedCards: [SavedCard] = [
        SavedCard(brand: .visa, last4: "4242", cardholder: "Jane Doe", expiry: "12/26", address: "123 Main St", city: "New York", country: "USA", zipcode: "10001"),
        SavedCard(brand: .mastercard, last4: "4444", cardholder: "Jane Doe", expiry: "09/25", address: "456 Elm St", city: "San Francisco", country: "USA", zipcode: "94102")
    ]
    @State private var expandedCardID: UUID? = nil
    @State private var showDeleteAlert: UUID? = nil
    
    // Simple validation (replace with real API for production)
    func isValidCity(_ city: String) -> Bool { city.count > 1 }
    func isValidCountry(_ country: String) -> Bool { country.count > 1 }
    func isValidZip(_ zip: String) -> Bool { zip.count >= 4 && zip.count <= 10 }

    var body: some View {
        ZStack {
            (colorScheme == .dark ? Color.black : Color(.systemGray6)).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 4) {
                        Text("Payment Methods")
                            .font(.largeTitle).fontWeight(.bold)
                            .padding(.top, 16)
                        Text("Securely manage your cards")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
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
                    }
                    // Save card button
                    Button(action: {
                        // Save card logic here
                    }) {
                        HStack {
                            Spacer()
                            Text("Save card")
                                .fontWeight(.semibold)
                                .padding(.vertical, 14)
                            Spacer()
                        }
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]), startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.purple.opacity(0.18), radius: 6, x: 0, y: 2)
                    }
                    .padding(.horizontal, 8)
                    // Previously added cards
                    if !savedCards.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Saved Cards")
                                .font(.headline)
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