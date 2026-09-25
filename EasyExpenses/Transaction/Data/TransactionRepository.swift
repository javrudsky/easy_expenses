//
//  TransactionRepository.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import Foundation
import SwiftData
    

protocol TransactionRepository: ModelActor {
    func fetchAll() async throws -> [Transaction]
    func insertOrUpdate(_ transaction: Transaction) async throws
    func delete(_ transaction: Transaction) async throws
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
    
    func fetchBy(id: String) async throws -> Transaction? {
        if let obj = try getBy(id: id) {
            return mapper.toDomain(obj)
        }
        return nil
    }
    func fetchAll() async throws -> [Transaction] {
        let all: [TransactionModel] = try getAll()
        return all.map { mapper.toDomain($0) }
    }
    
    func insertOrUpdate(_ transaction: Transaction) async throws {
        
        let obj: TransactionModel? = try getBy(id: transaction.id)
        if let obj {
            obj.account = transaction.account
            obj.amount = transaction.amount
            obj.category = transaction.category
            obj.detail = transaction.detail
            obj.date = obj.date
            try await save()
        } else {
            try insert(mapper.toModel(transaction))
        }
    }
    
    func delete(_ transaction: Transaction) async throws {
        try await deleteBy(id: transaction.id)
    }
    
    func save() async throws {
        try modelContext.save()
    }
           
    @discardableResult
    func deleteBy(id: String) async throws -> TransactionModel? {
        let obj = try getBy(id: id)
        guard let obj else { return nil }
        modelContext.delete(obj)
        try modelContext.save()
        return obj
    }
    
    //MARK: Private
    private func getBy(id: String)throws -> TransactionModel? {
        let predicate = #Predicate<TransactionModel> { model in
            model.id == id
        }
        let objs = try modelContext.fetch(FetchDescriptor<TransactionModel>(predicate: predicate))
        return objs.first
    }
    
    private func getAll() throws -> [TransactionModel] {
        return try modelContext.fetch(FetchDescriptor<TransactionModel>())
    }

    private func insert(_ item: TransactionModel) throws {
        modelContext.insert(item)
        try modelContext.save()
    }
}

