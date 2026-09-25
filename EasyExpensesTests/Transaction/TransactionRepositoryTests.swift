//
//  TransactionRepositoryTests.swift
//  EasyExpensesTests
//
//  Created by Javier Avrudsky on 17/09/2026.
//

import Foundation
import SwiftData
import Testing
@testable import EasyExpenses

@Suite("TransactionRepository Contract") struct TransactionRepositoryContractTests {
    
    typealias Th = TransactionTestsHelper
    var cf: AppFactory!
    var context: ModelContext!
    let repo: SwiftDataTransactionRepository!
    
    init() async throws {
        
        repo = try await MainActor.run {
            let container = try DefaultAppFactory.createModelContainer(inMemory: true)
            return SwiftDataTransactionRepository(modelContainer: container,
                                                  transactionMapper: DefaultTransactionMapper())
        }
    }
    
    @Test("insertOrUpdate inserts when new, updates when existing")
    func insertOrUpdateBehavior() async throws {
        
        var tx = Th.createTransaction(amount: 10)
        try await repo.insertOrUpdate(tx)
        let transBef: [Transaction] = try await repo.fetchAll()
        // Update
        tx.amount = 20
        try await repo.insertOrUpdate(tx)
        
        let transAft: [Transaction] = try await repo.fetchAll()
        
        #expect(transBef.count == 1)
        #expect(transBef.first?.amount == 10)

        #expect(transAft.count == 1)
        #expect(transAft.first?.amount == 20)
    }

    @Test("fetchAll returns the current list")
    func fetchAllReturns() async throws {
        
        let list = [
            Th.createTransaction(),
            Th.createTransaction()
        ]
        
        for tx in list {
            try await repo.insertOrUpdate(tx)
        }
                
        let fetched = try await repo.fetchAll()
        #expect(fetched.map(\.id) == list.map(\.id))
    }

    @Test("delete removes from storage")
    func deleteRemoves() async throws {
        let a = Th.createTransaction()
        let b = Th.createTransaction()
        try await repo.insertOrUpdate(a)
        try await repo.insertOrUpdate(b)
        try await repo.delete(a)
        let ts = try await repo.fetchAll()
        #expect(ts.count == 1)
        #expect(ts.first?.id == b.id)
    }
}

