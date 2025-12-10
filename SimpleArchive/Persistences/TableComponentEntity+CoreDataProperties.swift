import CoreData
import Foundation

extension TableComponentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TableComponentEntity> {
        return NSFetchRequest<TableComponentEntity>(entityName: "TableComponentEntity")
    }

    @nonobjc public class func findTableComponentEntityById(id: UUID) -> NSFetchRequest<TableComponentEntity> {
        let fetchRequest = NSFetchRequest<TableComponentEntity>(entityName: "TableComponentEntity")
        let fetchPredicate = NSPredicate(
            format: "%K == %@", (\TableComponentEntity.id)._kvcKeyPathString!, id as CVarArg)
        fetchRequest.predicate = fetchPredicate
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    @NSManaged public var sortBy: String
    @NSManaged public var columns: NSMutableOrderedSet
    @NSManaged public var rows: NSMutableOrderedSet

    @NSManaged public var snapshots: Set<TableComponentSnapshotEntity>
}

// MARK: Generated accessors for snapshots
extension TableComponentEntity {

    @objc(addSnapshotsObject:)
    @NSManaged public func addToSnapshots(_ value: TableComponentSnapshotEntity)

    @objc(removeSnapshotsObject:)
    @NSManaged public func removeFromSnapshots(_ value: TableComponentSnapshotEntity)

    @objc(addSnapshots:)
    @NSManaged public func addToSnapshots(_ values: NSSet)

    @objc(removeSnapshots:)
    @NSManaged public func removeFromSnapshots(_ values: NSSet)

}
