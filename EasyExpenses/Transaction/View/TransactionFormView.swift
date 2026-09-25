//
//  TransactionFormView.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import SwiftUI

enum TransactionFormResult {
    case created(date: Date,
                 category: String,
                 detail: String,
                 type: TransactionType,
                 account: String,
                 amount: Decimal)
    case updated(Transaction)
    case cancelled
}

enum CRUDOperation {
    case create
    case update
    case delete
}

struct TransactionFormView: View {
    var crudOperation: CRUDOperation
    var transaction: Transaction?
    var onComplete: (TransactionFormResult) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = .now
    @State private var category: String = ""
    @State private var detail: String = ""
    @State private var type: TransactionType = .debit
    @State private var account: String = ""
    @State private var amountText: String = ""

    init(crudOperation: CRUDOperation = .update,
         transaction: Transaction? = nil,
         onComplete: @escaping (TransactionFormResult) -> Void) {
        self.crudOperation = transaction == nil ? .create : crudOperation
        self.transaction = transaction
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { t in
                            Text(t == .debit ? "Debit" : "Credit").tag(t)
                        }
                    }
                    TextField("Category", text: $category)
                    TextField("Description", text: $detail)
                    TextField("Account", text: $account)
                }
                Section("Amount") {
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(transaction == nil ? "New Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismissAndSend(.cancelled) }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(crudOperation == .update ? "Add" : "Save") {
                        if crudOperation == .update, var tx = transaction {
                            tx.date = date.timeIntervalSince1970
                            tx.category = category
                            tx.detail = detail
                            tx.transactionType = type
                            tx.account = account
                            if let amount = Decimal(string: amountText) { tx.amount = amount }
                            dismissAndSend(.updated(tx))
                        } else {
                            guard let amount = Decimal(string: amountText) else { return }
                            dismissAndSend(.created(date: date, category: category, detail: detail, type: type, account: account, amount: amount))
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear { populateFromTransactionIfNeeded() }
        }
    }

    private var isValid: Bool {
        !category.isEmpty && !account.isEmpty && Decimal(string: amountText) != nil
    }

    private func populateFromTransactionIfNeeded() {
        guard let tx = transaction else { return }
        date = Date(timeIntervalSince1970: tx.date)
        category = tx.category
        detail = tx.detail ?? ""
        type = tx.transactionType
        account = tx.account
        amountText = NSDecimalNumber(decimal: tx.amount).stringValue
    }

    private func dismissAndSend(_ result: TransactionFormResult) {
        dismiss()
        onComplete(result)
    }
}

#Preview {
    TransactionFormView { _ in }
}
