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
}
