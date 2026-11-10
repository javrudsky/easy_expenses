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
    // SFSymbol
    var imageName: String
    var rgbColor: String
    
    @Relationship(deleteRule: .deny, inverse: \TransactionModel.account)
    var transactions: [TransactionModel]?

    init(id: UUID = UUID(), name: String, imageName: String = "creditcard.fill", rgbColor: String = "0.29, 0.52, 1.0, 1.0") {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.rgbColor = rgbColor
    }
}
