import Foundation

struct ReportSlice<Item: ReportDisplayItem>: Identifiable {
    let id: Item.ID
    let item: Item
    let amount: Decimal
    let fraction: Double

    init(id: Item.ID? = nil, item: Item, amount: Decimal, fraction: Double) {
        self.id = id ?? item.id
        self.item = item
        self.amount = amount
        self.fraction = fraction
    }
}

struct ReportBucket: Identifiable {
    let date: Date
    let income: Double
    let expenses: Double
    var id: Date { date }
}

struct ReportInsight: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let symbol: String
}

struct ReportAnalytics {
    let dataset: ReportDataset
    let range: ReportRange

    var filtered: [Transaction] { dataset.transactions.filter { range.contains($0.reportDate) } }
    var income: Decimal { total(.income) }
    var expenses: Decimal { total(.expense) }
    var net: Decimal { income - expenses }

    func total(_ type: TransactionType) -> Decimal {
        filtered.filter { $0.transactionType == type }.reduce(Decimal.zero) { $0 + $1.amount }
    }

    var categories: [ReportSlice<Category>] {
        let sum = expenses.reportDouble
        return dataset.categories.compactMap { item -> ReportSlice<Category>? in
            let amount = filtered.filter { $0.transactionType == .expense && $0.category.id == item.id }
                .reduce(Decimal.zero) { $0 + $1.amount }
            guard amount > 0 else { return nil }
            return ReportSlice(item: item, amount: amount,
                               fraction: sum > 0 ? amount.reportDouble / sum : 0)
        }.sorted { $0.amount > $1.amount }
    }

    var accounts: [ReportSlice<Account>] {
        dataset.accounts.map { item -> ReportSlice<Account> in
            let movements = dataset.transactions.filter { $0.account.id == item.id && $0.reportDate < range.endExclusive }
                .reduce(Decimal.zero) { total, tx in total + (tx.transactionType == .income ? tx.amount : -tx.amount) }
            let balance = (dataset.openingBalances[item.id] ?? 0) + movements
            return ReportSlice(item: item, amount: balance, fraction: 0)
        }
    }

    var buckets: [ReportBucket] {
        let calendar = Calendar.current
        let monthly = calendar.dateComponents([.month], from: range.start, to: range.endExclusive).month ?? 0
        let component: Calendar.Component = monthly >= 3 ? .month : .day
        var cursor = calendar.dateInterval(of: component, for: range.start)?.start ?? range.start
        var output: [ReportBucket] = []
        while cursor < range.endExclusive && output.count < 400 {
            guard let next = calendar.date(byAdding: component, value: 1, to: cursor) else { break }
            let txs = filtered.filter { $0.reportDate >= cursor && $0.reportDate < next }
            let inc = txs.filter { $0.transactionType == .income }.reduce(Decimal.zero) { $0 + $1.amount }
            let exp = txs.filter { $0.transactionType == .expense }.reduce(Decimal.zero) { $0 + $1.amount }
            output.append(.init(date: cursor, income: inc.reportDouble, expenses: exp.reportDouble))
            cursor = next
        }
        return output
    }

    func spent(for categoryID: UUID) -> Decimal {
        filtered.filter { $0.transactionType == .expense && $0.category.id == categoryID }
            .reduce(Decimal.zero) { $0 + $1.amount }
    }

    var insights: [ReportInsight] {
        var results: [ReportInsight] = []
        if let biggest = categories.first {
            results.append(.init(title: "Top spending category", detail: "\(biggest.item.name) accounts for \(biggest.fraction.formatted(.percent.precision(.fractionLength(0)))) of expenses.", symbol: "chart.pie.fill"))
        }
        if income > 0 {
            let rate = net.reportDouble / income.reportDouble
            results.append(.init(title: "Savings rate", detail: "You retained \(rate.formatted(.percent.precision(.fractionLength(1)))) of your income in this period.", symbol: "sparkles"))
        }
        let exceeded = dataset.budgets.filter { spent(for: $0.categoryID) > $0.amount }
        if !dataset.budgets.isEmpty {
            results.append(.init(title: exceeded.isEmpty ? "Budgets on track" : "Budget alert", detail: exceeded.isEmpty ? "All configured category budgets are within their limits." : "\(exceeded.count) category budget(s) exceeded their limits.", symbol: exceeded.isEmpty ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"))
        }
        if results.isEmpty { results.append(.init(title: "No insights yet", detail: "Add transactions to see spending insights.", symbol: "lightbulb")) }
        return results
    }
}
