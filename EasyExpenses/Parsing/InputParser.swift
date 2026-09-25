//
//  InputParser.swift
//  EasyExpenses
//
//  Created by Javier Avrudsky on 21/09/2026.
//

import Foundation

protocol InputParser {
    func buildTransactionFrom(text: String, defaults: TransactionDefaults) async throws -> Transaction
}
