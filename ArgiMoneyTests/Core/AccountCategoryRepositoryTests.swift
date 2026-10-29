import Foundation
import SwiftData
import Testing
@testable import ArgiMoney

@Suite("Account and category repository contracts")
struct AccountCategoryRepositoryTests {
    let categoryRepository: SwiftDataCategoryRepository
    let accountRepository: SwiftDataAccountRepository

    init() async throws {
        let container = try await MainActor.run {
            try DefaultAppFactory.createModelContainer(inMemory: true)
        }
        categoryRepository = SwiftDataCategoryRepository(modelContainer: container)
        accountRepository = SwiftDataAccountRepository(modelContainer: container)
    }

    @Test
    func categoryRepositoryInsertsUpdatesFetchesAndDeletes() async throws {
        let original = Category(name: "Food", transactionType: .expense)
        try await categoryRepository.insertOrUpdate(original)
        let fetchedOriginal = try await categoryRepository.fetchBy(id: original.id)
        #expect(fetchedOriginal == original)

        let updated = Category(id: original.id, name: "Restaurants", transactionType: .expense)
        try await categoryRepository.insertOrUpdate(updated)
        let categories = try await categoryRepository.fetchAll()
        #expect(categories.count == 1)
        #expect(categories.first == updated)

        try await categoryRepository.delete(updated)
        let deletedCategory = try await categoryRepository.fetchBy(id: updated.id)
        #expect(deletedCategory == nil)
    }

    @Test
    func accountRepositoryInsertsUpdatesFetchesAndDeletes() async throws {
        let original = Account(name: "Cash")
        try await accountRepository.insertOrUpdate(original)
        let fetchedOriginal = try await accountRepository.fetchBy(id: original.id)
        #expect(fetchedOriginal == original)

        let updated = Account(id: original.id, name: "Checking")
        try await accountRepository.insertOrUpdate(updated)
        let accounts = try await accountRepository.fetchAll()
        #expect(accounts.count == 1)
        #expect(accounts.first == updated)

        try await accountRepository.delete(updated)
        let deletedAccount = try await accountRepository.fetchBy(id: updated.id)
        #expect(deletedAccount == nil)
    }
}
