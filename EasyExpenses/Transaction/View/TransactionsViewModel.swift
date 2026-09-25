//
//  TransactionsViewModel.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import Foundation
import SwiftData
import Combine

protocol TransactionsViewModel: AnyObject, ObservableObject {
    var transactions: [Transaction] { get }
    var showingForm: Bool { get set }
    var editingTransaction: Transaction? { get set }

    func reload() async throws
    func addDebit(using builder: TransactionBuilder) async throws
    func addCredit(using builder: TransactionBuilder) async throws
    func update(_ transaction: Transaction) async throws
    func delete(at offsets: IndexSet) async throws
}

@MainActor
final class DefaultTransactionsViewModel: TransactionsViewModel {
    @Published var transactions: [Transaction] = []
    @Published var showingForm = false
    @Published var editingTransaction: Transaction? = nil

    private let transactionRepo: TransactionRepository

    init(repo: TransactionRepository) {
        self.transactionRepo = repo
    }

    func reload() async throws {
        let items = try await transactionRepo.fetchAll()
        await MainActor.run {
            self.transactions = items
        }
    }

    func addDebit(using builder: TransactionBuilder) async throws {
        let tx = try builder.setting(type: .debit).build()
        try await transactionRepo.insertOrUpdate(tx)
        try await reload()
    }

    func addCredit(using builder: TransactionBuilder) async throws {
        let tx = try builder.setting(type: .credit).build()
        try await transactionRepo.insertOrUpdate(tx)
        try await reload()
    }

    func update(_ transaction: Transaction) async throws {
        try await transactionRepo.insertOrUpdate(transaction)
        try await reload()
    }

    func delete(at offsets: IndexSet) async throws {
        for index in offsets {
            let tx = await transactions[index]
            try await transactionRepo.delete(tx)
        }
        try await reload()
    }
}

