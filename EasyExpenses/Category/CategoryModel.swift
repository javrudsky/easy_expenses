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

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
