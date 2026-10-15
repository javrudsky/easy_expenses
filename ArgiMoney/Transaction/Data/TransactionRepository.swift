//
//  TransactionRepository.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import Foundation
import SwiftData
    

struct TransactionTotals {
    let income: Decimal
    let expenses: Decimal
    var result: Decimal {
        return income - expenses
    }
}

protocol TransactionRepository: ModelActor {
    func fetchAll() async throws -> [Transaction]
    func fetchBy(id: UUID) async throws -> Transaction?
    func insertOrUpdate(_ transaction: Transaction) async throws
    func delete(_ transaction: Transaction) async throws
    func fetchTotals(from: TimeInterval, to: TimeInterval) async throws -> TransactionTotals
    func fetch(from: TimeInterval, to: TimeInterval) async throws -> [Transaction]
}

actor SwiftDataTransactionRepository: TransactionRepository {
    
    nonisolated let mapper: TransactionMapper
    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor
    
    init(modelContainer: ModelContainer, transactionMapper: TransactionMapper) {
        self.modelContainer = modelContainer
        self.mapper = transactionMapper
        let c = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: c)
    }
    
    func fetchBy(id: UUID) async throws -> Transaction? {
        if let obj = try getBy(id: id) {
            return mapper.toDomain(obj)
        }
        return nil
    }
    func fetchAll() async throws -> [Transaction] {
        let all: [TransactionModel] = try getAll()
        return all.map { mapper.toDomain($0) }
    }
    
    func fetchTotals(from: TimeInterval, to: TimeInterval) async throws -> TransactionTotals {
        let items = try get(from: from, to: to)
        return TransactionTotals(income: sumAmount(items, transactionType: .income),
                                 expenses: sumAmount(items, transactionType: .expense))
    }
    
    func fetch(from: TimeInterval, to: TimeInterval) async throws -> [Transaction] {
        return try get(from: from, to: to).map { mapper.toDomain($0) }
    }
    
    func insertOrUpdate(_ transaction: Transaction) async throws {
        // Resolve or create related models
        let catModel: CategoryModel
        if let existingCat: CategoryModel = try getCategoryBy(id: transaction.category.id) {
            existingCat.name = transaction.category.name
            catModel = existingCat
        } else {
            catModel = CategoryModel(id: transaction.category.id, name: transaction.category.name, transactionType: transaction.transactionType.rawValue)
            modelContext.insert(catModel)
        }

        let accModel: AccountModel
        if let existingAcc: AccountModel = try getAccountBy(id: transaction.account.id) {
            existingAcc.name = transaction.account.name
            accModel = existingAcc
        } else {
            accModel = AccountModel(id: transaction.account.id, name: transaction.account.name)
            modelContext.insert(accModel)
        }

        if let obj: TransactionModel = try getBy(id: transaction.id) {
            obj.date = transaction.date
            obj.detail = transaction.detail
            obj.transactionType = transaction.transactionType.rawValue
            obj.amount = transaction.amount
            obj.category = catModel
            obj.account = accModel
            try await save()
        } else {
            let model = mapper.toModel(transaction, categoryModel: catModel, accountModel: accModel)
            try insert(model)
        }
    }
    
    func delete(_ transaction: Transaction) async throws {
        try await deleteBy(id: transaction.id)
    }
    
    func save() async throws {
        try modelContext.save()
    }
           
    @discardableResult
    func deleteBy(id: UUID) async throws -> TransactionModel? {
        let obj = try getBy(id: id)
        guard let obj else { return nil }
        modelContext.delete(obj)
        try modelContext.save()
        return obj
    }
    
    //MARK: Private
    private func sumAmount(_ items: [TransactionModel], transactionType: TransactionType) -> Decimal {
        return items.filter { $0.transactionType == transactionType.rawValue }
            .map { $0.amount }
            .reduce(0) { $0 + $1 }
    }
    
    private func getBy(id: UUID) throws -> TransactionModel? {
        let predicate = #Predicate<TransactionModel> { model in
            model.id == id
        }
        let objs = try modelContext.fetch(FetchDescriptor<TransactionModel>(predicate: predicate))
        return objs.first
    }
    
    private func getAll() throws -> [TransactionModel] {
        return try modelContext.fetch(FetchDescriptor<TransactionModel>())
    }
    
    private func get(from: TimeInterval, to: TimeInterval) throws -> [TransactionModel] {
        let predicate = #Predicate<TransactionModel> { model in
            model.date >= from && model.date <= to
        }
        return try modelContext.fetch(FetchDescriptor<TransactionModel>(predicate: predicate))
    }
    

    private func insert(_ item: TransactionModel) throws {
        modelContext.insert(item)
        try modelContext.save()
    }
    
    private func getCategoryBy(id: UUID) throws -> CategoryModel? {
        let predicate = #Predicate<CategoryModel> { model in model.id == id }
        let objs = try modelContext.fetch(FetchDescriptor<CategoryModel>(predicate: predicate))
        return objs.first
    }

    private func getAccountBy(id: UUID) throws -> AccountModel? {
        let predicate = #Predicate<AccountModel> { model in model.id == id }
        let objs = try modelContext.fetch(FetchDescriptor<AccountModel>(predicate: predicate))
        return objs.first
    }
    
}

