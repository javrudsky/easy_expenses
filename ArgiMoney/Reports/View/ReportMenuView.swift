import SwiftUI
import Charts

enum ReportType: String, CaseIterable, Identifiable {
    case income = "Income & Expenses"
    case categories = "Expenses by Category"
    case cashFlow = "Cash Flow Analysis"
    case spending = "Spending Trends"
//    case budgets = "Budget Analysis"
    case accounts = "Account Analysis"
//    case insights = "Smart Insights"

    var id: String { rawValue }
    var premium: Bool { ![Self.income, .categories].contains(self) }
    /// Product that unlocks this report. Reports without a dedicated product
    /// are unlocked by the complete premium bundle.
    var premiumProduct: PurchaseProduct? {
        switch self {
        case .income, .categories: nil
        case .cashFlow: .cashFlow
        case .spending: .spending
//        case .budgets: .premiumBundle
        case .accounts: .accountsReport
//        case .insights: .insights
        }
    }
    var symbol: String {
        switch self {
        case .income: "chart.bar.fill"
        case .categories: "chart.pie.fill"
        case .cashFlow: "waveform.path.ecg"
        case .spending: "chart.line.uptrend.xyaxis"
//        case .budgets: "target"
        case .accounts: "creditcard.fill"
//        case .insights: "sparkles"
        }
    }
}

struct ReportMenuView: View {
    let dataset: ReportDataset
    var embedInNavigationStack: Bool = true
    @Environment(FeatureAccessManager.self) private var access

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
            if isUnlocked(report) {
                ReportMenuItemView(report: report, dataset: dataset)
            } else {
                PremiumReportsGate(report: report)
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

    private func isUnlocked(_ report: ReportType) -> Bool {
        guard let product = report.premiumProduct else { return true }
        return access.owns(product) || access.owns(.premiumBundle)
    }
}

struct PremiumReportsGate: View {
    let report: ReportType
    @Environment(FeatureAccessManager.self) private var access

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                ContentUnavailableView("Premium Report", systemImage: "crown.fill",
                                       description: Text("Unlock \(report.rawValue) with Argi Premium."))
                if access.state == .loading {
                    ProgressView("Checking purchases…")
                } else {
                    if let product = report.premiumProduct {
                        Button {
                            Task { _ = await access.purchase(product) }
                        } label: {
                            if access.busyProduct == product { ProgressView() }
                            else {
                                Text(access.metadata(for: product).map { "Unlock for \($0.displayPrice)" }
                                     ?? "Currently unavailable")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(access.busyProduct != nil || access.metadata(for: product) == nil)
                    }
                    NavigationLink {
                        PremiumStoreView()
                    } label: {
                        Text("View all premium features").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .navigationTitle(report.rawValue)
        .alert("Purchase information", isPresented: Binding(
            get: { access.lastError != nil },
            set: { if !$0 { access.clearError() } }
        )) {
            Button("OK") { access.clearError() }
        } message: {
            Text(access.lastError ?? "")
        }
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
//                case .budgets: budgetsView
                case .accounts: accountsView
//                case .insights: insightsView
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
        PremiumReportsGate(report: .spending)
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

