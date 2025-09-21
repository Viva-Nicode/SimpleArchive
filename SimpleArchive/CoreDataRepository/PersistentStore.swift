import Combine
import CoreData

protocol PersistentStore {
    func fetch<T, V>(_ fetchRequest: NSFetchRequest<T>, map: @escaping (T) throws -> V?) -> AnyPublisher<[V], Error>

    @discardableResult
    func update<Result>(_ operation: @escaping (NSManagedObjectContext) throws -> Result) -> AnyPublisher<Result, Error>
}
