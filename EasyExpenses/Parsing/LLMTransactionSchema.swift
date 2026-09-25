//
//  LLMTransactionSchema.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 19/09/2026.
//

import Foundation
import FoundationModels

struct LLMTransactionSchema {
    
    static func transactionSchema(categories: [String],
                           accounts: [String]) -> DynamicGenerationSchema {
        
        return DynamicGenerationSchema(
            name: "GeneratedTransaction",
            description: "Structured information extracted from a financial transaction",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "category",
                    description: "The category that best describes the transaction.",
                    schema: DynamicGenerationSchema(
                        name: "category",
                        anyOf: categories
                    )
                ),
                
                DynamicGenerationSchema.Property(
                    name: "detail",
                    description: "A short description of the purpose of the transaction, such as groceries, dinner, fuel, or a doctor's appointment.",
                    schema: DynamicGenerationSchema(type: String.self)
                ),
                
                DynamicGenerationSchema.Property(
                    name: "transactionType",
                    description: "The transaction type. Use 'debit' when money was spent or paid, and 'credit' when money was received.",
                    schema: DynamicGenerationSchema(
                        name: "transactionType",
                        anyOf: ["debit", "credit"]
                    )
                ),
                
                DynamicGenerationSchema.Property(
                    name: "account",
                    description: "The account or payment method used for the transaction.",
                    schema: DynamicGenerationSchema(
                        name: "account",
                        anyOf: accounts
                    )
                ),
                
                DynamicGenerationSchema.Property(
                    name: "amount",
                    description: "The monetary amount of the transaction as a numeric value, without currency symbols.",
                    schema: DynamicGenerationSchema(type: Decimal.self)
                )
            ]
        )
    }
}

// MARK: - LLM Generable transaction

struct GeneratedTransaction: Sendable, Decodable {
    
    var category: String?
    var detail: String?
    var transactionType: String
    var account: String?
    var amount: Decimal
}
