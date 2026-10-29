import Foundation
import Testing
@testable import ArgiMoney

@Suite("Account and category service tests")
struct AccountCategoryServiceTests {
    @MainActor
    @Test
    func accountsViewModelLoadsAddsSavesAndDeletes() async throws {
        let repository = FakeAccountRepository()
        let existing = Account(name: "Cash")
        try await repository.insertOrUpdate(existing)
        let viewModel = DefaultAccountsViewModel(repo: repository)

        await viewModel.load()
        #expect(viewModel.accounts == [existing])

        viewModel.add()
        #expect(viewModel.accounts.count == 2)
        let created = viewModel.accounts[1]
        #expect(created.name == "New Account")

        let renamed = Account(id: created.id, name: "Savings")
        try await viewModel.save(renamed)
        #expect(viewModel.accounts.contains(renamed))

        guard let existingIndex = viewModel.accounts.firstIndex(where: { $0.id == existing.id }) else {
            Issue.record("Expected the existing account to remain in the loaded list")
            return
        }
        try await viewModel.delete(at: IndexSet(integer: existingIndex))
        #expect(viewModel.accounts.contains(renamed))
        #expect(!viewModel.accounts.contains(existing))
    }

    @MainActor
    @Test
    func categoriesViewModelFiltersByTypeAndPersistsChanges() async throws {
        let repository = FakeCategoryRepository()
        let expense = Category(name: "Food", transactionType: .expense)
        let income = Category(name: "Salary", transactionType: .income)
        try await repository.insertOrUpdate(expense)
        try await repository.insertOrUpdate(income)
        let viewModel = DefaultCategoriesViewModel(transactionType: .expense, repo: repository)

        await viewModel.load()
        #expect(viewModel.categories == [expense])

        viewModel.add()
        let created = viewModel.categories[1]
        #expect(created.transactionType == .expense)
        let renamed = Category(id: created.id, name: "Transport", transactionType: .expense)
        try await viewModel.save(renamed)
        #expect(viewModel.categories.contains(renamed))

        guard let expenseIndex = viewModel.categories.firstIndex(where: { $0.id == expense.id }) else {
            Issue.record("Expected the expense category to remain in the loaded list")
            return
        }
        try await viewModel.delete(at: IndexSet(integer: expenseIndex))
        #expect(viewModel.categories.contains(renamed))
        #expect(!viewModel.categories.contains(expense))
    }

    @MainActor
    @Test
    func transactionFormServiceReturnsRepositoryData() async throws {
        let categoryRepo = FakeCategoryRepository()
        let accountRepo = FakeAccountRepository()
        let transactionRepo = FakeTransactionRepository()
        let category = Category(name: "Food", transactionType: .expense)
        let account = Account(name: "Cash")
        try await categoryRepo.insertOrUpdate(category)
        try await accountRepo.insertOrUpdate(account)
        let service = DefaultTransactionFormViewService(dataStore: DataStore(
            transactionRepo: transactionRepo,
            categoryRepo: categoryRepo,
            accountRepo: accountRepo
        ))

        let categories = await service.getCategories()
        let accounts = await service.getAccounts()

        #expect(categories == [category])
        #expect(accounts == [account])
    }
}
