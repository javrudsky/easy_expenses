import Foundation
import Testing
@testable import ArgiMoney

@Suite("Transaction domain tests")
struct TransactionDomainTests {
    private let category = Category(name: "Food", transactionType: .expense)
    private let account = Account(name: "Cash")

    @Test
    func builderBuildsTransactionWithAllValues() throws {
        let id = UUID()
        let transaction = try TransactionBuilder()
            .setting(id: id)
            .setting(date: 123)
            .setting(category: category)
            .setting(detail: "Lunch")
            .setting(type: .expense)
            .setting(account: account)
            .setting(amount: 12.50)
            .build()

        #expect(transaction.id == id)
        #expect(transaction.date == 123)
        #expect(transaction.category == category)
        #expect(transaction.detail == "Lunch")
        #expect(transaction.transactionType == .expense)
        #expect(transaction.account == account)
        #expect(transaction.amount == 12.50)
        #expect(transaction.isExpense)
    }

    @Test
    func builderErrorsHaveDescriptions() {
        let errors: [TransactionBuilder.BuildError] = [
            .missingDate, .missingCategory, .missingType, .missingAccount, .missingAmount
        ]

        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }

    @Test
    func builderReportsTheFirstMissingRequiredValue() {
        #expect(throws: TransactionBuilder.BuildError.self) {
            try TransactionBuilder().build()
        }
    }

    @Test
    func expenseAndIncomeFactoriesSetTheCorrectType() throws {
        let expense = try Transaction.expense(date: 1, category: category, account: account, amount: 1)
        let incomeCategory = Category(name: "Salary", transactionType: .income)
        let income = try Transaction.income(date: 2, category: incomeCategory, account: account, amount: 2)

        #expect(expense.transactionType == .expense)
        #expect(expense.isExpense)
        #expect(income.transactionType == .income)
        #expect(!income.isExpense)
    }

    @Test
    func audioTranscriberResultConvertsAttributedText() {
        let result = AudioTranscriberResult(text: AttributedString("Recognized text"), isFinal: true)

        #expect(result.text == "Recognized text")
        #expect(result.isFinal)
    }
}
