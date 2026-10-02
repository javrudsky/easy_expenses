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
    
    var transactionType: TransactionType { get }
    var categories: [Category] { get }
    func load() async
    func add()
    func save(_ category: Category) async
    func delete(at offsets: IndexSet) async
}

@MainActor
final class DefaultCategoriesViewModel: CategoriesViewModel {
    @Published var categories: [Category] = []
    let transactionType: TransactionType
    private let repository: CategoryRepository

    init(transactionType: TransactionType,
         repo: CategoryRepository) {
        self.repository = repo
        self.transactionType = transactionType
        Task { await load() }
    }

    func load() async {
        if let list = try? await repository.fetchAll() {
            categories = list.filter { $0.transactionType == transactionType }
        }
    }

    func add() {
        categories.append(Category(name: "New Category", transactionType: transactionType))
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
