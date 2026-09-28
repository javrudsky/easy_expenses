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
    var useAccounts: Bool = false
    var onComplete: (TransactionFormResult) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = .now
    @State private var category: Category
    @State private var detail: String = ""
    @State private var type: TransactionType = .debit
    @State private var account: String = ""
    @State private var amountText: String = ""
    private var categories: [Category]

    init(crudOperation: CRUDOperation = .update,
         transaction: Transaction? = nil,
         onComplete: @escaping (TransactionFormResult) -> Void) {
        self.crudOperation = transaction == nil ? .create : crudOperation
        self.transaction = transaction
        self.onComplete = onComplete
        self.categories = InputWordSet.debitCategoryWords[..<9].map { Category(name: $0)}
        self.category = self.categories[0]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("") {
                    TransactionTypeToggle(type: $type)
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                    //TextField("Category", text: $category)
                    CategoryGridView(items: categories , value: category)
                    if useAccounts {
                        TextField("Account", text: $account)
                    }
                    Spacer()
                    HStack {
                        Text("Amount")
                        TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                       
                    }
                    TextField("Description", text: $detail)
                }
            }
            .navigationTitle(transaction == nil ? "New Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button{ dismissAndSend(.cancelled) }
                    label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if crudOperation == .update, var tx = transaction {
                            tx.date = date.timeIntervalSince1970
                            tx.category = category.name
                            tx.detail = detail
                            tx.transactionType = type
//                            tx.account = account
                            tx.account = "other"
                            if let amount = Decimal(string: amountText) { tx.amount = amount }
                            dismissAndSend(.updated(tx))
                        } else {
                            guard let amount = Decimal(string: amountText) else { return }
                            dismissAndSend(.created(date: date, category: category.name, detail: detail, type: type, account: account, amount: amount))
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear { populateFromTransactionIfNeeded() }
        }
    }

    private var isValid: Bool {
        !account.isEmpty && Decimal(string: amountText) != nil
    }

    private func populateFromTransactionIfNeeded() {
        guard let tx = transaction else { return }
        date = Date(timeIntervalSince1970: tx.date)
        //category = tx.category
        if let c = categories.first(where: { $0.name == tx.category }) {
            print("found cat")
            category = c
        } else {
            print(" to 0")
            category = categories[0]
        }
        detail = tx.detail ?? ""
        type = tx.transactionType
        account = tx.account
        account = "other"
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

