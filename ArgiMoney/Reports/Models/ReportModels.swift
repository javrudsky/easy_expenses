import Foundation
import SwiftUI

/// Common presentation surface shared by the project's Category and Account models.
protocol ReportDisplayItem: Identifiable {
    var name: String { get }
    var imageName: String { get }
    var rgbColor: String { get }
}

extension Category: ReportDisplayItem {}
extension Account: ReportDisplayItem {}

extension ReportDisplayItem {
    var color: Color { Color(rgbaCsv: rgbColor) }
}

extension Transaction {
    var reportDate: Date { Date(timeIntervalSince1970: date) }
}

struct ReportBudget: Identifiable {
    let categoryID: UUID
    let amount: Decimal
    var id: UUID { categoryID }
}

struct ReportDataset {
    var transactions: [Transaction]
    var categories: [Category]
    var accounts: [Account]
    var budgets: [ReportBudget]
    // Optional opening balances for accounts; without them, account totals are net movements.
    var openingBalances: [UUID: Decimal] = [:]
}

struct ReportRange: Equatable {
    var start: Date
    var endExclusive: Date
    func contains(_ date: Date) -> Bool { date >= start && date < endExclusive }
}

enum ReportPeriod: String, CaseIterable, Identifiable {
    case month = "This Month", year = "This Year", custom = "Custom"
    var id: Self { self }
}

struct ReportDateSelection {
    var period: ReportPeriod = .month
    var from: Date = Calendar.current.startOfDay(for: .now)
    var to: Date = .now

    var range: ReportRange {
        let calendar = Calendar.current
        let today = Date()
        switch period {
        case .month:
            let start = calendar.dateInterval(of: .month, for: today)!.start
            return .init(start: start, endExclusive: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today))!)
        case .year:
            let start = calendar.dateInterval(of: .year, for: today)!.start
            return .init(start: start, endExclusive: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today))!)
        case .custom:
            let first = min(from, to), last = max(from, to)
            return .init(start: calendar.startOfDay(for: first), endExclusive: calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last))!)
        }
    }
}

extension Decimal {
    var reportDouble: Double { NSDecimalNumber(decimal: self).doubleValue }
    // TODO: Remove hardcoded USD
    var reportCurrency: String { self.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")) }
}
