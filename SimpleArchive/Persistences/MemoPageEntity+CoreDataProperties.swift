import Foundation
import CoreData

extension MemoPageEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemoPageEntity> {
        return NSFetchRequest<MemoPageEntity>(entityName: "MemoPageEntity")
    }

    @nonobjc public class func findPageById(id: UUID) -> NSFetchRequest<MemoPageEntity> {
        let fetchRequest = NSFetchRequest<MemoPageEntity>(entityName: "MemoPageEntity")
        let fetchPredicate = NSPredicate(format: "%K == %@", (\MemoPageEntity.id)._kvcKeyPathString!, id as CVarArg)
        fetchRequest.predicate = fetchPredicate
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    
    @NSManaged public var components: Set<MemoComponentEntity>
    @NSManaged public var containingDirectory: MemoDirectoryEntity
    @NSManaged public var isSingleComponentPage:Bool

}

// MARK: Generated accessors for components
extension MemoPageEntity {

    @objc(addComponentsObject:)
    @NSManaged public func addToComponents(_ value: MemoComponentEntity)

    @objc(removeComponentsObject:)
    @NSManaged public func removeFromComponents(_ value: MemoComponentEntity)

    @objc(addComponents:)
    @NSManaged public func addToComponents(_ values: NSSet)

    @objc(removeComponents:)
    @NSManaged public func removeFromComponents(_ values: NSSet)

}
