import SwiftUI

struct ProductCardView: View {
    let product: ProductSearchResult
    // Use AsyncImage for simplicity to avoid custom loader dependency
    @State private var isSaved = false
    @EnvironmentObject var userTierManager: UserTierManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 80, height: 80)
                if let urlStr = product.imageURL, let url = URL(string: urlStr) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .failure:
                            Image(systemName: "photo").font(.title2).foregroundColor(.secondary)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            ProgressView()
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    if let brand = product.brand { Text(brand).font(.subheadline).foregroundColor(.secondary) }
                    if let price = product.priceText { Text(price).font(.subheadline).foregroundColor(.secondary) }
                }
                if !product.benefits.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(product.benefits.prefix(3), id: \.self) { b in
                            Text(b.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(8)
                        }
                    }
                }
                HStack(spacing: 12) {
                    Button(action: { saveToRoutine(product) }) {
                        Label(isSaved ? "Saved" : "Save to Routine", systemImage: isSaved ? "checkmark.circle.fill" : "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    if let dest = product.destinationURL, let url = URL(string: dest) {
                        Link("View", destination: url).font(.caption)
                    }
                }
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        // No custom loader needed
    }
    
    private func saveToRoutine(_ product: ProductSearchResult) {
        var saved = UserDefaults.standard.array(forKey: "nura.saved.products") as? [Data] ?? []
        if let data = try? JSONEncoder().encode(product) {
            saved.append(data)
            UserDefaults.standard.set(saved, forKey: "nura.saved.products")
            isSaved = true
        }
    }
}

struct ProductCardList: View {
    let products: [ProductSearchResult]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(products) { p in
                ProductCardView(product: p)
            }
        }
    }
}


