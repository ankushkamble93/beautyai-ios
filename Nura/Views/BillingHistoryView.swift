import SwiftUI

struct BillingHistoryView: View {
    @State private var invoices: [Invoice] = [
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 2), description: "Nura Pro Monthly", amount: 9.99, status: .paid),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 32), description: "Nura Pro Monthly", amount: 9.99, status: .paid),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 62), description: "Nura Pro Monthly", amount: 9.99, status: .failed),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 92), description: "Nura Pro Monthly", amount: 9.99, status: .pending)
    ]
    @State private var animateDownload: UUID? = nil
    
    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text("Billing History")
                        .font(.largeTitle).fontWeight(.bold)
                        .padding(.top, 16)
                    Text("View and download past invoices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 18)
                // Billing list
                if invoices.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.gray.opacity(0.3))
                        Text("No billing history yet")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            ForEach(invoices) { invoice in
                                BillingRowView(invoice: invoice, animateDownload: $animateDownload)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color.white)
                                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                                    )
                                    .padding(.horizontal, 8)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .padding(.horizontal, 0)
        }
    }
}

struct BillingRowView: View {
    let invoice: Invoice
    @Binding var animateDownload: UUID?
    @State private var isHovered: Bool = false
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.dateFormatted)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(invoice.description)
                    .font(.headline)
                    .fontWeight(.medium)
                Text(String(format: "$%.2f", invoice.amount))
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer()
            StatusBadge(status: invoice.status)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    animateDownload = invoice.id
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    animateDownload = nil
                }
                // TODO: Implement PDF download logic
            }) {
                ZStack {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .scaleEffect(animateDownload == invoice.id ? 1.25 : 1.0)
                        .opacity(animateDownload == invoice.id ? 0.7 : 1.0)
                }
                .frame(width: 36, height: 36)
                .background(Color(.systemGray6))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.07), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 12)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: isHovered ? Color.accentColor.opacity(0.10) : Color.black.opacity(0.06), radius: isHovered ? 12 : 8, x: 0, y: 2)
        )
    }
}

struct StatusBadge: View {
    let status: InvoiceStatus
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.vertical, 4)
            .padding(.horizontal, 12)
            .background(
                Capsule().fill(status.color.opacity(0.13))
            )
            .foregroundColor(status.color)
    }
}

struct Invoice: Identifiable {
    let id = UUID()
    let date: Date
    let description: String
    let amount: Double
    let status: InvoiceStatus
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

enum InvoiceStatus: String {
    case paid, failed, pending
    var color: Color {
        switch self {
        case .paid: return .green
        case .failed: return .red
        case .pending: return .gray
        }
    }
}

#Preview {
    BillingHistoryView()
} 