import Foundation
import Testing
@testable import ArgiMoney

// MARK: - Tests

@Suite("DefaultDataTransferService Tests") struct DefaultDataTransferServiceTests {
    var categoryRepo: FakeCategoryRepository
    var accountRepo: FakeAccountRepository
    var transactionRepo: FakeTransactionRepository

    var dataStore: DataStore
    var sut: DefaultDataTransferService

    init() {
        categoryRepo = FakeCategoryRepository()
        accountRepo = FakeAccountRepository()
        transactionRepo = FakeTransactionRepository()
        
        dataStore = DataStore(transactionRepo: transactionRepo,
                              categoryRepo: categoryRepo,
                              accountRepo: accountRepo)
        sut = DefaultDataTransferService(dataStore: dataStore)
    }

    // MARK: - CSV Helpers

    func csvEscaped(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    func csvRow(_ columns: [String]) -> String {
        columns.map { csvEscaped($0) }.joined(separator: ",")
    }

    // MARK: - Tests

    @Test
    func testExportToCsv_buildsHeaderAndRowsCorrectly() async throws {
        // Arrange
        let categoryId1 = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let accountId1 = UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!
        let transactionId1 = UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!
        let transactionId2 = UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!

        let category1 = Category(id: categoryId1, name: "Cat1", transactionType: .expense)
        let account1 = Account(id: accountId1, name: "Main \"Acc1\"")
        
        let category2 = Category(id: categoryId1, name: "Cat2", transactionType: .expense)
        let account2 = Account(id: accountId1, name: "Main \"Acc2\"")

        try await categoryRepo.insertOrUpdate(category1)
        try await accountRepo.insertOrUpdate(account1)

        let date1 = 11111.0
        let date2 = 22222.0

        let transaction1 = Transaction(
            id: transactionId1,
            date: date1,
            category: category1,
            detail: "Lunch at \"Joe's\", very tasty",
            transactionType: .expense,
            account: account1,
            amount: 123.45,
        )
        let transaction2 = Transaction(
            id: transactionId2,
            date: date2,
            category: category2,
            detail: "Salary, October",
            transactionType: .income,
            account: account2,
            amount: 987.65,
        )

        for t in [transaction1, transaction2] {
            try await transactionRepo.insertOrUpdate(t)
        }

        // Act
        let csv = try await sut.exportToCsv()
        let lines = csv.components(separatedBy: "\n")

        // Assert
        let expectedHeader = [
            "transaction_id",
            "date",
            "transaction_type",
            "amount",
            "detail",
            "category_id",
            "category_name",
            "account_id",
            "account_name"
        ].joined(separator: ",")

        #expect(lines.first == expectedHeader)
        #expect(lines.count == 3)

        // Check first data line fields
        let firstDataLine = lines[1]

        // Split CSV respecting quotes. We'll implement a simple parser for the test here:
        func splitCSVLine(_ line: String) -> [String] {
            var result = [String]()
            var current = ""
            var inQuotes = false
            let characters = Array(line)
            var index = 0

            while index < characters.count {
                let char = characters[index]
                if char == "\"" {
                    if inQuotes && index + 1 < characters.count && characters[index + 1] == "\"" {
                        current.append("\"")
                        index += 1
                    } else {
                        inQuotes.toggle()
                    }
                } else if char == "," && !inQuotes {
                    result.append(current)
                    current = ""
                } else {
                    current.append(char)
                }
                index += 1
            }
            result.append(current)
            return result
        }

        let fields = splitCSVLine(firstDataLine)
        #expect(fields.count == 9)

        #expect(fields[0] == transactionId1.uuidString)
        #expect(fields[1] == ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: date1)))
        #expect(fields[2] == transaction1.transactionType.rawValue)
        #expect(fields[3] == String(describing: transaction1.amount))
        #expect(fields[4] == "Lunch at \"Joe's\", very tasty")
        #expect(fields[5] == categoryId1.uuidString)
        #expect(fields[6] == "Cat1")
        #expect(fields[7] == accountId1.uuidString)
        #expect(fields[8] == "Main \"Acc1\"")
    }

    @Test
    func exportToCsv_withNoTransactions_returnsOnlyHeader() async throws {
        let csv = try await sut.exportToCsv()

        #expect(csv == [
            "transaction_id",
            "date",
            "transaction_type",
            "amount",
            "detail",
            "category_id",
            "category_name",
            "account_id",
            "account_name"
        ].joined(separator: ","))
    }

    @Test
    func testImportFrom_withValidCsv_parsesEntitiesAndReturnsSummary() async throws {
        // Arrange
        let transactionId = UUID(uuidString: "EEEEEEEE-EEEE-EEEE-EEEE-EEEEEEEEEEEE")!
        let categoryId = UUID(uuidString: "FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF")!
        let accountId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let dateString = "2026-10-21T00:00:00.000Z"

        let header = [
            "transaction_id",
            "date",
            "transaction_type",
            "amount",
            "detail",
            "category_id",
            "category_name",
            "account_id",
            "account_name"
        ].joined(separator: ",")

        let row = csvRow([
            transactionId.uuidString,
            dateString,
            TransactionType.income.rawValue,
            "1000.00",
            "Salary payment",
            categoryId.uuidString,
            "Salary",
            accountId.uuidString,
            "Main Account"
        ])

        let csv = [header, row].joined(separator: "\n")

        // Act
        let result = try await sut.importFrom(csv: csv)

        // Assert
        #expect(result.categories.count == 1)
        #expect(result.accounts.count == 1)
        #expect(result.transactions.count == 1)
        #expect(result.logSummary.errorCount == 0)
        #expect(result.logSummary.warningCount == 0)
    }

    @Test
    func importFrom_withReorderedColumns_parsesByHeaderName() async throws {
        let transactionId = UUID()
        let categoryId = UUID()
        let accountId = UUID()
        let header = [
            "account_name",
            "amount",
            "transaction_id",
            "category_name",
            "date",
            "account_id",
            "detail",
            "transaction_type",
            "category_id"
        ].joined(separator: ",")
        let row = csvRow([
            "Wallet",
            "25.50",
            transactionId.uuidString,
            "Dining",
            "2026-10-21T00:00:00Z",
            accountId.uuidString,
            "Dinner",
            TransactionType.expense.rawValue,
            categoryId.uuidString
        ])

        let result = try await sut.importFrom(csv: [header, row].joined(separator: "\n"))

        #expect(result.logSummary.errorCount == 0)
        #expect(result.transactions.count == 1)
        #expect(result.transactions[0].id == transactionId)
        #expect(result.transactions[0].category.id == categoryId)
        #expect(result.transactions[0].account.id == accountId)
        #expect(result.transactions[0].detail == "Dinner")
        #expect(result.transactions[0].amount == 25.50)
    }

    @Test
    func testImportFrom_withInvalidHeader_throwsMissingColumn() async {
        // Arrange
        let headerMissingAccountName = [
            "transaction_id",
            "date",
            "transaction_type",
            "amount",
            "detail",
            "category_id",
            "category_name",
            "account_id"
            // Missing account_name column
        ].joined(separator: ",")

        let csv = headerMissingAccountName + "\n" // no data rows

        // Act & Assert
        do {
            _ = try await sut.importFrom(csv: csv)
            Issue.record("Expected importFrom to throw missingColumn error")
        } catch let error as DefaultDataTransferService.ImportError {
            switch error {
            case .missingColumn(let missing):
                #expect(missing == "account_name")
            default:
                Issue.record("Expected missingColumn error, got \(error)")
            }
        } catch {
            Issue.record("Expected ImportError.missingColumn but got different error: \(error)")
        }
    }

    @Test
    func testImportFrom_logsInvalidRows_andSkipsThem() async throws {
        // Arrange
        let header = [
            "transaction_id",
            "date",
            "transaction_type",
            "amount",
            "detail",
            "category_id",
            "category_name",
            "account_id",
            "account_name"
        ].joined(separator: ",")

        let invalidTransactionId = "invalid-uuid"
        let validTransactionId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let categoryId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
        let accountId = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let dateString = "2026-10-21T00:00:00.000Z"

        let invalidRow = csvRow([
            invalidTransactionId,
            dateString,
            TransactionType.expense.rawValue,
            "12.34",
            "Invalid transaction id row",
            categoryId.uuidString,
            "CategoryX",
            accountId.uuidString,
            "AccountX"
        ])

        let validRow = csvRow([
            validTransactionId.uuidString,
            dateString,
            TransactionType.expense.rawValue,
            "56.78",
            "Valid transaction",
            categoryId.uuidString,
            "CategoryX",
            accountId.uuidString,
            "AccountX"
        ])

        let csv = [header, invalidRow, validRow].joined(separator: "\n")

        // Act
        let result = try await sut.importFrom(csv: csv)

        // Assert
        #expect(result.transactions.count == 1)
        #expect(result.logSummary.errorCount >= 1)

        let logsString = result.logSummary.log.lowercased()
        #expect(logsString.contains("invalid transaction id"))
    }

    @Test
    func importFrom_withShortRow_logsErrorInsteadOfCrashing() async throws {
        let header = [
            "transaction_id", "date", "transaction_type", "amount", "detail",
            "category_id", "category_name", "account_id", "account_name"
        ].joined(separator: ",")
        let csv = [header, UUID().uuidString].joined(separator: "\n")

        let result = try await sut.importFrom(csv: csv)

        #expect(result.transactions.isEmpty)
        #expect(result.logSummary.errorCount == 1)
        #expect(result.logSummary.log.localizedCaseInsensitiveContains("missing transaction type"))
    }

    @Test
    func testImportFrom_logsDuplicates_usingRepositories() async throws {
        // Arrange

        // Existing entities in mocks
        let existingCategoryId = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
        let existingAccountId = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
        let existingTransactionId = UUID(uuidString: "77777777-7777-7777-7777-777777777777")!

        let existingCategory = Category(id: existingCategoryId, name: "ExistingCategory", transactionType: .income)
        let existingAccount = Account(id: existingAccountId, name: "ExistingAccount")
        let existingTransaction = Transaction(
            id: existingTransactionId,
            date: 1792650200,
            category: existingCategory,
            detail: "Existing transaction",
            transactionType: .income,
            account: existingAccount,
            amount: 100.0,
        )

        try await categoryRepo.insertOrUpdate(existingCategory)
        try await accountRepo.insertOrUpdate(existingAccount)
        try await transactionRepo.insertOrUpdate(existingTransaction)

        // CSV row that conflicts by IDs
        let header = [
            "transaction_id",
            "date",
            "transaction_type",
            "amount",
            "detail",
            "category_id",
            "category_name",
            "account_id",
            "account_name"
        ].joined(separator: ",")

        let conflictingRow = csvRow([
            existingTransactionId.uuidString,
            "2026-10-19T00:00:00-03:00",
            TransactionType.income.rawValue,
            "101.00",
            "Conflicting transaction",
            existingCategoryId.uuidString,
            "ExistingCategory",
            existingAccountId.uuidString,
            "ExistingAccount"
        ])

        let csv = [header, conflictingRow].joined(separator: "\n")

        // Act
        let result = try await sut.importFrom(csv: csv)

        // Assert
        #expect(result.logSummary.errorCount > 0)
        let logsString = result.logSummary.log
        #expect(logsString.contains("[CONFLICT]"))
    }

    @Test
    func executeImport_persistsEntitiesInSummary() async throws {
        let category = Category(name: "Groceries", transactionType: .expense)
        let account = Account(name: "Wallet")
        let transaction = Transaction(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            date: 1_000,
            category: category,
            detail: "Market",
            transactionType: .expense,
            account: account,
            amount: 12.50
        )
        let summary = ImportSummary(
            logSummary: ImportLogSummary(lines: []),
            categories: [category],
            accounts: [account],
            transactions: [transaction]
        )

        try await sut.executeImport(summary: summary)

        let importedCategory = try await categoryRepo.fetchBy(id: category.id)
        let importedAccount = try await accountRepo.fetchBy(id: account.id)
        let importedTransaction = try await transactionRepo.fetchBy(id: transaction.id)
        #expect(importedCategory == category)
        #expect(importedAccount == account)
        #expect(importedTransaction?.id == transaction.id)
        #expect(importedTransaction?.amount == transaction.amount)
    }

    @Test
    func executeImport_updatesExistingEntitiesWithMatchingIDs() async throws {
        let categoryId = UUID()
        let accountId = UUID()
        let transactionId = UUID()
        let originalCategory = Category(id: categoryId, name: "Food", transactionType: .expense)
        let originalAccount = Account(id: accountId, name: "Cash")
        let originalTransaction = Transaction(
            id: transactionId,
            date: 1,
            category: originalCategory,
            detail: "Lunch",
            transactionType: .expense,
            account: originalAccount,
            amount: 10
        )
        try await sut.executeImport(summary: ImportSummary(
            logSummary: ImportLogSummary(lines: []),
            categories: [originalCategory],
            accounts: [originalAccount],
            transactions: [originalTransaction]
        ))

        let updatedCategory = Category(id: categoryId, name: "Restaurants", transactionType: .expense)
        let updatedAccount = Account(id: accountId, name: "Debit Card")
        let updatedTransaction = Transaction(
            id: transactionId,
            date: 2,
            category: updatedCategory,
            detail: "Dinner",
            transactionType: .expense,
            account: updatedAccount,
            amount: 25
        )
        try await sut.executeImport(summary: ImportSummary(
            logSummary: ImportLogSummary(lines: []),
            categories: [updatedCategory],
            accounts: [updatedAccount],
            transactions: [updatedTransaction]
        ))

        let categories = try await categoryRepo.fetchAll()
        let accounts = try await accountRepo.fetchAll()
        let transactions = try await transactionRepo.fetchAll()
        let category = try await categoryRepo.fetchBy(id: categoryId)
        let account = try await accountRepo.fetchBy(id: accountId)
        let transaction = try await transactionRepo.fetchBy(id: transactionId)
        #expect(categories.count == 1)
        #expect(accounts.count == 1)
        #expect(transactions.count == 1)
        #expect(category?.name == "Restaurants")
        #expect(account?.name == "Debit Card")
        #expect(transaction?.date == 2)
        #expect(transaction?.detail == "Dinner")
        #expect(transaction?.amount == 25)
    }
}
