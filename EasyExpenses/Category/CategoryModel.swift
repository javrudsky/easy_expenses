//
//  CategoryModel.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//
import SwiftData
import Foundation

@Model
final class CategoryModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var transactionType: String
    
    @Relationship(deleteRule: .deny, inverse: \TransactionModel.category)
    var transactions: [TransactionModel]?

    init(id: UUID = UUID(),
         name: String,
         transactionType: String) {
        self.id = id
        self.name = name
        self.transactionType = transactionType
    }
}

