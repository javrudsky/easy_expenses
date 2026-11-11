import SwiftUI
import Charts

enum ReportType: String, CaseIterable, Identifiable {
    case income = "Income & Expenses"
    case categories = "Expenses by Category"
    case cashFlow = "Cash Flow Analysis"
    case spending = "Spending Trends"
    case budgets = "Budget Analysis"
    case accounts = "Account Analysis"
    case insights = "Smart Insights"

    var id: String { rawValue }
    var premium: Bool { ![Self.income, .categories].contains(self) }
    var symbol: String {
        switch self {
        case .income: "chart.bar.fill"
        case .categories: "chart.pie.fill"
        case .cashFlow: "waveform.path.ecg"
        case .spending: "chart.line.uptrend.xyaxis"
        case .budgets: "target"
        case .accounts: "creditcard.fill"
        case .insights: "sparkles"
        }
    }
}

struct ReportMenuView: View {
    let dataset: ReportDataset
    // Connect this to your StoreKit entitlement state.
    var hasPremium: Bool = false
    var embedInNavigationStack: Bool = true

    @ViewBuilder
    var body: some View {
        if embedInNavigationStack {
            NavigationStack { content }
        } else {
            content
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Free Reports").font(.headline).padding(.horizontal, 4)
                ForEach(ReportType.allCases.filter { !$0.premium }) { report in
                    reportLink(report)
                }
                Text("Premium Reports").font(.headline).padding(.horizontal, 4).padding(.top, 8)
                ForEach(ReportType.allCases.filter(\.premium)) { report in
                    reportLink(report)
                }
            }
            .padding(16)
        }
        .background(ReportStyle.background.ignoresSafeArea())
        .navigationTitle("Reports")
    }

    @ViewBuilder private func reportLink(_ report: ReportType) -> some View {
        NavigationLink {
            if report.premium && !hasPremium {
                PremiumReportsGate(report: report)
            } else {
                ReportMenuItemView(report: report, dataset: dataset)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: report.symbol)
                    .foregroundStyle(ReportStyle.blue)
                    .frame(width: 42, height: 42)
                    .background(ReportStyle.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                Text(report.rawValue).font(.subheadline.weight(.semibold))
                Spacer()
                if report.premium {
                    Label("Premium", systemImage: "crown.fill")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.orange)
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .foregroundStyle(ReportStyle.ink)
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 17))
        }
        .buttonStyle(.plain)
    }
}

struct PremiumReportsGate: View {
    let report: ReportType
    var body: some View {
        ContentUnavailableView("Premium Report", systemImage: "crown.fill",
                               description: Text("Unlock \(report.rawValue) with Argi Premium."))
            .navigationTitle(report.rawValue)
        // Replace with your StoreKit purchase / paywall screen.
    }
}

struct ReportMenuItemView: View {
    let report: ReportType
    let dataset: ReportDataset
    @State private var selection = ReportDateSelection()

    private var analytics: ReportAnalytics { .init(dataset: dataset, range: selection.range) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(report.rawValue).font(.title2.bold())
                    Spacer()
                    Text(report.premium ? "♛ Premium" : "Free")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(report.premium ? .orange : ReportStyle.blue)
                }
                ReportPeriodPicker(selection: $selection)
                switch report {
                case .income: incomeView
                case .categories: categoriesView
                case .cashFlow: cashFlowView
                case .spending: spendingView
                case .budgets: budgetsView
                case .accounts: accountsView
                case .insights: insightsView
                }
            }
            .padding(16)
        }
        .background(ReportStyle.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }

    private var incomeView: some View {
        VStack(spacing: 14) {
            ReportMetricStrip(income: analytics.income, expenses: analytics.expenses, balance: analytics.net)
            ReportCard {
                Text("Income vs. Expenses").font(.headline)
                ReportTrendChart(buckets: analytics.buckets)
            }
            ReportCard {
                Text("Period Summary").font(.headline)
                HStack {
                    Text("Net cash flow")
                    Spacer()
                    Text(analytics.net.reportCurrency).bold()
                        .foregroundStyle(analytics.net >= 0 ? ReportStyle.green : ReportStyle.red)
                }
            }
        }
    }

    private var categoriesView: some View {
        VStack(spacing: 14) {
            ReportCard {
                Text("Expense Distribution").font(.headline)
                if analytics.categories.isEmpty {
                    ContentUnavailableView("No expenses", systemImage: "chart.pie")
                } else { ReportDonutChart(slices: analytics.categories) }
            }
            ReportCard {
                Text("By Category").font(.headline)
                ForEach(analytics.categories) { slice in
                    ReportItemRow(item: slice.item, amount: slice.amount,
                                  detail: slice.fraction.formatted(.percent.precision(.fractionLength(1))))
                    if slice.id != analytics.categories.last?.id { Divider() }
                }
            }
        }
    }

    private var cashFlowView: some View {
#if PREMIUM
        CashFlowReportView(analytics: analytics)
#else
        PremiumReportsGate(report: .cashFlow)
#endif
    }

    private var spendingView: some View {
#if PREMIUM
        SpendingReportView(analytics: analytics)
#else
        PremiumReportsGate(report: .insights)
#endif
    }

    private var budgetsView: some View {
#if PREMIUM
        BudgetsReportView(selection: $selection,
                          dataset: dataset,
                          analytics: analytics)
#else
        PremiumReportsGate(report: .budgets)
#endif
    }

    private var accountsView: some View {
#if PREMIUM
        AccountsReportView(analytics: analytics)
#else
        PremiumReportsGate(report: .accounts)
#endif
    }

    private var insightsView: some View {
#if PREMIUM
        InsightsReportView(analytics: analytics)
#else
        PremiumReportsGate(report: .insights)
#endif
        
        
        //        VStack(spacing: 14) {
//            ReportCard {
//                Label("Your Financial Insights", systemImage: "sparkles")
//                    .font(.headline).foregroundStyle(.purple)
//                Text("Insights are calculated on your device from your transactions.")
//                    .font(.caption).foregroundStyle(.secondary)
//            }
//            ForEach(analytics.insights) { insight in
//                ReportCard { ReportInsightRow(insight: insight) }
//            }
//        }
//    }
    }
}

struct ReportDonutChart: View {
    let slices: [ReportSlice<Category>]
    var body: some View {
        Chart(slices) { slice in
            SectorMark(angle: .value("Amount", slice.amount.reportDouble), innerRadius: .ratio(0.64), angularInset: 2)
                .foregroundStyle(slice.item.color)
                .cornerRadius(3)
        }
        .frame(height: 210)
        .overlay {
            VStack(spacing: 3) {
                Text(slices.reduce(Decimal.zero) { $0 + $1.amount }.reportCurrency)
                    .font(.headline).minimumScaleFactor(0.7).lineLimit(1)
                Text("Total Expenses").font(.caption2).foregroundStyle(.secondary)
            }.padding(30)
        }
    }
}

struct ReportTrendChart: View {
    let buckets: [ReportBucket]
    var line: Bool = false
    var body: some View {
        Chart {
            ForEach(buckets) { bucket in
                if line {
                    LineMark(x: .value("Date", bucket.date), y: .value("Income", bucket.income))
                        .foregroundStyle(by: .value("Type", "Income"))
                    LineMark(x: .value("Date", bucket.date), y: .value("Expenses", bucket.expenses))
                        .foregroundStyle(by: .value("Type", "Expenses"))
                } else {
                    BarMark(x: .value("Date", bucket.date), y: .value("Income", bucket.income))
                        .foregroundStyle(by: .value("Type", "Income"))
                        .position(by: .value("Type", "Income"))
                    BarMark(x: .value("Date", bucket.date), y: .value("Expenses", bucket.expenses))
                        .foregroundStyle(by: .value("Type", "Expenses"))
                        .position(by: .value("Type", "Expenses"))
                }
            }
        }
        .chartForegroundStyleScale(["Income": ReportStyle.blue, "Expenses": .purple])
        .chartLegend(position: .top, alignment: .trailing)
        .frame(height: 210)
    }
}

