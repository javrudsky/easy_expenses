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
    var categories: [Category]
    var accounts: [Account]
    
    init(transaction: Transaction? = nil,
         crudOperation: CRUDOperation = .create,
         categories: [Category],
         accounts: [Account]) {
        self.transaction = transaction
        self.crudOperation = crudOperation
        self.categories = categories
        self.accounts = accounts
    }
}

struct TransactionFormView: View {
    var onComplete: (TransactionFormResult) -> Void
    private let cfg: TransactionFormConfig
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    
    @State private var date: Date = .now
    @State private var inCategory: Category = Category(id: UUID(), name: "", transactionType: .income)
    @State private var exCategory: Category = Category(id: UUID(), name: "", transactionType: .expense)
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
                            .accessibilityIdentifier("transaction-amount")
                    }
                    
                    if type == .income {
                        CategoryGridView(items: cfg.categories.filter { $0.transactionType == .income },
                                         value: $inCategory)
                                     .frame(maxHeight: .infinity)
                                     .frame(maxWidth: .infinity)

                    } else {
                        CategoryGridView(items: cfg.categories.filter { $0.transactionType == .expense },
                                         value: $exCategory)
                                         .frame(maxHeight: .infinity)
                                         .frame(maxWidth: .infinity)

                    }
                                            
                    VStack(alignment: .leading) {
                        Text("Description")
                        TextEditor(text: $detail)
                            .frame(height: 120)
                            .backgroundStyle(Color(.systemGray))
                            .focused($focusedField, equals: .detail)
                            .themedTextField()
                            .accessibilityIdentifier("transaction-detail")
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
                            tx.category = selectedCategory()
                            tx.detail = detail
                            tx.transactionType = type
                            tx.account = account
                            if let amount = Decimal(string: amountText) { tx.amount = amount }
                            dismissAndSend(.updated(tx))
                        } else {
                            guard let amount = Decimal(string: amountText) else { return }
                            dismissAndSend(.created(date: date,
                                                    category: selectedCategory(),
                                                    detail: detail,
                                                    type: type,
                                                    account: account,
                                                    amount: amount))
                        }
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(!isValid)
                    .accessibilityIdentifier("save-transaction")
                }
            }
            .onTapGesture {
                focusedField = nil
            }
            .onAppear { populateFromTransactionIfNeeded() }
        }
    }
    
    private func selectedCategory() -> Category {
        return type == .income ? inCategory : exCategory
    }
    
    private var isValid: Bool {
        Decimal(string: amountText) != nil
    }
    
    private func populateFromTransactionIfNeeded() {
        if let tx = cfg.transaction {
            date = Date(timeIntervalSince1970: tx.date)
            detail = tx.detail ?? ""
            type = tx.transactionType
            account = tx.account
            amountText = NSDecimalNumber(decimal: tx.amount).stringValue
        }
        inCategory = populateCategory(cfg.categories, transactionType: .income, current: inCategory)
        exCategory = populateCategory(cfg.categories, transactionType: .expense, current: exCategory)
    }
    
    private func populateCategory(_ categories: [Category], transactionType: TransactionType, current: Category) -> Category {
        let filtered = categories.filter { $0.transactionType == transactionType }
        let cat = filtered.first(where: { $0.id == current.id })
        return cat ?? filtered.first ?? current
    }
    
    private func dismissAndSend(_ result: TransactionFormResult) {
        dismiss()
        onComplete(result)
    }
}

#Preview {
    let cf = try! DefaultAppFactory(inMemory: true)
    var cat = [AppDefaults.incomeCategory, Category(name: "Food", transactionType: .income), Category(name: "Fuel", transactionType: .income), Category(name: "Rent", transactionType: .income)]
    let cfg = TransactionFormConfig(categories: [AppDefaults.incomeCategory], accounts: [])
    TransactionFormView(config: cfg, onComplete: { _ in })
}
