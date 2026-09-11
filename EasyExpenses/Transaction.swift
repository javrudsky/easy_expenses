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

    init(date: Date = .now,
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
