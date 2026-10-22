//
//  FakeRepos.swift
//  ArgiMoneyTests
//
//  Created by Javier Avrudsky on 21/10/2026.
//

import Foundation
import SwiftData
@testable import ArgiMoney

actor FakeCategoryRepository: CategoryRepository {
    
    let modelContainer: ModelContainer = try! DefaultAppFactory.createModelContainer(inMemory: true)
    nonisolated let modelExecutor: any ModelExecutor

    var categoriesById: [UUID: ArgiMoney.Category] = [:]

    init() {
        let c = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: c)
    }

    func fetchAll() async throws -> [ArgiMoney.Category] {
        return Array(categoriesById.values)
    }
    
    func insertOrUpdate(_ category: ArgiMoney.Category) async throws {
        categoriesById[category.id] = category
    }
    
    func insert(_ categories: [ArgiMoney.Category]) async {
        for category in categories {
            categoriesById[category.id] = category
        }
    }
    
    func delete(_ category: ArgiMoney.Category) async throws {
        categoriesById.removeValue(forKey: category.id)
    }

    func fetchBy(id: UUID) async throws -> ArgiMoney.Category? {
        return categoriesById[id]
    }

}

actor FakeAccountRepository: AccountRepository {
    let modelContainer: ModelContainer = try! DefaultAppFactory.createModelContainer(inMemory: true)
    nonisolated let modelExecutor: any ModelExecutor

    
    var accountsById: [UUID: Account] = [:]

    init() {
        let c = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: c)
    }

    func fetchAll() async throws -> [Account] {
        return Array(accountsById.values)
    }
    
    func insertOrUpdate(_ account: Account) async throws {
        accountsById[account.id] = account
    }
    
    func delete(_ account: Account) async throws {
        accountsById.removeValue(forKey: account.id)
    }
    
    func fetchBy(id: UUID) async throws -> Account? {
        return accountsById[id]
    }    
}
