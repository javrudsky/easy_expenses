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
    @Attribute(.unique) var id: String
    var name: String

    init(id: String = UUID().uuidString, name: String) {
        self.id = id
        self.name = name
    }
}
