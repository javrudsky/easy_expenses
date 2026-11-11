import Foundation
import Combine

@MainActor
protocol ReportsViewModel: ObservableObject {
    var dataset: ReportDataset? { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    func load() async
}

@MainActor
final class DefaultReportsViewModel: ReportsViewModel {
    @Published private(set) var dataset: ReportDataset?
    @Published private(set) var isLoading = true
    @Published private(set) var errorMessage: String?

    private let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let transactions = try await dataStore.transactionRepo.fetchAll()
            let categories = try await dataStore.categoryRepo.fetchAll()
            let accounts = try await dataStore.accountRepo.fetchAll()
            dataset = ReportDataset(transactions: transactions,
                                    categories: categories,
                                    accounts: accounts,
                                    budgets: [])
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
