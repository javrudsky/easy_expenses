//
//  LLMModel.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 19/09/2026.
//
import Foundation
import FoundationModels

struct LLMParser: InputParser {
    private let support: FoundationModelSupport

    init(model: SystemLanguageModel = .default) {
        self.support = FoundationModelSupport(model: model)
    }

    func buildTransactionFrom(text: String,
                              categories: [Category],
                              accounts: [Account],
                              defaults: TransactionDefaults) async throws -> Transaction {
        guard support.availability.isAvailable else {
            let reason = support.availability.unavailableReason
            throw ParserError.onParsing(reason?.message ?? "The on-device model is unavailable.")
        }

        let session = support.makeSession(instructions: instructions)
        let categoryNames = categories.isEmpty ? ["Other"] : categories.map(\.name)
        let txSchema = LLMTransactionSchema.transactionSchema(categories: categoryNames,
                                                              accounts: accounts.map(\.name))
        let schema: GenerationSchema
        do {
            schema = try GenerationSchema(root: txSchema, dependencies: [])
        } catch {
            throw ParserError.onParsing("Error generating schema: \(error)")
        }

        do {
            let response = try await session.respond(to: text, schema: schema)
            let data = Data(response.content.jsonString.utf8)
            let tx = try JSONDecoder().decode(GeneratedTransaction.self, from: data)
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
        } catch let error as ParserError {
            throw error
        } catch let error as DecodingError {
            throw ParserError.onParsing("Couldn't decode data from LLM: \(error)")
        } catch {
            throw ParserError.onParsing(FoundationModelErrorDescription.message(for: error))
        }
    }

    private var instructions: String {
        """
        You extract one financial transaction from free-form text.
        Choose exactly one of the provided categories and one of the provided accounts.
        Use "expense" when money leaves the account and "income" when money is received.
        Return the amount as a numeric value without currency symbols.
        If the text doesn't clearly describe a transaction, make the most reasonable inference from the available values.
        \(support.localeInstruction)
        """
    }

    private func getCategory(categories: [Category], name: String?, defaultValue: Category) -> Category {
        if let n = name, let c = categories.first(where: { $0.name == n }) {
            return c
        }
        return defaultValue
    }
}
