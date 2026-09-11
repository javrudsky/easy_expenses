//
//  Transaction.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import Foundation
import SwiftData

enum TransactionType: String, Codable, CaseIterable {
    case debit = "d"
    case credit = "c"
}

@Model
final class Transaction {
    var date: Date
    var category: String
    var detail: String
    var transactionType: TransactionType
    var account: String
    var amount: Decimal

    // Make the initializer private to force usage of builder/factories
    init(date: Date,
                 category: String,
                 detail: String,
                 transactionType: TransactionType,
                 account: String,
                 amount: Decimal) {
        self.date = date
        self.category = category
        self.detail = detail
        self.transactionType = transactionType
        self.account = account
        self.amount = amount
    }

    var isDebit: Bool { transactionType == .debit }
}

// MARK: - Builder

struct TransactionBuilder {
    var date: Date? = nil
    var category: String? = nil
    var detail: String? = nil // optional/empty allowed
    var type: TransactionType? = nil
    var account: String? = nil
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

    func setting(date: Date) -> Self { var c = self; c.date = date; return c }
    func setting(category: String) -> Self { var c = self; c.category = category; return c }
    func setting(detail: String?) -> Self { var c = self; c.detail = detail; return c }
    func setting(type: TransactionType) -> Self { var c = self; c.type = type; return c }
    func setting(account: String) -> Self { var c = self; c.account = account; return c }
    func setting(amount: Decimal) -> Self { var c = self; c.amount = amount; return c }

    func build() throws -> Transaction {
        guard let date else { throw BuildError.missingDate }
        guard let category, !category.isEmpty else { throw BuildError.missingCategory }
        guard let type else { throw BuildError.missingType }
        guard let account, !account.isEmpty else { throw BuildError.missingAccount }
        guard let amount else { throw BuildError.missingAmount }
        return Transaction(
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
    static func debit(date: Date, category: String, account: String, amount: Decimal, detail: String? = nil) throws -> Transaction {
        try TransactionBuilder()
            .setting(date: date)
            .setting(category: category)
            .setting(account: account)
            .setting(amount: amount)
            .setting(type: .debit)
            .setting(detail: detail)
            .build()
    }

    static func credit(date: Date, category: String, account: String, amount: Decimal, detail: String? = nil) throws -> Transaction {
        try TransactionBuilder()
            .setting(date: date)
            .setting(category: category)
            .setting(account: account)
            .setting(amount: amount)
            .setting(type: .credit)
            .setting(detail: detail)
            .build()
    }
}
