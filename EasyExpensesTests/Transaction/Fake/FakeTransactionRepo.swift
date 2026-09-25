import Foundation
import SwiftData
@testable import EasyExpenses

enum TestError: Error {
    case forced
}

actor FakeTransactionRepository: TransactionRepository {
    let modelContainer: ModelContainer
    let modelExecutor: any ModelExecutor
    private(set) var insertedOrUpdated: [Transaction] = []
    private(set) var deleted: [Transaction] = []
    var transactions: [Transaction] = []
    
    var shouldFailInsertUpdate = false
    var shouldFailFetchAll = false
    var shouldFailDelete = false
    
    init() {
        // Added only to conform ModelActor protocol
        self.modelContainer = try! DefaultAppFactory.createModelContainer(inMemory: true)
        let c = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: c)
    }
    
    func mockInsert(_ tx: [Transaction]) async {
        transactions.append(contentsOf: tx)
    }
    
    func mockGetDeleted() async -> [Transaction] {
        return deleted
    }
    
    func mockGetInsertOrUpdated() async -> [Transaction] {
        return insertedOrUpdated
    }
    
    func insertOrUpdate(_ tx: Transaction) throws {
        if shouldFailInsertUpdate {
            throw TestError.forced
        }
        if let index = transactions.firstIndex(where: { $0.id == tx.id }) {
            transactions[index] = tx
        } else {
            transactions.append(tx)
        }
        insertedOrUpdated.append(tx)
    }
    
    func fetchAll() throws -> [Transaction] {
        if shouldFailFetchAll {
            throw TestError.forced
        }
        return transactions
    }
    
    func fetchById(_ id: String) throws -> Transaction? {
        return transactions.first { $0.id == id }
    }
    
    func delete(_ tx: Transaction) throws {
        if shouldFailDelete {
            throw TestError.forced
        }
        transactions.removeAll { $0.id == tx.id }
        deleted.append(tx)
    }
}
