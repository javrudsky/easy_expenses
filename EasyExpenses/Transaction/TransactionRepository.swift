//
//  TransactionRepository.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import Foundation
import SwiftData

protocol TransactionRepository {
    func fetchAll() throws -> [Transaction]
    func add(_ transaction: Transaction) throws
    func delete(_ transaction: Transaction) throws
    func delete(at offsets: IndexSet, from transactions: [Transaction]) throws
    func update() throws
}

struct SwiftDataTransactionRepository: TransactionRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Transaction] {
        let descriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func add(_ transaction: Transaction) throws {
        context.insert(transaction)
        try context.save()
    }

    func delete(_ transaction: Transaction) throws {
        context.delete(transaction)
        try context.save()
    }
    
    func update() throws {
        try context.save()
    }

    func delete(at offsets: IndexSet, from transactions: [Transaction]) throws {
        for index in offsets { context.delete(transactions[index]) }
        try context.save()
    }
}
