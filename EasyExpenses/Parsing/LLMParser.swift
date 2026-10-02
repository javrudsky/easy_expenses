//
//  LLMModel.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 19/09/2026.
//
import Foundation
import FoundationModels

struct LLMParser: InputParser {
    
    
    func buildTransactionFrom(text: String,
                              categories: [Category],
                              accounts: [Account],
                              defaults: TransactionDefaults) async throws -> Transaction {
        
        //let accounts = ["Cash", "Galicia", "Mercado Pago"]
        
        print("About to parse text \(text) in LLM parser")
        
        let session = LanguageModelSession(model: .default)
        let txSchema = LLMTransactionSchema.transactionSchema(categories: categories.map { $0.name },
//        let txSchema = LLMTransactionSchema.transactionSchema(categories: InputWordSet.creditCategoryWords,
                                                              accounts: accounts.map {$0.name })
        let schema: GenerationSchema
        do {
            schema = try GenerationSchema(root: txSchema, dependencies: [])
        } catch {
            throw ParserError.onParsing("Error generating schema: \(error)")
        }
        
        // Generate a response and decode into our model
        do {
            print("Previous model")
            let response = try await session.respond(to: text, schema: schema)
            
            print("response from model: \(response)")
            let data = Data(response.content.jsonString.utf8)
            print("Data from model: \(data)")
            let decoder = JSONDecoder()
            let tx = try decoder.decode(GeneratedTransaction.self, from: data)
            guard let txType = TransactionType(rawValue: tx.transactionType) else {
                throw ParserError.onParsing("Could not get transaction type from LLM")
            }
            return Transaction(id: UUID(),
                               date: defaults.date,
                               category: getCategory(categories: categories,
                                                     name: tx.category,
                                                     defaultValue: (txType == .expense ? defaults.expenseCategory : defaults.incomeCategory)),
                               transactionType: txType,
                               account: defaults.account,
                               amount: tx.amount)
        } catch {
            throw ParserError.onParsing("Couldn't decode data from LLM: \(error)")
        }
    }
    
    private func getCategory(categories: [Category], name: String?, defaultValue: Category) -> Category {
        if let n = name, let c = categories.first(where: { $0.name == n }) {
            return c
        }
        return defaultValue
    }
}
