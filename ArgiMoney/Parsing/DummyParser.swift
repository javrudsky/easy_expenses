//
//  InputRecognition.swift
//  ArgiMoney
//
//  Created by Javier Avrudsky on 14/09/2026.
//

import Foundation

nonisolated struct InputWordSet {
    static let debitWords = [
        "debit", "expense", "spending", "outflow", "payment", "withdrawal", "charge", "money out", "deduction", "purchase", "cost"
    ]

    static let creditWords = [
        "credit", "income", "earnings", "inflow", "receipt", "deposit", "payment received", "money in", "addition", "revenue", "proceeds"
    ]
    
    static let debitCategoryWords = [
        "food", "groceries", "supermarket", "restaurant", "lunch", "dinner", "takeout", "delivery", "snacks",
        "transport", "taxi", "uber", "fuel", "gas", "parking", "tolls", "bus", "train", "flight",
        "rent", "mortgage", "utilities", "electricity", "water", "internet", "phone", "insurance", "taxes", "fees",
        "health", "doctor", "pharmacy", "medicine", "dentist", "gym", "clothing", "shopping", "electronics", "furniture",
        "entertainment", "subscription", "education", "travel", "hotel", "maintenance", "repairs", "services", "gifts", "donations", "other"
    ]

    static let creditCategoryWords = [
        "salary", "wages", "paycheck", "bonus", "commission", "overtime", "freelance", "consulting", "contract", "payment",
        "sales", "revenue", "refund", "reimbursement", "cashback", "rebate", "interest", "dividend", "investment", "profit",
        "rent", "rental", "pension", "retirement", "allowance", "benefit", "grant", "scholarship", "subsidy", "compensation",
        "royalty", "licensing", "gift", "donation", "prize", "award", "inheritance", "settlement", "transfer", "deposit",
        "repayment", "loan", "advance", "resale", "dividends", "earnings", "tips", "proceeds", "redemption", "distribution", "other"
    ]
}

struct DummyInputParser: InputParser {
    // Rudimentary function to recognize transaction
    // TODO: Replace by AI
    func buildTransactionFrom(text: String,
                              categories: [Category],
                              accounts: [Account],
                              defaults: TransactionDefaults) async throws -> Transaction {
        
        let lowText = text.lowercased().split(separator: " ")
        var detail = text
        var hasCredit = false
        var hasDebit = false
        var amount: Decimal = 0.0
        var category: String?
        
        for word in lowText {
            let w = String(word)
            if InputWordSet.creditWords.contains(w) {
                hasCredit = true
                detail.replace(word, with: "")
            }
            if InputWordSet.debitWords.contains(w) {
                hasDebit = true
                detail.replace(word, with: "")
            }
            
            if let a = Decimal(string: w) {
                amount = a
                detail.replace(word, with: "")
            }
            
        }
       
        if hasDebit == hasCredit {
            throw ParserError.onParsing("Could not recognize transaction type")
        }
        
        let type: TransactionType = hasDebit ? .expense : .income
        let categoryWords = type == .expense ? InputWordSet.debitCategoryWords : InputWordSet.creditCategoryWords
        for word in lowText {
            let name = String(word)
            if category == nil && categoryWords.contains(name) {
                category = name
                detail.replace(word, with: "")
            }
        }
        let defaultCategory = type == .expense ? defaults.expenseCategory : defaults.incomeCategory
        
        let builder = TransactionBuilder()
        return try builder
            .setting(amount: amount)
            .setting(detail: detail.trimmingCharacters(in: .whitespacesAndNewlines))
            .setting(date: defaults.date)
            .setting(type: type)
            .setting(account: defaults.account)
            .setting(category: getCategory(categories: categories,
                                            name: category ?? defaultCategory.name,
                                            defaultValue: defaultCategory))
            .build()
    }
    
    private func getCategory(categories: [Category], name: String, defaultValue: Category) -> Category {
        if let c = categories.first(where: { $0.name == name }) {
            return c
        }
        return defaultValue
    }
}
