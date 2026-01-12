import Foundation
import CoreData

extension StorageItemEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StorageItemEntity> {
        return NSFetchRequest<StorageItemEntity>(entityName: "StorageItemEntity")
    }

    @nonobjc public class func findById(id: UUID) -> NSFetchRequest<StorageItemEntity> {
        let fetchRequest = NSFetchRequest<StorageItemEntity>(entityName: "StorageItemEntity")
        let fetchPredicate = NSPredicate(format: "%K == %@", (\StorageItemEntity.id)._kvcKeyPathString!, id as CVarArg)
        fetchRequest.predicate = fetchPredicate
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    @NSManaged public var creationDate: Date
    @NSManaged public var id: UUID
    @NSManaged public var name: String
}

extension StorageItemEntity: Identifiable {

}
