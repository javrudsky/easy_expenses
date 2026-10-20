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
    @Environment(\.theme) private var theme

    @State private var date: Date = .now
    @State private var category: Category = Category(id: UUID(), name: "", transactionType: .expense)
    @State private var detail: String = ""
    @State private var type: TransactionType = .expense
    @State private var account: Account = Account(id: UUID(), name: "")
    @State private var amountText: String = ""
    
    @State private var showCatList: Bool = false
    
    enum Field {
        case amount
        case detail
    }
    @FocusState private var focusedField: Field?

    init(config: TransactionFormConfig,
         onComplete: @escaping (TransactionFormResult) -> Void) {
        self.cfg = config
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("") {
                    
                    DatePicker("", selection: $date, displayedComponents: [.date])
                    TransactionTypeToggle(type: $type)
                    VStack(alignment: .leading) {
                        Text("Amount")
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .amount)
                            .themedTextField()
                    }
                    
                        CategoryGridView(items: cfg.gridCategories,
                                         value: $category) {
                            showCatList = true
                        }
                                         .frame(maxHeight: .infinity)
                                         .frame(maxWidth: .infinity)
                        
                        VStack(alignment: .leading) {
                            Text("Description")
                            TextEditor(text: $detail)
                                .frame(height: 120)
                                .backgroundStyle(Color(.systemGray))
                                .focused($focusedField, equals: .detail)
                                .themedTextField()
                        }
                    
                }
                .listRowSpacing(1)
                .listRowSeparator(.hidden)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .onTapGesture {
                focusedField = nil
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
    var cat = [AppDefaults.incomeCategory, Category(name: "Food", transactionType: .income), Category(name: "Fuel", transactionType: .income), Category(name: "Rent", transactionType: .income)]
    let cfg = TransactionFormConfig(allCategories: [AppDefaults.incomeCategory], gridCategories: cat, accounts: [])
    TransactionFormView(config: cfg, onComplete: { _ in })
}

