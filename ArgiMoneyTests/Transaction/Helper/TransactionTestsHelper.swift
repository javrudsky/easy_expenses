//
//  TransactionTestsHelper.swift
//  EasyExpensesTests
//
//  Created by Javier Avrudsky on 17/09/2026.
//

import Foundation
@testable import EasyExpenses

struct TransactionTestsHelper {
    
    static func createTransaction(id: UUID = UUID(),
                                  date: TimeInterval = Date().timeIntervalSince1970,
                                  category: String = "MyCategory",
                                  detail: String = "",
                                  transactionType: TransactionType = .debit,
                                  account: String = "MyAccount",
                                  amount: Decimal = 10) -> Transaction {
        return Transaction(id: id,
                           date: date,
                           category: category,
                           detail: detail,
                           transactionType: transactionType,
                           account: account,
                           amount: amount)
    }
    
    static func clone(transaction tx: Transaction) -> Transaction {
        return Transaction(id: tx.id,
                           date: tx.date,
                           category: tx.category,
                           detail: tx.detail,
                           transactionType: tx.transactionType,
                           account: tx.account,
                           amount: tx.amount)
    }
    
    static func createModelTransaction(id: UUID = UUID(),
                                       date: TimeInterval = 1234567890,
                                       category: String = "Food",
                                       detail: String = "Lunch",
                                       transactionType: String = TransactionType.debit.rawValue,
                                       account: String = "Checking",
                                       amount: Decimal = 45.67) -> TransactionModel {
        return TransactionModel(id: id,
                                date: date,
                                category: category,
                                detail: detail,
                                transactionType: transactionType,
                                account: account,
                                amount: amount)
    }
}
