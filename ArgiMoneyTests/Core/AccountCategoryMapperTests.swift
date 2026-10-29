import Foundation
import Testing
@testable import ArgiMoney

@Suite("Account and category mapper tests")
struct AccountCategoryMapperTests {
    @Test
    func accountMapperRoundTripPreservesValues() {
        let account = Account(id: UUID(), name: "Savings")
        let mapper = DefaultAccountMapper()

        let model = mapper.toModel(account)
        let mapped = mapper.toDomain(model)

        #expect(model.id == account.id)
        #expect(model.name == account.name)
        #expect(mapped == account)
    }

    @Test
    func categoryMapperRoundTripPreservesValues() {
        let category = Category(id: UUID(), name: "Freelance", transactionType: .income)
        let mapper = DefaultCategoryMapper()

        let model = mapper.toModel(category)
        let mapped = mapper.toDomain(model)

        #expect(model.id == category.id)
        #expect(model.name == category.name)
        #expect(model.transactionType == TransactionType.income.rawValue)
        #expect(mapped == category)
    }

    @Test
    func categoryMapperDefaultsUnknownPersistedTypeToExpense() {
        let model = CategoryModel(id: UUID(), name: "Unknown", transactionType: "invalid")

        let category = DefaultCategoryMapper().toDomain(model)

        #expect(category.transactionType == .expense)
    }
}
