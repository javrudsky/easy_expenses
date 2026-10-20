import Foundation
import SwiftData

protocol AccountRepository: ModelActor {
    func fetchBy(id: UUID) async throws -> Account?
    func fetchAll() async throws -> [Account]
    func insertOrUpdate(_ account: Account) async throws
    func delete(_ account: Account) async throws
}

actor SwiftDataAccountRepository: AccountRepository {
    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let mapper: AccountMapper

    init(modelContainer: ModelContainer, mapper: AccountMapper = DefaultAccountMapper()) {
        self.modelContainer = modelContainer
        self.mapper = mapper
        let c = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: c)
    }

    func fetchBy(id: UUID) async throws -> Account? {
        if let model = try getBy(id: id) {
            return mapper.toDomain(model)
        }
        return nil
    }

    func fetchAll() async throws -> [Account] {
        let all: [AccountModel] = try getAll()
        return all.map { mapper.toDomain($0) }
    }

    func insertOrUpdate(_ account: Account) async throws {
        if let obj: AccountModel = try getBy(id: account.id) {
            obj.name = account.name
        } else {
            insert(mapper.toModel(account))
        }
        try save()
    }

    func delete(_ account: Account) async throws {
        _ = try await deleteBy(id: account.id)
    }

    // MARK: - Private helpers
    private func save() throws {
        do {
            try modelContext.save()
        } catch {
            print("An error has occurred in \(String(describing: type(of: self))): \(error)")
            modelContext.rollback()
            throw error
        }
    }

    @discardableResult
    func deleteBy(id: UUID) async throws -> AccountModel? {
        let obj = try getBy(id: id)
        guard let obj else { return nil }
        modelContext.delete(obj)
        try save()
        return obj
    }

    private func getBy(id: UUID) throws -> AccountModel? {
        let predicate = #Predicate<AccountModel> { model in model.id == id }
        let objs = try modelContext.fetch(FetchDescriptor<AccountModel>(predicate: predicate))
        return objs.first
    }

    private func getAll() throws -> [AccountModel] {
        return try modelContext.fetch(FetchDescriptor<AccountModel>())
    }

    private func insert(_ item: AccountModel) {
        modelContext.insert(item)
    }
}
