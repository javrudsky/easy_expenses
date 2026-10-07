//
//  Transaction.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case expense = "expense"
    case income = "income"
}

struct Transaction: Sendable, Identifiable {
    
    var id: UUID
    var date: TimeInterval
    var category: Category
    var detail: String?
    var transactionType: TransactionType
    var account: Account
    var amount: Decimal
}

struct TransactionDefaults {
    var date: TimeInterval
    var incomeCategory: Category
    var expenseCategory: Category
    var account: Account
}

// MARK: - Builder
struct TransactionBuilder {
    var id: UUID = UUID()
    var date: TimeInterval? = nil
    var category: Category? = nil
    var detail: String? = nil // optional/empty allowed
    var type: TransactionType? = nil
    var account: Account? = nil
    var amount: Decimal? = nil

    enum BuildError: Error, LocalizedError {
        case missingDate
        case missingCategory
        case missingType
        case missingAccount
        case missingAmount

        var errorDescription: String? {
            switch self {
            case .missingDate: return "Date is required."
            case .missingCategory: return "Category is required."
            case .missingType: return "Transaction type is required."
            case .missingAccount: return "Account is required."
            case .missingAmount: return "Amount is required."
            }
        }
    }

    nonisolated func setting(id: UUID) -> Self { var c = self; c.id = id; return c }
    nonisolated func setting(date: TimeInterval) -> Self { var c = self; c.date = date; return c }
    nonisolated func setting(category: Category) -> Self { var c = self; c.category = category; return c }
    nonisolated func setting(detail: String?) -> Self { var c = self; c.detail = detail; return c }
    nonisolated func setting(type: TransactionType) -> Self { var c = self; c.type = type; return c }
    nonisolated func setting(account: Account) -> Self { var c = self; c.account = account; return c }
    nonisolated func setting(amount: Decimal) -> Self { var c = self; c.amount = amount; return c }

    nonisolated func build() throws -> Transaction {
        guard let date else { throw BuildError.missingDate }
        guard let category else { throw BuildError.missingCategory }
        guard let type else { throw BuildError.missingType }
        guard let account else { throw BuildError.missingAccount }
        guard let amount else { throw BuildError.missingAmount }
        return Transaction(
            id: id,
            date: date,
            category: category,
            detail: detail ?? "",
            transactionType: type,
            account: account,
            amount: amount
        )
    }
}

// MARK: - Factory helpers

extension Transaction {
    
    var isExpense: Bool {
        return transactionType == .expense ? true : false
    }
    
    static func expense(date: TimeInterval,
                      category: Category,
                      account: Account,
                      amount: Decimal,
                      detail: String? = nil) throws -> Transaction {
        try TransactionBuilder()
            .setting(date: date)
            .setting(category: category)
            .setting(account: account)
            .setting(amount: amount)
            .setting(type: .expense)
            .setting(detail: detail)
            .build()
    }

    static func income(date: TimeInterval,
                       category: Category,
                       account: Account,
                       amount: Decimal,
                       detail: String? = nil) throws -> Transaction {
        try TransactionBuilder()
            .setting(date: date)
            .setting(category: category)
            .setting(account: account)
            .setting(amount: amount)
            .setting(type: .expense)
            .setting(detail: detail)
            .build()
    }
}

