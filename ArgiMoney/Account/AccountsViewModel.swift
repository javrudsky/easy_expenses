import Foundation
import Combine

@MainActor
protocol AccountsViewModel: ObservableObject {
    var accounts: [Account] { get }
    func load() async
    func add()
    func save(_ account: Account) async throws
    func delete(at offsets: IndexSet) async throws
}

@MainActor
final class DefaultAccountsViewModel: AccountsViewModel {
    @Published var accounts: [Account] = []
    private let repository: AccountRepository

    init(repo: AccountRepository) {
        self.repository = repo
        Task { await load() }
    }

    func load() async {
        if let list = try? await repository.fetchAll() {
            accounts = list
        }
    }

    func add() {
        accounts.append(Account(name: "New Account"))
    }

    func save(_ account: Account) async throws {
        try await repository.insertOrUpdate(account)
        await load()
    }

    func delete(at offsets: IndexSet) async throws {
        for index in offsets { try await repository.delete(accounts[index]) }
        await load()
    }
}
