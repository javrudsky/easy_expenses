//
//  Category.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//

import Foundation

struct Category: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var name: String
    var transactionType: TransactionType
    // SFSymbol
    var imageName: String
    var rgbColor: String
    
    init(name: String,
         transactionType: TransactionType,
         imageName: String,
         rgbColor: String) {
        self.name = name
        self.transactionType = transactionType
        self.imageName = imageName
        self.rgbColor = rgbColor
        self.id = IdHelper.categoryId(name: name, type: transactionType)
    }
    
    init(id: UUID,
         name: String,
         transactionType: TransactionType,
         imageName: String,
         rgbColor: String) {
        self.id = id
        self.name = name
        self.transactionType = transactionType
        self.imageName = imageName
        self.rgbColor = rgbColor
    }
}
