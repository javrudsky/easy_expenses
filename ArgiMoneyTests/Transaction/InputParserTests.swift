//
//  InputParserTests.swift
//  EasyExpensesTests
//
//  Created by Javier Avrudsky on 15/09/2026.
//

import Foundation
import Testing
@testable import ArgiMoney

@Suite("InputParser parsing")
struct InputParserTests {
    private func makeParser() -> InputParser { DummyInputParser() }

    // Helper to build input string in required format
    private func input(_ typeWord: String, _ amount: String, _ category: String, _ detail: String) -> String {
        return "\(typeWord) \(amount) \(category) \(detail)"
    }

    @Test("Parses debit with amount, category and detail")
    func parsesDebit() async throws {
        let parser = makeParser()
        let text = input("debit", "12.50", "food", "burger and fries")
        let tx = try await parser.buildTransactionFrom(text: text, defaults: TransactionDefaults())

        #expect(tx.transactionType == .debit)
        #expect(tx.amount == Decimal(string: "12.50"))
        #expect(tx.category == "food")
        #expect(tx.detail == "burger and fries")
    }

    @Test("Parses credit with amount, category and detail")
    func parsesCredit() async throws {
        let parser = makeParser()
        let text = input("credit", "1000", "salary", "monthly payment")
        let tx = try await parser.buildTransactionFrom(text: text, defaults: TransactionDefaults())

        #expect(tx.transactionType == .credit)
        #expect(tx.amount == Decimal(string: "1000"))
        #expect(tx.category == "salary")
        #expect(tx.detail == "monthly payment")
    }

    @Test("Prefers credit when both words appear, first word determines type per format")
    func ambiguousWords() async throws {
        let parser = makeParser()
        // Our DummyInputParser marks credit if any credit word is present; ensure detail excludes keywords and amount
        let text = input("credit", "55.00", "refund", "refund from store")
        let tx = try await parser.buildTransactionFrom(text: text, defaults: TransactionDefaults())
        #expect(tx.transactionType == .credit)
        #expect(tx.category == "refund")
        #expect(tx.detail == "from store")
    }

    @Test("Invalid when no debit/credit word present")
    func invalidNoType() async throws {
        let parser = makeParser()
        let text = "12.5 food just some text"
        await #expect(throws: ParserError.self) {
            _ = try await parser.buildTransactionFrom(text: text, defaults: TransactionDefaults())
        }
    }

    @Test("Invalid when both debit and credit implied without clear type")
    func invalidBothTypes() async throws {
        let parser = makeParser()
        let text = "debit credit 10 food something"
        await #expect(throws: ParserError.self) {
            _ = try await parser.buildTransactionFrom(text: text, defaults: TransactionDefaults())
        }
    }

    @Test("Parses detail as all remaining words excluding recognized tokens")
    func parsesDetailRemainder() async throws {
        let parser = makeParser()
        let text = input("debit", "34.99", "groceries", "at local market with coupon")
        let tx = try await parser.buildTransactionFrom(text: text, defaults: TransactionDefaults())
        #expect(tx.detail == "at local market with coupon")
    }
    
    @Test("Defaults are ok")
    func setDefaults() async throws {
        let parser = makeParser()
        let text = input("credit", "55.00", "", " from store")
        let defaults = TransactionDefaults(date: 1.0,
                                           category: "mycat",
                                           account: "myAcc")
        let tx = try await parser.buildTransactionFrom(text: text, defaults: defaults)
        #expect(tx.transactionType == .credit)
        #expect(tx.date == 1.0)
        #expect(tx.category == "mycat")
        #expect(tx.account == "myAcc")
        #expect(tx.detail == "from store")
    }

}
