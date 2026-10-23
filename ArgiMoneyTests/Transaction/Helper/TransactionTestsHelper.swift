//
//  TransactionTestsHelper.swift
//  EasyExpensesTests
//
//  Created by Javier Avrudsky on 17/09/2026.
//

import Foundation
@testable import ArgiMoney

struct TransactionTestsHelper {
    
    static func createTransaction(id: UUID = UUID(),
                                  date: TimeInterval = Date().timeIntervalSince1970,
                                  category: String = "MyCategory",
                                  detail: String = "",
                                  transactionType: TransactionType = .expense,
                                  account: String = "MyAccount",
                                  amount: Decimal = 10) -> Transaction {
        return Transaction(id: id,
                           date: date,
                           category: Category(name: category, transactionType: transactionType),
                           detail: detail,
                           transactionType: transactionType,
                           account: Account(name: account),
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
                                       transactionType: TransactionType = .expense,
                                       account: String = "Checking",
                                       amount: Decimal = 45.67) -> TransactionModel {
        
        let catModel = DefaultCategoryMapper().toModel(Category(name: category, transactionType: transactionType))
        let accModel = DefaultAccountMapper().toModel(Account(name: account))
        
        return TransactionModel(id: id,
                                date: date,
                                detail: detail,
                                transactionType: transactionType.rawValue,
                                amount: amount,
                                category: catModel,
                                account: accModel)
    }
    
    static func getUUIDStr(_ char: String) -> String {
        if char.isEmpty {
            print("Empty")
            return ""
        }
        let c = String(char[char.startIndex])
        let p1 = String(repeating: c, count: 8)
        let p2 = String(repeating: c, count: 4)
        let p3 = String(repeating: c, count: 4)
        let p4 = String(repeating: c, count: 4)
        let p5 = String(repeating: c, count: 12)
        let uuid =  "\(p1)-\(p2)-\(p3)-\(p4)-\(p5)"
        print(uuid)
        return uuid
    }
}
