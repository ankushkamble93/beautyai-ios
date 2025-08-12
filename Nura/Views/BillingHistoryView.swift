import SwiftUI

struct BillingHistoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    private var cardBackground: Color {
        colorScheme == .dark ? Color.black.opacity(0.7) : .white
    }
    
    @State private var invoices: [Invoice] = [
        // Recent invoices with updated plans
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 2), description: "Nura Pro Monthly", amount: 7.99, status: .paid),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 3), description: "Nura Pro Unlimited Monthly", amount: 9.99, status: .paid),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 32), description: "Nura Pro Monthly", amount: 7.99, status: .paid),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 33), description: "Nura Pro Unlimited Monthly", amount: 9.99, status: .paid),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 62), description: "Nura Pro Monthly", amount: 7.99, status: .failed),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 63), description: "Nura Pro Unlimited Monthly", amount: 9.99, status: .paid),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 92), description: "Nura Pro Monthly", amount: 7.99, status: .pending),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 93), description: "Nura Pro Unlimited Monthly", amount: 9.99, status: .paid),
        // Yearly invoices for testing filter
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 365), description: "Nura Pro Yearly", amount: 59.99, status: .paid),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 366), description: "Nura Pro Unlimited Yearly", amount: 79.99, status: .paid),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 730), description: "Nura Pro Yearly", amount: 59.99, status: .paid),
        Invoice(date: Date(timeIntervalSinceNow: -86400 * 731), description: "Nura Pro Unlimited Yearly", amount: 79.99, status: .paid)
    ]
    
    @State private var animateDownload: UUID? = nil
    @State private var selectedFilter: DateFilter = .all
    @State private var showFilterPicker: Bool = false
    
    // Filtered invoices based on selected filter
    private var filteredInvoices: [Invoice] {
        switch selectedFilter {
        case .all:
            return invoices
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            return invoices.filter { invoice in
                calendar.isDate(invoice.date, equalTo: now, toGranularity: .month)
            }
        case .lastMonth:
            let calendar = Calendar.current
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            return invoices.filter { invoice in
                calendar.isDate(invoice.date, equalTo: lastMonth, toGranularity: .month)
            }
        case .thisYear:
            let calendar = Calendar.current
            let now = Date()
            return invoices.filter { invoice in
                calendar.isDate(invoice.date, equalTo: now, toGranularity: .year)
            }
        case .lastYear:
            let calendar = Calendar.current
            let lastYear = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            return invoices.filter { invoice in
                calendar.isDate(invoice.date, equalTo: lastYear, toGranularity: .year)
            }
        }
    }
    
    // Check if filter should be shown (only if there are multiple invoices in different time periods)
    private var shouldShowFilter: Bool {
        let calendar = Calendar.current
        let now = Date()
        let thisMonth = invoices.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
        let lastMonth = invoices.filter { 
            let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return calendar.isDate($0.date, equalTo: lastMonthDate, toGranularity: .month)
        }
        let thisYear = invoices.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .year) }
        let lastYear = invoices.filter { 
            let lastYearDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return calendar.isDate($0.date, equalTo: lastYearDate, toGranularity: .year)
        }
        
        return thisMonth.count > 0 && (lastMonth.count > 0 || thisYear.count > 2 || lastYear.count > 0)
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
                        Color.purple.opacity(0.06),
                        Color.blue.opacity(0.04),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 150,
                    endRadius: 500
                )
                
                // Animated floating elements
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.purple.opacity(0.08),
                                    Color.blue.opacity(0.04)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 40...80))
                        .offset(
                            x: CGFloat.random(in: -30...350),
                            y: CGFloat.random(in: -30...600)
                        )
                        .blur(radius: 15)
                        .opacity(0.5)
                }
            }
            .ignoresSafeArea()
            
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
                
                // Filter Section (only show if there are multiple invoices in different periods)
                if shouldShowFilter && !invoices.isEmpty {
                    VStack(spacing: 12) {
                        Button(action: {
                            showFilterPicker.toggle()
                        }) {
                            HStack {
                                Text("Filter by:")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Spacer()
                                HStack(spacing: 6) {
                                    Text(selectedFilter.displayName)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.purple)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                        .rotationEffect(.degrees(showFilterPicker ? 180 : 0))
                                        .animation(.easeInOut(duration: 0.2), value: showFilterPicker)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.purple.opacity(0.1))
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if showFilterPicker {
                            VStack(spacing: 8) {
                                ForEach(DateFilter.allCases, id: \.self) { filter in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedFilter = filter
                                            showFilterPicker = false
                                        }
                                    }) {
                                        HStack {
                                            Text(filter.displayName)
                                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                                .foregroundColor(selectedFilter == filter ? .white : .primary)
                                            Spacer()
                                            if selectedFilter == filter {
                                                Image(systemName: "checkmark")
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedFilter == filter ? Color.purple : Color.clear)
                                        )
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(cardBackground)
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                // Billing list
                if invoices.isEmpty {
                    // Empty state when no invoices exist
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray.opacity(0.4))
                        
                        VStack(spacing: 8) {
                            Text("No billing history yet")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("Your invoices will appear here once you have active subscriptions")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    .padding(.top, 80)
                } else if filteredInvoices.isEmpty {
                    // Empty state when filter returns no results
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.gray.opacity(0.4))
                        
                        VStack(spacing: 8) {
                            Text("No invoices found")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("Try adjusting your filter or select a different time period")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                    .padding(.top, 60)
                } else {
                    ScrollView {
                        VStack(spacing: 18) {
                            ForEach(filteredInvoices) { invoice in
                                BillingRowView(invoice: invoice, animateDownload: $animateDownload, cardBackground: cardBackground)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(cardBackground)
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

// Date filter enum
enum DateFilter: CaseIterable {
    case all, thisMonth, lastMonth, thisYear, lastYear
    
    var displayName: String {
        switch self {
        case .all: return "All Time"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .thisYear: return "This Year"
        case .lastYear: return "Last Year"
        }
    }
}

struct BillingRowView: View {
    let invoice: Invoice
    @Binding var animateDownload: UUID?
    let cardBackground: Color
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
                .background(cardBackground)
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
                .fill(cardBackground)
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