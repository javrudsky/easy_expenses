//
//  InputRecognition.swift
//  EasyExpenses
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
    func buildTransactionFrom(text: String, defaults: TransactionDefaults) async throws -> Transaction {
        let lowText = text.lowercased().split(separator: " ")
        var detail = text
        var hasCredit = false
        var hasDebit = false
        var amount: Decimal = 0.0
        var category: String = defaults.category
        
        for word in lowText {
            let w = String(word)
            if InputWordSet.creditWords.contains(w) {
                hasCredit = true
                detail.replace(word, with: "")
            }
            if !hasCredit && InputWordSet.debitWords.contains(w) {
                hasDebit = true
                detail.replace(word, with: "")
            }
            
            if let a = Decimal(string: w) {
                amount = a
                detail.replace(word, with: "")
            }
            
            if hasCredit {
                if category == defaults.category && InputWordSet.creditCategoryWords.contains(w) {
                    category = w
                    detail.replace(word, with: "")
                }
            } else if hasDebit {
                if category == defaults.category && InputWordSet.debitCategoryWords.contains(w) {
                    category = w
                    detail.replace(word, with: "")
                }
            }
        }
       
        if hasDebit == hasCredit {
            throw ParserError.onParsing("Could not recognize transaction type")
        }
        
        let type: TransactionType = hasDebit ? .debit : .credit
        
        let builder = TransactionBuilder()
        return try builder
            .setting(amount: amount)
            .setting(detail: detail.trimmingCharacters(in: .whitespacesAndNewlines))
            .setting(date: defaults.date)
            .setting(type: type)
            .setting(account: defaults.account)
            .setting(category: category)
            .build()
    }
}
