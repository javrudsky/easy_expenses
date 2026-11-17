import Foundation
import SwiftUI
import Charts

// Centralized design tokens, shared by all seven screens.
enum ReportStyle {
    static let blue = Color(red: 0.10, green: 0.48, blue: 0.96)
    static let background = Color(red: 0.92, green: 0.95, blue: 1.00)
    static let ink = Color(red: 0.08, green: 0.14, blue: 0.26)
    static let green = Color(red: 0.10, green: 0.64, blue: 0.33)
    static let red = Color(red: 0.91, green: 0.19, blue: 0.24)
}

struct ReportCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 17))
            .shadow(color: .blue.opacity(0.08), radius: 10, y: 4)
    }
}

struct ReportPeriodPicker: View {
    @Binding var selection: ReportDateSelection
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 3) {
                ForEach(ReportPeriod.allCases) { period in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { selection.period = period }
                    } label: {
                        Text(period.localizedTitle)
                            .font(.system(size: 12, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(selection.period == period ? .white : ReportStyle.ink)
                            .background(selection.period == period ? ReportStyle.blue : .clear, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(.white.opacity(0.8), in: Capsule())
            if selection.period == .custom {
                VStack(spacing: 8) {
                    DatePicker("From", selection: $selection.from, displayedComponents: .date)
            DatePicker("To", selection: $selection.to, in: selection.from..., displayedComponents: .date)
                }
                .font(.subheadline)
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }
}

struct ReportMetric: View {
    let title: String
    let amount: Decimal
    let symbol: String
    let tint: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).foregroundStyle(tint).font(.title3)
            Text(LocalizedStringKey(title)).font(.caption2).foregroundStyle(.secondary)
            Text(amount.reportCurrency).font(.system(size: 14, weight: .bold)).minimumScaleFactor(0.6).lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ReportMetricStrip: View {
    let income: Decimal
    let expenses: Decimal
    let balance: Decimal
    var body: some View {
        HStack(spacing: 7) {
            ReportMetric(title: String(localized: "Income"), amount: income, symbol: "arrow.up.right", tint: ReportStyle.green)
            ReportMetric(title: String(localized: "Expenses"), amount: expenses, symbol: "arrow.down.right", tint: ReportStyle.red)
            ReportMetric(title: String(localized: "Net Flow"), amount: balance, symbol: "equal", tint: ReportStyle.blue)
        }
    }
}

struct ReportItemRow<Item: ReportDisplayItem>: View {
    let item: Item
    let amount: Decimal
    var detail: String? = nil
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.imageName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(item.color)
                .frame(width: 38, height: 38)
                .background(item.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).font(.subheadline.weight(.semibold))
                if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 4)
            Text(amount.reportCurrency).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.7)
        }
    }
}

struct ReportProgressRow: View {
    let item: Category
    let spent: Decimal
    let budget: Decimal
    var body: some View {
        VStack(spacing: 8) {
            ReportItemRow(item: item, amount: spent, detail: String(localized: "Budget: \(budget.reportCurrency)"))
            ProgressView(value: max(0, spent.reportDouble), total: max(1, budget.reportDouble))
                .tint(spent > budget ? ReportStyle.red : ReportStyle.blue)
        }
    }
}
