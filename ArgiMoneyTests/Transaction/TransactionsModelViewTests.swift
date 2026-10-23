//
//  TransactionsModelViewTests.swift
//  EasyExpensesTests
//
//  Created by Javier Avrudsky on 17/09/2026.
//
import Foundation
import Testing
@testable import ArgiMoney

@Suite("TransactionsViewModel") struct TransactionsViewModelTests {
    
    typealias Th = TransactionTestsHelper
   
    func createTxBuilder() -> TransactionBuilder {
        
        return TransactionBuilder()
            .setting(account: Account(name: "Acc"))
            .setting(date: 111111.0)
            .setting(detail: "")
            .setting(category: Category(name: "mycat", transactionType: .income))
            .setting(amount: 1.20)
    }

    @MainActor
    func createViewModel(repo: FakeTransactionRepository) -> DefaultTransactionsViewModel {
        let categoryRepo = FakeCategoryRepository()
        let accountRepo = FakeAccountRepository()
        let dataStore = DataStore(
            transactionRepo: repo,
            categoryRepo: categoryRepo,
            accountRepo: accountRepo
        )
        let formService = DefaultTransactionFormViewService(dataStore: dataStore)
        return DefaultTransactionsViewModel(formService: formService, dataStore: dataStore)
    }
    @MainActor
    @Test("reload loads transactions from repository")
    func reloadLoads() async throws {
        let repo = FakeTransactionRepository()
        await repo.mockInsert( [Th.createTransaction(), Th.createTransaction(transactionType: .income)])
        let vm = createViewModel(repo: repo)
        try await vm.reload()
        // reload is called in init; ensure state reflects repo
        #expect(vm.transactions.count == 2)
    }

    @MainActor
    @Test("addExpense creates and reloads list")
    func addExpenseReloads() async throws {
        let repo = FakeTransactionRepository()
        let vm = createViewModel(repo: repo)
        let builder = createTxBuilder()
        try await vm.addExpense(using: builder)
        
        let insOrUpd = await repo.mockGetInsertOrUpdated()
        #expect(insOrUpd.count == 1)
        #expect(vm.transactions.count == 1)
        #expect(vm.transactions.first?.isExpense == true)
    }

    @MainActor
    @Test("addIncome creates and reloads list")
    func addIncomeReloads() async throws {
        let repo = FakeTransactionRepository()
        let vm = createViewModel(repo: repo)
        
        let builder = createTxBuilder()
        try await vm.addIncome(using: builder)
        
        let insOrUpd = await repo.mockGetInsertOrUpdated()
        #expect(insOrUpd.count == 1)
        #expect(vm.transactions.count == 1)
        #expect(vm.transactions.first?.isExpense == false)
    }

    @MainActor
    @Test("update forwards to repo and reloads")
    func updateReloads() async throws {
        let repo = FakeTransactionRepository()
        let initial = Th.createTransaction(amount: 5.0)
        await repo.mockInsert([initial])
        let vm = createViewModel(repo: repo)
        var updated = initial
        updated.amount = 99.0
        try await vm.update(updated)
        let insOrUpd = await repo.mockGetInsertOrUpdated()
        #expect(insOrUpd.contains(where: { $0.id == updated.id }))
        #expect(vm.transactions.first?.amount == 99)
    }
}
