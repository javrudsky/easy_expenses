import Foundation
import SwiftData

/*
final class SwiftDataDatabase: Database {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll<M>() throws -> [M] where M: PersistentModel {
        return try context.fetch(FetchDescriptor<M>())
    }

    func insert<M>(_ model: M) throws where M: PersistentModel {
        context.insert(model)
        try context.save()
        // Try to find an existing model that matches this domain item
    }
    
    func update<M>(_ model: M) throws where M: PersistentModel {
        try context.save()
    }
    
    @discardableResult
    func deleteBy<M>(id: String) throws -> M? where M: PersistentModel {
        
        let obj: M? = try fetchBy(id: id)
        guard let obj else { return nil }
        context.delete(obj)
        try context.save()
        return obj
    }

    func save() throws {
        try context.save()
    }
    
    private func byIdDescriptor<M>(_ id: String) -> FetchDescriptor<M> where M: PersistentModel {
        let predicate = Predicate<M> { model in
            model.id == id
        }
        return FetchDescriptor<M>(predicate: predicate)
    }
    
    func fetchBy<M>(id: String)throws -> M? where M: PersistentModel {
        let descriptor: FetchDescriptor<M> = byIdDescriptor(id)
        let objs = try context.fetch(descriptor)
        return objs.first
    }
}
*/
