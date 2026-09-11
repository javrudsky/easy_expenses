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
final class TransactionsViewModel: ObservableObject {
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

    func add(fields: [String: Any]) {
        // Extract values with minimal coupling for testability
        let date = (fields["date"] as? Date) ?? .now
        guard let category = fields["category"] as? String, !category.isEmpty else { return }
        guard let detail = fields["detail"] as? String else { return }
        guard let account = fields["account"] as? String, !account.isEmpty else { return }

        let type: TransactionType
        if let t = fields["type"] as? TransactionType {
            type = t
        } else if let raw = fields["type"] as? String, let mapped = TransactionType(rawValue: raw) {
            type = mapped
        } else {
            type = .debit
        }

        var amount: Decimal?
        if let dec = fields["amount"] as? Decimal {
            amount = dec
        } else if let str = fields["amount"] as? String, let dec = Decimal(string: str) {
            amount = dec
        }
        guard let finalAmount = amount else { return }

        let new = Transaction(date: date, category: category, detail: detail, transactionType: type, account: account, amount: finalAmount)
        do {
            try transactionRepo.add(new)
            reload()
        } catch {
            print("Failed to add transaction: \(error)")
        }
    }

    func update(_ transaction: Transaction) {
        do {
            try context.save()
            reload()
        } catch {
            print("Failed to update transaction: \(error)")
        }
    }

    func delete(at offsets: IndexSet) {
        do {
            try repository.delete(at: offsets, from: transactions)
            reload()
        } catch {
            print("Failed to delete transactions: \(error)")
        }
    }
}
