//
//  TransactionFormView.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 10/09/2026.
//

import SwiftUI

enum TransactionFormResult {
    case created(date: Date,
                 category: Category,
                 detail: String,
                 type: TransactionType,
                 account: Account,
                 amount: Decimal)
    case updated(Transaction)
    case cancelled
}

enum CRUDOperation {
    case create
    case update
    case delete
}

struct TransactionFormConfig {
    var transaction: Transaction?
    var crudOperation: CRUDOperation
    var allCategories: [Category]
    var gridCategories: [Category]
    var accounts: [Account]
    
    init(transaction: Transaction? = nil,
         crudOperation: CRUDOperation = .create,
         allCategories: [Category],
         gridCategories: [Category],
         accounts: [Account]) {
        self.transaction = transaction
        self.crudOperation = crudOperation
        self.allCategories = allCategories
        self.gridCategories = gridCategories
        self.accounts = accounts
    }
}

struct TransactionFormView: View {
    var onComplete: (TransactionFormResult) -> Void
    private let cfg: TransactionFormConfig

    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = .now
    @State private var category: Category = Category(id: UUID(), name: "", transactionType: .expense)
    @State private var detail: String = ""
    @State private var type: TransactionType = .expense
    @State private var account: Account = Account(id: UUID(), name: "")
    @State private var amountText: String = ""
    
    
    @State private var showCatList: Bool = false

    init(config: TransactionFormConfig,
         onComplete: @escaping (TransactionFormResult) -> Void) {
        self.cfg = config
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            Form {
                
                Section("") {
                    Button ("Show") {
                        showCatList.toggle()
                    }
                        TransactionTypeToggle(type: $type)
                        DatePicker("Date", selection: $date, displayedComponents: [.date])
                        
                        ZStack {
                            CategoryGridView(items: cfg.gridCategories, value: $category)
                            Text("cat: \(category.name)").backgroundStyle(.defaultFail)
                            if showCatList {
                                ListOfValuesView(values: cfg.allCategories.map { LovValue(id: $0.id, name: $0.name)},
                                                 name: \LovValue.name) { selCat in
                                    print(selCat.name)
                                    category = cfg.allCategories.first { $0.id == selCat.id } ?? category
                                    print("new cat name \(category.name)")
                                    showCatList = false
                                }
                            }
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
            .navigationTitle(cfg.transaction == nil ? "New Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button{ dismissAndSend(.cancelled) }
                    label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if cfg.crudOperation == .update, var tx = cfg.transaction {
                            tx.date = date.timeIntervalSince1970
                            tx.category = category
                            tx.detail = detail
                            tx.transactionType = type
                            tx.account = account
                            if let amount = Decimal(string: amountText) { tx.amount = amount }
                            dismissAndSend(.updated(tx))
                        } else {
                            guard let amount = Decimal(string: amountText) else { return }
                            dismissAndSend(.created(date: date,
                                                    category: category,
                                                    detail: detail,
                                                    type: type,
                                                    account: account,
                                                    amount: amount))
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
        Decimal(string: amountText) != nil
    }

    private func populateFromTransactionIfNeeded() {
        if let tx = cfg.transaction {
            date = Date(timeIntervalSince1970: tx.date)
            category = cfg.allCategories.first(where: { $0.id == tx.category.id }) ?? cfg.allCategories.first ?? category
            detail = tx.detail ?? ""
            type = tx.transactionType
            account = tx.account
            amountText = NSDecimalNumber(decimal: tx.amount).stringValue
        } else {
            category = cfg.allCategories.first ?? category
            account = cfg.accounts.first ?? account
        }
    }

    private func dismissAndSend(_ result: TransactionFormResult) {
        dismiss()
        onComplete(result)
    }
}

#Preview {
    let cf = try! DefaultAppFactory(inMemory: true)
    var cat = [AppDefaults.incomeCategory, Category(name: "Food", transactionType: .income), Category(name: "Fuel", transactionType: .income)]
    let cfg = TransactionFormConfig(allCategories: [AppDefaults.incomeCategory], gridCategories: cat, accounts: [])
    TransactionFormView(config: cfg, onComplete: { _ in })
}
