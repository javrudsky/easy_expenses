import Foundation
import Testing
@testable import EasyExpenses

typealias Th = TransactionTestsHelper

@Suite("TransactionMapper mapping")

struct TransactionMapperTests {
    // Helper factories

//    private func makeDomainTransaction(
//        id: String = "id1",
//        date: TimeInterval = 1234567890,
//        category: String = "Food",
//        detail: String = "Lunch",
//        transactionType: TransactionType = .debit,
//        account: String = "Checking",
//        amount: Decimal = 45.67
//    ) -> Transaction {
//        Transaction(
//            id: id,
//            date: date,
//            category: category,
//            detail: detail,
//            transactionType: transactionType,
//            account: account,
//            amount: amount
//        )
//    }
    // Because we are in the same module via @testable import, we assume real types are visible.
    // So prefer to use real types and mapper directly.

    @Test("toModel maps all fields")
    func testToModel() {
        let domain = Th.createTransaction(
            id: UUID(),
            date: 1625072400,
            category: "Utilities",
            detail: "Electric bill",
            transactionType: .credit,
            account: "Savings",
            amount: 120.50
        )
        let model = DefaultTransactionMapper().toModel(domain)

        #expect(model.id == domain.id)
        #expect(model.date == domain.date)
        #expect(model.category == domain.category)
        #expect(model.detail == domain.detail)
        #expect(model.transactionType == domain.transactionType.rawValue)
        #expect(model.account == domain.account)
        #expect(model.amount == domain.amount)
    }

    @Test("toDomain maps all fields")
    func testToDomain() {
        let model = Th.createModelTransaction(
            id: UUID(),
            date: 1625072400,
            category: "Transport",
            detail: "Bus ticket",
            transactionType: "credit",
            account: "Cash",
            amount: 2.75
        )
        let domain = DefaultTransactionMapper().toDomain(model)

        #expect(domain.id == model.id)
        #expect(domain.date == model.date)
        #expect(domain.category == model.category)
        #expect(domain.detail == model.detail)
        #expect(domain.transactionType.rawValue == model.transactionType)
        #expect(domain.account == model.account)
        #expect(domain.amount == model.amount)

        // Unknown transactionType defaults to .debit
        let unknownModel = Th.createModelTransaction(transactionType: "unknownType")
        let defaultDomain = DefaultTransactionMapper().toDomain(unknownModel)
        #expect(defaultDomain.transactionType == TransactionType.debit)
    }

    @Test("round-trip preserves values")
    func testRoundTrip() {
        let domain = Th.createTransaction(
            id: UUID(),
            date: 1625072400,
            category: "Groceries",
            detail: "Weekly shopping",
            transactionType: .debit,
            account: "Credit Card",
            amount: 95.30
        )
        let model = DefaultTransactionMapper().toModel(domain)
        let domain2 = DefaultTransactionMapper().toDomain(model)

        #expect(domain2.id == domain.id)
        #expect(domain2.date == domain.date)
        #expect(domain2.category == domain.category)
        #expect(domain2.detail == domain.detail)
        #expect(domain2.transactionType.rawValue == domain.transactionType.rawValue)
        #expect(domain2.account == domain.account)
        #expect(domain2.amount == domain.amount)
    }
}
