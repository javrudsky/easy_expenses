import Foundation

// Preview/demo only. The live app loads these models from the project repositories.
enum ReportDemoData {
    static let housing = Category(id: UUID(), name: "Housing",
                                  transactionType: .expense,
                                  imageName: "house.fill",
                                  rgbColor: "0.36, 0.32, 0.95, 1.0")
    static let food = Category(id: UUID(), name: "Food & Dining",
                               transactionType: .expense,
                               imageName: "fork.knife",
                               rgbColor: "0.72, 0.27, 0.85, 1.0")
    static let transport = Category(id: UUID(), name: "Transportation",
                                    transactionType: .expense,
                                    imageName: "car.fill",
                                    rgbColor: "1.0, 0.48, 0.12, 1.0")
    static let salary = Category(id: UUID(), name: "Salary",
                                 transactionType: .income,
                                 imageName: "dollarsign.circle.fill",
                                 rgbColor: "0.15, 0.68, 0.4, 1.0")

    static let checking = Account(id: UUID(), name: "Checking",
                                  imageName: "building.columns.fill",
                                  rgbColor: "0.1, 0.48, 0.96, 1.0")
    static let savings = Account(id: UUID(), name: "Savings",
                                 imageName: "banknote.fill",
                                 rgbColor: "0.15, 0.68, 0.4, 1.0")

    static var dataset: ReportDataset {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .month, value: -5, to: .now)!
        var transactions: [Transaction] = []
        for index in 0..<6 {
            let date = calendar.date(byAdding: .month, value: index, to: start)!
            let account = index.isMultiple(of: 2) ? checking : savings
            transactions.append(.init(id: UUID(),
                                      date: date.timeIntervalSince1970,
                                      category: salary,
                                      detail: nil,
                                      transactionType: .income,
                                      account: account,
                                      amount: Decimal(4500 + index * 80)))
            for (category, amount) in [(housing, 1260), (food, 580), (transport, 400)] {
                transactions.append(.init(id: UUID(),
                                          date: date.timeIntervalSince1970,
                                          category: category,
                                          detail: nil,
                                          transactionType: .expense,
                                          account: account,
                                          amount: Decimal(amount + index * 20)))
            }
        }
        return .init(transactions: transactions,
                     categories: [housing, food, transport, salary],
                     accounts: [checking, savings],
                     budgets: [.init(categoryID: housing.id, amount: 1300),
                               .init(categoryID: food.id, amount: 600),
                               .init(categoryID: transport.id, amount: 500)])
    }
}

#if DEBUG
import SwiftUI
#Preview { ReportMenuView(dataset: ReportDemoData.dataset, hasPremium: true) }
#endif
