//
//  Transaction.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import Foundation

struct TransactionDefaults: Sendable {
    let date: TimeInterval
    let category: String
    let account: String
    
    init(date: TimeInterval = Date().timeIntervalSince1970,
         category: String = "other",
         account: String = "other") {
        self.date = date
        self.category = category
        self.account = account
    }
}

enum TransactionType: String, Codable, CaseIterable {
    case debit = "debit"
    case credit = "credit"
}

struct Transaction: Sendable, Identifiable {
    
    var id: String
    var date: TimeInterval
    var category: String
    var detail: String?
    var transactionType: TransactionType
    var account: String
    var amount: Decimal
}

// MARK: - Builder
struct TransactionBuilder {
    var id: String = UUID().uuidString
    var date: TimeInterval? = nil
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

    nonisolated func setting(id: String) -> Self { var c = self; c.id = id; return c }
    nonisolated func setting(date: TimeInterval) -> Self { var c = self; c.date = date; return c }
    nonisolated func setting(category: String) -> Self { var c = self; c.category = category; return c }
    nonisolated func setting(detail: String?) -> Self { var c = self; c.detail = detail; return c }
    nonisolated func setting(type: TransactionType) -> Self { var c = self; c.type = type; return c }
    nonisolated func setting(account: String) -> Self { var c = self; c.account = account; return c }
    nonisolated func setting(amount: Decimal) -> Self { var c = self; c.amount = amount; return c }

    nonisolated func build() throws -> Transaction {
        guard let date else { throw BuildError.missingDate }
        guard let category, !category.isEmpty else { throw BuildError.missingCategory }
        guard let type else { throw BuildError.missingType }
        guard let account, !account.isEmpty else { throw BuildError.missingAccount }
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
    
    var isDebit: Bool {
        return transactionType == .debit ? true : false
    }
    
    static func debit(date: TimeInterval, category: String, account: String, amount: Decimal, detail: String? = nil) throws -> Transaction {
        try TransactionBuilder()
            .setting(date: date)
            .setting(category: category)
            .setting(account: account)
            .setting(amount: amount)
            .setting(type: .debit)
            .setting(detail: detail)
            .build()
    }

    static func credit(date: TimeInterval, category: String, account: String, amount: Decimal, detail: String? = nil) throws -> Transaction {
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
