import Foundation
import Testing
@testable import ArgiMoney

@Suite("Parser and schema tests")
struct ParserAndSchemaTests {
    private let expenseCategory = Category(name: "food", transactionType: .expense)
    private let incomeCategory = Category(name: "salary", transactionType: .income)
    private let account = Account(name: "Cash")

    private var defaults: TransactionDefaults {
        TransactionDefaults(
            date: 42,
            incomeCategory: incomeCategory,
            expenseCategory: expenseCategory,
            account: account
        )
    }

    @Test
    func dummyParserBuildsExpenseUsingMatchingCategory() async throws {
        let transaction = try await DummyInputParser().buildTransactionFrom(
            text: "expense 12.50 food lunch",
            categories: [expenseCategory, incomeCategory],
            accounts: [account],
            defaults: defaults
        )

        #expect(transaction.transactionType == .expense)
        #expect(transaction.amount == 12.50)
        #expect(transaction.category == expenseCategory)
        #expect(transaction.account == account)
        #expect(transaction.date == 42)
        #expect(transaction.detail == "lunch")
    }

    @Test
    func dummyParserBuildsIncomeAndUsesDefaultWhenNoCategoryIsRecognized() async throws {
        let transaction = try await DummyInputParser().buildTransactionFrom(
            text: "income 1000 sidegig",
            categories: [expenseCategory, incomeCategory],
            accounts: [account],
            defaults: defaults
        )

        #expect(transaction.transactionType == .income)
        #expect(transaction.amount == 1000)
        #expect(transaction.category == incomeCategory)
        #expect(transaction.detail == "sidegig")
    }

    @Test
    func dummyParserRejectsMissingOrAmbiguousTransactionType() async {
        await #expect(throws: ParserError.self) {
            _ = try await DummyInputParser().buildTransactionFrom(
                text: "12.50 food lunch",
                categories: [expenseCategory],
                accounts: [account],
                defaults: defaults
            )
        }
        await #expect(throws: ParserError.self) {
            _ = try await DummyInputParser().buildTransactionFrom(
                text: "expense income 12.50 food lunch",
                categories: [expenseCategory, incomeCategory],
                accounts: [account],
                defaults: defaults
            )
        }
    }

    @Test
    func generatedTransactionDecodesOptionalFields() throws {
        let generated = try JSONDecoder().decode(
            GeneratedTransaction.self,
            from: Data("{\"transactionType\":\"income\",\"amount\":10.5}".utf8)
        )

        #expect(generated.transactionType == "income")
        #expect(generated.amount == 10.5)
        #expect(generated.category == nil)
        #expect(generated.detail == nil)
        #expect(generated.account == nil)
    }
}
