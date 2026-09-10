//
//  Item.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
