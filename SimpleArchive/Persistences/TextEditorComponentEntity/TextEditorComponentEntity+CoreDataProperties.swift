import Foundation
import CoreData

extension TextEditorComponentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextEditorComponentEntity> {
        return NSFetchRequest<TextEditorComponentEntity>(entityName: "TextEditorComponentEntity")
    }

    @nonobjc public class func findTextComponentEntityById(id: UUID) -> NSFetchRequest<TextEditorComponentEntity> {
        let fetchRequest = NSFetchRequest<TextEditorComponentEntity>(entityName: "TextEditorComponentEntity")
        let fetchPredicate = NSPredicate(format: "%K == %@", (\TextEditorComponentEntity.id)._kvcKeyPathString!, id as CVarArg)
        fetchRequest.predicate = fetchPredicate
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    @NSManaged public var contents: String
    @NSManaged public var snapshots: Set<TextEditorComponentSnapshotEntity>

}

// MARK: Generated accessors for snapshots
extension TextEditorComponentEntity {

    @objc(addSnapshotsObject:)
    @NSManaged public func addToSnapshots(_ value: TextEditorComponentSnapshotEntity)

    @objc(removeSnapshotsObject:)
    @NSManaged public func removeFromSnapshots(_ value: TextEditorComponentSnapshotEntity)

    @objc(addSnapshots:)
    @NSManaged public func addToSnapshots(_ values: NSSet)

    @objc(removeSnapshots:)
    @NSManaged public func removeFromSnapshots(_ values: NSSet)

}
