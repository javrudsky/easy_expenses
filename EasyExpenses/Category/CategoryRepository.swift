import Foundation
import SwiftData

protocol CategoryRepository: ModelActor {
    func fetchAll() async throws -> [Category]
    func insertOrUpdate(_ category: Category) async throws
    func delete(_ category: Category) async throws
}

actor SwiftDataCategoryRepository: CategoryRepository {
    nonisolated let modelContainer: ModelContainer
    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let mapper: CategoryMapper

    private let modelContext: ModelContext

    init(modelContainer: ModelContainer, mapper: CategoryMapper = DefaultCategoryMapper()) {
        self.modelContainer = modelContainer
        self.mapper = mapper
        let c = ModelContext(modelContainer)
        self.modelContext = c
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: c)
    }

    func fetchAll() async throws -> [Category] {
        let all: [CategoryModel] = try getAll()
        return all.map { mapper.toDomain($0) }
    }

    func insertOrUpdate(_ category: Category) async throws {
        if let obj: CategoryModel = try getBy(id: category.id) {
            obj.name = category.name
            try await save()
        } else {
            try insert(mapper.toModel(category))
        }
    }

    func delete(_ category: Category) async throws {
        _ = try await deleteBy(id: category.id)
    }

    // MARK: - Private helpers
    func save() async throws { try modelContext.save() }

    @discardableResult
    func deleteBy(id: UUID) async throws -> CategoryModel? {
        let obj = try getBy(id: id)
        guard let obj else { return nil }
        modelContext.delete(obj)
        try modelContext.save()
        return obj
    }

    private func getBy(id: UUID) throws -> CategoryModel? {
        let predicate = #Predicate<CategoryModel> { model in model.id == id }
        let objs = try modelContext.fetch(FetchDescriptor<CategoryModel>(predicate: predicate))
        return objs.first
    }

    private func getAll() throws -> [CategoryModel] {
        return try modelContext.fetch(FetchDescriptor<CategoryModel>())
    }

    private func insert(_ item: CategoryModel) throws {
        modelContext.insert(item)
        try modelContext.save()
    }
}
