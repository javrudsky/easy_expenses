//
//  TransactionsViewModel.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import Foundation
import SwiftData
import Combine

protocol TransactionsViewModelProtocol: AnyObject, ObservableObject {
    var transactions: [Transaction] { get }
    var showingForm: Bool { get set }
    var editingTransaction: Transaction? { get set }

    func reload()
    func addDebit(using builder: TransactionBuilder)
    func addCredit(using builder: TransactionBuilder)
    func update(_ transaction: Transaction)
    func delete(at offsets: IndexSet)
}

@MainActor
final class TransactionsViewModel: TransactionsViewModelProtocol {
    @Published var transactions: [Transaction] = []
    @Published var showingForm = false
    @Published var editingTransaction: Transaction? = nil

    private let transactionRepo: TransactionRepository

    init(repo: TransactionRepository) {
        self.transactionRepo = repo
        reload()
    }

    func reload() {
        do {
            transactions = try transactionRepo.fetchAll()
        } catch {
            print("Failed to fetch transactions: \(error)")
        }
    }

    func addDebit(using builder: TransactionBuilder) {
        do {
            let tx = try builder.setting(type: .debit).build()
            try transactionRepo.add(tx)
            reload()
        } catch {
            print("Failed to add debit transaction: \(error)")
        }
    }

    func addCredit(using builder: TransactionBuilder) {
        do {
            let tx = try builder.setting(type: .credit).build()
            try transactionRepo.add(tx)
            reload()
        } catch {
            print("Failed to add credit transaction: \(error)")
        }
    }

    func update(_ transaction: Transaction) {
        do {
            try transactionRepo.update()
            reload()
        } catch {
            print("Failed to update transaction: \(error)")
        }
    }

    func delete(at offsets: IndexSet) {
        do {
            try transactionRepo.delete(at: offsets, from: transactions)
            reload()
        } catch {
            print("Failed to delete transactions: \(error)")
        }
    }
}
