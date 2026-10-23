import Foundation
import Testing
@testable import ArgiMoney

typealias Th = TransactionTestsHelper

@Suite("TransactionMapper mapping")

struct TransactionMapperTests {
    @Test("toModel maps all fields")
    func testToModel() {
        let domain = Th.createTransaction(
            id: UUID(),
            date: 1625072400,
            category: "Utilities",
            detail: "Electric bill",
            transactionType: .income,
            account: "Savings",
            amount: 120.50
        )
        let categoryModel = DefaultCategoryMapper().toModel(domain.category)
        let accountModel = DefaultAccountMapper().toModel(domain.account)
        let model = DefaultTransactionMapper().toModel(
            domain,
            categoryModel: categoryModel,
            accountModel: accountModel
        )

        #expect(model.id == domain.id)
        #expect(model.date == domain.date)
        #expect(model.category.id == domain.category.id)
        #expect(model.category.name == domain.category.name)
        #expect(model.category.transactionType == domain.category.transactionType.rawValue)
        #expect(model.detail == domain.detail)
        #expect(model.transactionType == domain.transactionType.rawValue)
        #expect(model.account.id == domain.account.id)
        #expect(model.account.name == domain.account.name)
        #expect(model.amount == domain.amount)
    }

    @Test("toDomain maps all fields")
    func testToDomain() {
        let model = Th.createModelTransaction(
            id: UUID(),
            date: 1625072400,
            category: "Transport",
            detail: "Bus ticket",
            transactionType: .income,
            account: "Cash",
            amount: 2.75
        )
        let domain = DefaultTransactionMapper().toDomain(model)

        #expect(domain.id == model.id)
        #expect(domain.date == model.date)
        #expect(domain.category.id == model.category.id)
        #expect(domain.category.name == model.category.name)
        #expect(domain.detail == model.detail)
        #expect(domain.transactionType.rawValue == model.transactionType)
        #expect(domain.account.id == model.account.id)
        #expect(domain.account.name == model.account.name)
        #expect(domain.amount == model.amount)

        // Unknown transaction types default to expense.
        let unknownModel = TransactionModel(
            id: UUID(),
            date: 0,
            detail: nil,
            transactionType: "unknownType",
            amount: 0,
            category: DefaultCategoryMapper().toModel(Category(name: "Other", transactionType: .expense)),
            account: DefaultAccountMapper().toModel(Account(name: "Cash"))
        )
        let defaultDomain = DefaultTransactionMapper().toDomain(unknownModel)
        #expect(defaultDomain.transactionType == .expense)
    }

    @Test("round-trip preserves values")
    func testRoundTrip() {
        let domain = Th.createTransaction(
            id: UUID(),
            date: 1625072400,
            category: "Groceries",
            detail: "Weekly shopping",
            transactionType: .expense,
            account: "Credit Card",
            amount: 95.30
        )
        let model = DefaultTransactionMapper().toModel(
            domain,
            categoryModel: DefaultCategoryMapper().toModel(domain.category),
            accountModel: DefaultAccountMapper().toModel(domain.account)
        )
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
