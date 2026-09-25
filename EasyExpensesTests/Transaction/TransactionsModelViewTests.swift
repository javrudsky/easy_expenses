//
//  TransactionsModelViewTests.swift
//  EasyExpensesTests
//
//  Created by Javier Avrudsky on 17/09/2026.
//
import Foundation
import Testing
@testable import EasyExpenses

@Suite("TransactionsViewModel") struct TransactionsViewModelTests {
    
    typealias Th = TransactionTestsHelper
   
    func createTxBuilder() -> TransactionBuilder {
        
        return TransactionBuilder()
            .setting(account: "Acc")
            .setting(date: 111111.0)
            .setting(detail: "")
            .setting(category: "mycat")
            .setting(amount: 1.20)
    }
    @MainActor
    @Test("reload loads transactions from repository")
    func reloadLoads() async throws {
        let repo = FakeTransactionRepository()
        await repo.mockInsert( [Th.createTransaction(), Th.createTransaction(transactionType: .credit)])
        let vm = DefaultTransactionsViewModel(repo: repo)
        try await vm.reload()
        // reload is called in init; ensure state reflects repo
        #expect(vm.transactions.count == 2)
    }

    @MainActor
    @Test("addDebit creates and reloads list")
    func addDebitReloads() async throws {
        let repo = FakeTransactionRepository()
        let vm = DefaultTransactionsViewModel(repo: repo)
        let builder = createTxBuilder()
        try await vm.addDebit(using: builder)
        
        let insOrUpd = await repo.mockGetInsertOrUpdated()
        #expect(insOrUpd.count == 1)
        #expect(vm.transactions.count == 1)
        #expect(vm.transactions.first?.isDebit == true)
    }

    @MainActor
    @Test("addCredit creates and reloads list")
    func addCreditReloads() async throws {
        let repo = FakeTransactionRepository()
        let vm = DefaultTransactionsViewModel(repo: repo)
        
        let builder = createTxBuilder()
        try await vm.addCredit(using: builder)
        
        let insOrUpd = await repo.mockGetInsertOrUpdated()
        #expect(insOrUpd.count == 1)
        #expect(vm.transactions.count == 1)
        #expect(vm.transactions.first?.isDebit == false)
    }

    @MainActor
    @Test("update forwards to repo and reloads")
    func updateReloads() async throws {
        let repo = FakeTransactionRepository()
        let initial = Th.createTransaction(amount: 5.0)
        await repo.mockInsert([initial])
        let vm = DefaultTransactionsViewModel(repo: repo)
        var updated = initial
        updated.amount = 99.0
        try await vm.update(updated)
        let insOrUpd = await repo.mockGetInsertOrUpdated()
        #expect(insOrUpd.contains(where: { $0.id == updated.id }))
        #expect(vm.transactions.first?.amount == 99)
    }
}
