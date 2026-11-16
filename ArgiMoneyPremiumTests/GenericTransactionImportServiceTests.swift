import Foundation
import Testing
@testable import ArgiMoneyPremium

@Suite("Generic transaction import tests")
struct GenericTransactionImportServiceTests {
    var categoryRepo: FakeCategoryRepository
    var accountRepo: FakeAccountRepository
    var transactionRepo: FakeTransactionRepository

    var dataStore: DataStore
    var sut: DefaultAdvancedTransactionImportService

    init() {
        categoryRepo = FakeCategoryRepository()
        accountRepo = FakeAccountRepository()
        transactionRepo = FakeTransactionRepository()

        dataStore = DataStore(transactionRepo: transactionRepo,
                              categoryRepo: categoryRepo,
                              accountRepo: accountRepo)
        sut = DefaultAdvancedTransactionImportService(dataStore: dataStore)
    }

    // MARK: - Helpers

    private func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private func csvRow(_ columns: [String]) -> String {
        columns.map { csvEscaped($0) }.joined(separator: ",")
    }

    private func csv(_ header: String, _ rows: [[String]]) -> String {
        ([header] + rows.map(csvRow)).joined(separator: "\n")
    }

    // MARK: - Tests

    @Test
    func importFrom_acceptsReorderedColumnsAndBuildsEntities() async throws {
        let header = "amount,account,date,category,detail"
        let row = ["100.50", "Wallet", "2026-10-21T00:00:00Z", "Salary", "October"]

        let summary = try await sut.importFrom(csv: csv(header, [row]))

        #expect(summary.logSummary.errorCount == 0)
        #expect(summary.logSummary.warningCount == 0)
        #expect(summary.transactions.count == 1)
        #expect(summary.categories.count == 1)
        #expect(summary.accounts.count == 1)

        let transaction = try #require(summary.transactions.first)
        let expectedAmount = try #require(Decimal(string: "100.50"))
        #expect(transaction.transactionType == .income)
        #expect(transaction.amount == expectedAmount)
        #expect(transaction.category.name == "Salary")
        #expect(transaction.category.transactionType == .income)
        #expect(transaction.account.name == "Wallet")
        #expect(transaction.detail == "October")
    }

    @Test
    func importFrom_usesAmountSignForTypeAndStoresPositiveAmounts() async throws {
        let header = "date,category,account,detail,amount"
        let rows = [
            ["2026-10-21", "Food", "Cash", "", "-12.50"],
            ["2026-10-22", "Refund", "Cash", "Refund", "0"]
        ]

        let summary = try await sut.importFrom(csv: csv(header, rows))

        #expect(summary.logSummary.errorCount == 1)
        #expect(summary.transactions.count == 1)
        #expect(summary.logSummary.log.localizedCaseInsensitiveContains("zero"))

        let expense = try #require(summary.transactions.first)
        let expectedExpenseAmount = try #require(Decimal(string: "12.50"))
        #expect(expense.transactionType == .expense)
        #expect(expense.amount == expectedExpenseAmount)
        #expect(expense.detail == nil)
    }

    @Test
    func importFrom_reusesCategoryAndAccountIDsByName() async throws {
        let header = "date,category,account,amount,detail"
        let rows = [
            ["2026-10-21", "Food", "Cash", "-10", "Lunch"],
            ["2026-10-22", "food", "Cash", "-20", "Dinner"],
            ["2026-10-23", "Salary", "Cash", "100", "Pay"],
            ["2026-10-24", "Food", "Cash", "50", "Refund"]
        ]

        let summary = try await sut.importFrom(csv: csv(header, rows))

        #expect(summary.logSummary.errorCount == 0)
        #expect(summary.transactions.count == 4)
        #expect(summary.accounts.count == 1)

        let foodExpenses = summary.categories.filter {
            $0.name.lowercased() == "food" && $0.transactionType == .expense
        }
        let foodIncomes = summary.categories.filter {
            $0.name.lowercased() == "food" && $0.transactionType == .income
        }
        #expect(foodExpenses.count == 1)
        #expect(foodIncomes.count == 1)
        #expect(foodExpenses.first?.id != foodIncomes.first?.id)

        // The two expense rows and the income row must share IDs with their peers.
        #expect(summary.transactions[0].category.id == summary.transactions[1].category.id)
        #expect(summary.transactions[0].category.id != summary.transactions[3].category.id)
        #expect(summary.transactions.allSatisfy { $0.account.id == summary.transactions[0].account.id })
    }

    @Test
    func importFrom_deterministicIDsAreStableAcrossImports() async throws {
        let header = "date,category,account,amount,detail"
        let row = ["2026-10-21", "Food", "Cash", "-10", "Lunch"]

        let first = try await sut.importFrom(csv: csv(header, [row]))
        let second = try await sut.importFrom(csv: csv(header, [row]))

        #expect(first.categories.first?.id == second.categories.first?.id)
        #expect(first.accounts.first?.id == second.accounts.first?.id)
        #expect(first.transactions.first?.id != second.transactions.first?.id)
    }

    @Test
    func importFrom_reusesExistingCategoryAndAccountIDs() async throws {
        let existingCategory = Category(name: "Food", transactionType: .expense,
                                        imageName: "fork.knife", rgbColor: "1.0, 0.0, 0.0, 1.0")
        let existingAccount = Account(name: "Cash", imageName: "creditcard.fill",
                                      rgbColor: "0.29, 0.52, 1.0, 1.0")
        try await categoryRepo.insertOrUpdate(existingCategory)
        try await accountRepo.insertOrUpdate(existingAccount)

        let header = "date,category,account,amount,detail"
        let summary = try await sut.importFrom(csv: csv(header, [["2026-10-21", "food", "cash", "-10", "Lunch"]]))

        #expect(summary.categories.first?.id == existingCategory.id)
        #expect(summary.categories.first?.name == existingCategory.name)
        #expect(summary.categories.first?.imageName == existingCategory.imageName)
        #expect(summary.accounts.first?.id == existingAccount.id)
        #expect(summary.accounts.first?.name == existingAccount.name)
    }

    @Test
    func importFrom_missingRequiredColumnThrows() async {
        let header = "date,category,account"

        do {
            _ = try await sut.importFrom(csv: header + "\n")
            Issue.record("Expected missing column error")
        } catch let error as DefaultDataTransferService.ImportError {
            switch error {
            case .missingColumn(let missing):
                #expect(missing == "amount")
            default:
                Issue.record("Expected missingColumn error, got \(error)")
            }
        } catch {
            Issue.record("Expected ImportError.missingColumn but got \(error)")
        }
    }

    @Test
    func importFrom_logsInvalidRowsAndSkipsThem() async throws {
        let header = "date,category,account,detail,amount"
        let rows = [
            ["not-a-date", "Food", "Cash", "Bad date", "12.00"],
            ["2026-10-21T00:00:00Z", "Food", "Cash", "Bad amount", "twelve"],
            ["2026-10-21T00:00:00Z", "", "Cash", "Missing category", "12.00"],
            ["2026-10-21T00:00:00Z", "Food", "", "Missing account", "12.00"],
            ["2026-10-21T00:00:00Z", "Food", "Cash", "Valid", "12.00"]
        ]

        let summary = try await sut.importFrom(csv: csv(header, rows))

        #expect(summary.transactions.count == 1)
        #expect(summary.logSummary.errorCount == 4)
        #expect(summary.logSummary.log.localizedCaseInsensitiveContains("invalid date"))
        #expect(summary.logSummary.log.localizedCaseInsensitiveContains("invalid amount"))
        #expect(summary.logSummary.log.localizedCaseInsensitiveContains("missing category"))
        #expect(summary.logSummary.log.localizedCaseInsensitiveContains("missing account"))
    }

    @Test
    func importFrom_supportsDateOnlyValues() async throws {
        let header = "date,category,account,detail,amount"
        let summary = try await sut.importFrom(csv: csv(header, [["2026-10-21", "Food", "Cash", "", "12.00"]]))

        let transaction = try #require(summary.transactions.first)
        let components = Calendar(identifier: .gregorian)
            .dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: Date(timeIntervalSince1970: transaction.date))
        #expect(components.year == 2026)
        #expect(components.month == 10)
        #expect(components.day == 21)
    }

    @Test
    func importFrom_acceptsTrailingNewlineAndMissingDetailColumn() async throws {
        let csv = "date,category,account,amount\n2026-10-21,Food,Cash,-10\n"

        let summary = try await sut.importFrom(csv: csv)

        #expect(summary.logSummary.errorCount == 0)
        #expect(summary.transactions.count == 1)
        #expect(summary.transactions.first?.detail == nil)
    }

    @Test
    func dataTransferService_importGenericFromAndExecuteImportPersistsEntities() async throws {
        let service = DefaultDataTransferService(dataStore: dataStore)
        let header = "date,category,account,detail,amount"
        let rows = [
            ["2026-10-21T00:00:00Z", "Food", "Cash", "Lunch", "-12.50"],
            ["2026-10-22T00:00:00Z", "Salary", "Cash", "Pay", "100.00"]
        ]

        let summary = try await service.importGenericFrom(csv: csv(header, rows), logBuilder: DefaultImportLogBuilder())
        try await service.executeImport(summary: summary)

        let categories = try await categoryRepo.fetchAll()
        let accounts = try await accountRepo.fetchAll()
        let transactions = try await transactionRepo.fetchAll()

        #expect(categories.count == 2)
        #expect(accounts.count == 1)
        #expect(transactions.count == 2)
        let expectedExpenseAmount = try #require(Decimal(string: "12.50"))
        #expect(transactions.contains { $0.transactionType == .expense && $0.amount == expectedExpenseAmount })
        #expect(transactions.contains { $0.transactionType == .income && $0.amount == 100 })
    }

    // MARK: - Premium visuals

    private var headerWithVisuals: String {
        [
            "date", "category", "account", "detail", "amount",
            "category_image_name", "category_rgb_color", "account_image_name", "account_rgb_color"
        ].joined(separator: ",")
    }

    @Test
    func importFrom_withPremium_importsVisualsForNewEntities() async throws {
        let service = DefaultAdvancedTransactionImportService(dataStore: dataStore, hasPremium: true)
        let row = [
            "2026-10-21", "Food", "Cash", "Lunch", "-10",
            "fork.knife", "1.0, 0.0, 0.0, 1.0",
            "creditcard.fill", "0.29, 0.52, 1.0, 1.0"
        ]

        let summary = try await service.importFrom(csv: csv(headerWithVisuals, [row]))

        #expect(summary.logSummary.errorCount == 0)
        let category = try #require(summary.categories.first)
        let account = try #require(summary.accounts.first)
        #expect(category.imageName == "fork.knife")
        #expect(category.rgbColor == "1.0, 0.0, 0.0, 1.0")
        #expect(account.imageName == "creditcard.fill")
        #expect(account.rgbColor == "0.29, 0.52, 1.0, 1.0")
    }

    @Test
    func importFrom_withoutPremium_ignoresVisuals() async throws {
        let service = DefaultAdvancedTransactionImportService(dataStore: dataStore, hasPremium: false)
        let row = [
            "2026-10-21", "Food", "Cash", "Lunch", "-10",
            "fork.knife", "1.0, 0.0, 0.0, 1.0",
            "creditcard.fill", "0.29, 0.52, 1.0, 1.0"
        ]

        let summary = try await service.importFrom(csv: csv(headerWithVisuals, [row]))

        let category = try #require(summary.categories.first)
        let account = try #require(summary.accounts.first)
        #expect(category.imageName == AppDefaults.defaultCategoryImage)
        #expect(category.rgbColor == AppDefaults.defaultCategoryColor)
        #expect(account.imageName == AppDefaults.defaultAccountImage)
        #expect(account.rgbColor == AppDefaults.defaultAccountColor)
    }

    @Test
    func importFrom_existingVisualsDiffer_logsConflictsAndExecuteImportKeepsStoredValues() async throws {
        let existingCategory = Category(name: "Food", transactionType: .expense,
                                        imageName: "stored.symbol", rgbColor: "0.1, 0.2, 0.3, 1.0")
        let existingAccount = Account(name: "Cash",
                                      imageName: "stored.account", rgbColor: "0.4, 0.5, 0.6, 1.0")
        try await categoryRepo.insertOrUpdate(existingCategory)
        try await accountRepo.insertOrUpdate(existingAccount)

        let service = DefaultDataTransferService(dataStore: dataStore, hasPremium: true)
        let row = [
            "2026-10-21", "Food", "Cash", "Lunch", "-10",
            "new.symbol", "1.0, 0.0, 0.0, 1.0",
            "new.account", "0.0, 1.0, 0.0, 1.0"
        ]

        let summary = try await service.importGenericFrom(csv: csv(headerWithVisuals, [row]),
                                                          logBuilder: DefaultImportLogBuilder())

        #expect(summary.logSummary.errorCount == 4)
        #expect(summary.logSummary.log.contains("CONFLICT"))

        try await service.executeImport(summary: summary)

        let category = try await categoryRepo.fetchBy(id: existingCategory.id)
        let account = try await accountRepo.fetchBy(id: existingAccount.id)
        #expect(category?.imageName == existingCategory.imageName)
        #expect(category?.rgbColor == existingCategory.rgbColor)
        #expect(account?.imageName == existingAccount.imageName)
        #expect(account?.rgbColor == existingAccount.rgbColor)
    }
}
