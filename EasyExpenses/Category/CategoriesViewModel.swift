//
//  CategoryViewModel.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 25/09/2026.
//

import Foundation
import Combine

@MainActor
protocol CategoriesViewModel: AnyObject, ObservableObject {
    var categories: [Category] { get }
    func load() async
    func add()
    func save(_ category: Category) async
    func delete(at offsets: IndexSet) async
}

@MainActor
final class DefaultCategoriesViewModel: CategoriesViewModel {
    @Published var categories: [Category] = []
    private let repository: CategoryRepository

    init(repo: CategoryRepository) {
        self.repository = repo
        Task { await load() }
    }

    func load() async {
        if let list = try? await repository.fetchAll() {
            categories = list
        }
    }

    func add() {
        categories.append(Category(name: "New Category"))
    }

    func save(_ category: Category) async {
        try? await repository.insertOrUpdate(category)
        await load()
    }

    func delete(at offsets: IndexSet) async {
        for index in offsets { try? await repository.delete(categories[index]) }
        await load()
    }
}
