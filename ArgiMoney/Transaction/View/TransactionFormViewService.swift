import Foundation
import Combine

@MainActor
protocol TransactionFormViewService {
    func getCategories() async -> [Category]
    func getAccounts() async -> [Account]
    func gridCategories(categories: [Category], selected: Category?) -> [Category]
}

@MainActor
final class DefaultTransactionFormViewService: TransactionFormViewService {

    // Data sources
    private let categoryRepo: CategoryRepository
    private let accountRepo: AccountRepository

    // Initializers
    init(dataStore: DataStore) {
        self.categoryRepo = dataStore.categoryRepo
        self.accountRepo = dataStore.accountRepo
    }
    
    func getCategories() async -> [Category] {
        return (try? await categoryRepo.fetchAll()) ?? []
    }

    func gridCategories(categories: [Category], selected: Category?) -> [Category] {
        let cSel = selected ?? categories[0]
        var gc = [cSel]
        let max = min(categories.count - 1, 8)
        if max > 0 {
            gc.append(contentsOf: categories.filter {$0.id != cSel.id}[..<max])
        }
        return gc
    }
    
    func getAccounts() async -> [Account] {
        return (try? await accountRepo.fetchAll()) ?? []
    }
}
