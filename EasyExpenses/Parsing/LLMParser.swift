//
//  LLMModel.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 19/09/2026.
//
import Foundation
import FoundationModels

struct LLMParser: InputParser {
    
    
    func buildTransactionFrom(text: String, defaults: TransactionDefaults) async throws -> Transaction {
        var categories: [String] = []
        categories.append(contentsOf: InputWordSet.creditCategoryWords)
        categories.append(contentsOf: InputWordSet.debitCategoryWords)
        let accounts = ["Cash", "Galicia", "Mercado Pago"]
        
        print("About to parse text \(text) in LLM parser")
        
        let session = LanguageModelSession(model: .default)
        let txSchema = LLMTransactionSchema.transactionSchema(categories: categories,
                                                                accounts: accounts)
        let schema: GenerationSchema
        do {
            schema = try GenerationSchema(root: txSchema, dependencies: [])
        } catch {
            throw ParserError.onParsing("Error generating schema: \(error)")
        }
        
        // Generate a response and decode into our model
        do {
            let response = try await session.respond(to: text, schema: schema)
            let data = Data(response.content.jsonString.utf8)
            let decoder = JSONDecoder()
            let tx = try decoder.decode(GeneratedTransaction.self, from: data)
            guard let txType = TransactionType(rawValue: tx.transactionType) else {
                throw ParserError.onParsing("Could not get transaction type from LLM")
            }
            return Transaction(id: UUID().uuidString,
                               date: defaults.date,
                               category: tx.category ?? defaults.category,
                               transactionType: txType,
                               account: tx.account ?? defaults.account,
                               amount: tx.amount)
        } catch {
            throw ParserError.onParsing("Couldn't decode data from LLM: \(error)")
        }
    }
}
