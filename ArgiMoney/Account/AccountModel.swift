//
//  AccountModel.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//

import Foundation
import SwiftData

@Model
final class AccountModel {
    @Attribute(.unique) var id: UUID
    var name: String
    
    @Relationship(deleteRule: .deny, inverse: \TransactionModel.account)
    var transactions: [TransactionModel]?

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
