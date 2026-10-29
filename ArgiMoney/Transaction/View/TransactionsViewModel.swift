//
//  TransactionsViewModel.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import Foundation
import SwiftData
import Combine

@MainActor
protocol TransactionsViewModel: ObservableObject {
    var transactions: [Transaction] { get }
    var categories: [Category] { get }
    var accounts: [Account] { get }
    var showingForm: Bool { get set }
    var editingTransaction: Transaction? { get set }

    func reload() async throws
    func addExpense(using builder: TransactionBuilder) async throws
    func addIncome(using builder: TransactionBuilder) async throws
    func update(_ transaction: Transaction) async throws
    
    func delete(at offsets: IndexSet) async throws
    func reloadCategories() async
    func reloadAccounts() async
}

@MainActor
final class DefaultTransactionsViewModel: TransactionsViewModel {
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var accounts: [Account] = []
    
    @Published var showingForm = false
    @Published var editingTransaction: Transaction? = nil

    private let transactionRepo: TransactionRepository
    private let formService: TransactionFormViewService

    init(formService: TransactionFormViewService,
         dataStore: DataStore) {
        self.formService = formService
        self.transactionRepo = dataStore.transactionRepo
    }

    func reload() async throws {
        let items = try await transactionRepo.fetchAll()
        await MainActor.run {
            self.transactions = items
        }
    }

    func addExpense(using builder: TransactionBuilder) async throws {
        let tx = try builder.setting(type: .expense).build()
        try await transactionRepo.insertOrUpdate(tx)
        try await reload()
    }

    func addIncome(using builder: TransactionBuilder) async throws {
        let tx = try builder.setting(type: .income).build()
        try await transactionRepo.insertOrUpdate(tx)
        try await reload()
    }

    func update(_ transaction: Transaction) async throws {
        try await transactionRepo.insertOrUpdate(transaction)
        try await reload()
    }

    func delete(at offsets: IndexSet) async throws {
        for index in offsets {
            let tx = transactions[index]
            try await transactionRepo.delete(tx)
        }
        try await reload()
    }
    
    func reloadCategories() async {
            let items = await formService.getCategories()
            await MainActor.run {
                self.categories = items
            }
    }
    
    func reloadAccounts() async {
        let items = await formService.getAccounts()
        await MainActor.run {
            self.accounts = items
        }
    }
}

