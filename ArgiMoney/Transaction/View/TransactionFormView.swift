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
    @State private var inCategory: Category = AppDefaults.incomeCategory
    @State private var exCategory: Category = AppDefaults.expenseCategory
    
    @State private var detail: String = ""
    @State private var type: TransactionType = .expense
    @State private var account: Account = Account(id: UUID(), name: "", imageName: "creditcard.fill", rgbColor: "0.29, 0.52, 1.0, 1.0")
    @State private var amountText: String = ""
    
    @State private var showCatList: Bool = false
    @State private var isPresented: Bool
    
    enum Field {
        case amount
        case detail
    }
    @FocusState private var focusedField: Field?
    
    init(config: TransactionFormConfig,
         isPresented: Bool = false,
         onComplete: @escaping (TransactionFormResult) -> Void) {
        self.cfg = config
        self.onComplete = onComplete
        self.isPresented = isPresented
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("") {
                    
                    DatePicker("", selection: $date, displayedComponents: [.date])
                    TransactionTypeToggle(type: $type)
                    VStack(alignment: .leading) {
                        Text("Amount")
                        HStack(spacing: 4) {
                            // Static currency code that cannot be deleted or selected
                            Text("USD")
                                .foregroundColor(.secondary)
                                .font(.body)
                                .bold()
                            
                            TextField("0.00", text: $amountText)
                                .keyboardType(.decimalPad) // Shows numeric keyboard with decimal point
                                .focused($focusedField, equals: .amount)
                                .themedTextField()
                                .accessibilityIdentifier("transaction-amount")
                                .onChange(of: amountText) { oldValue, newValue in
                                    amountText = filterInvalidCurrencyCharacters(newValue)
                                }
                        }
                        .padding()
                    }
                    
                    if type == .income {
                        CategoryGridView(items: cfg.categories.filter { $0.transactionType == .income },
                                         value: $inCategory)
                        .frame(maxHeight: .infinity)
                        .frame(maxWidth: .infinity)
                        .padding(.all, 0.0)
                        
                    } else {
                        CategoryGridView(items: cfg.categories.filter { $0.transactionType == .expense },
                                         value: $exCategory)
                        .frame(maxHeight: .infinity)
                        .frame(maxWidth: .infinity)
                        .padding(.all, 0.0)
                        
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
                if isPresented {
                    ToolbarItem(placement: .topBarLeading) {
                        Button{ dismissAndSend(.cancelled) }
                        label: {
                            Image(systemName: "xmark")
                        }
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
                            // Necessary to create a decimal nummber when using "," as separator
                            if let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) {
                                tx.amount = amount
                            }
                            dismissAndSend(.updated(tx))
                        } else {
                            guard let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) else { return }
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
        return Decimal(string: amountText) != nil
    }
    
    private func populateFromTransactionIfNeeded() {
        if let tx = cfg.transaction {
            date = Date(timeIntervalSince1970: tx.date)
            detail = tx.detail ?? ""
            type = tx.transactionType
            account = tx.account
            let grpSep = Locale.current.groupingSeparator ?? ","
            amountText = tx.amount.formatted().replacingOccurrences(of: grpSep, with: "")
            inCategory = populateCategory(cfg.categories, transactionType: .income, current: tx.category)
            exCategory = populateCategory(cfg.categories, transactionType: .expense, current: tx.category)
        } else {
            inCategory = populateCategory(cfg.categories, transactionType: .income, current: AppDefaults.incomeCategory)
            exCategory = populateCategory(cfg.categories, transactionType: .expense, current: AppDefaults.expenseCategory)
        }
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
    
    
    private func filterInvalidCurrencyCharacters(_ input: String) -> String {
        let sep = Locale.current.decimalSeparator ?? "."
        let sepChar = Character(sep)
        // 1. Allow only numbers and the local decimal separator (dot or comma)
        let filtered = input.filter { $0.isNumber || $0 == sepChar }

        // 2. Prevent multiple decimal points
        let components = filtered.components(separatedBy: CharacterSet(charactersIn: sep))
        if components.count > 2 {
            // Keep only the first part and the second part
            return "\(components[0])\(sep)\(components[1])"
        }
        
        // 3. Limit to exactly 2 decimal places maximum
        if components.count == 2, components[1].count > 2 {
            let cents = String(components[1].prefix(2))
            return "\(components[0])\(sep)\(cents)"
        }
        
        return filtered
    }
}

#Preview {
    let cf = try! DefaultAppFactory(inMemory: true)
    var cat = [AppDefaults.incomeCategory, Category(name: "Food", transactionType: .income, imageName: "fork.knife", rgbColor: "1.0, 0.0, 0.0, 1.0"), Category(name: "Fuel", transactionType: .income, imageName: "fuelpump.fill", rgbColor: "1.0, 0.65, 0.0, 1.0"), Category(name: "Rent", transactionType: .income, imageName: "house.fill", rgbColor: "0.29, 0.56, 0.89, 1.0")]
    let cfg = TransactionFormConfig(categories: [AppDefaults.incomeCategory], accounts: [])
    TransactionFormView(config: cfg, onComplete: { _ in })
}
