import CoreData
import Foundation

@objc(MemoPageEntity)
public class MemoPageEntity: StorageItemEntity {

    @discardableResult
    override func convertToModel(parentDirectory: MemoDirectoryModel?) -> any StorageItem {
        let page = MemoPageModel(
            id: self.id,
            name: self.name,
            creationDate: self.creationDate,
            isSingleComponentPage: self.isSingleComponentPage,
            parentDirectory: parentDirectory,
            components: self.components
                .compactMap { $0.convertToModel() }
                .sorted { $0.renderingOrder < $1.renderingOrder })

        return page
    }

    override func moveToDormantBox(in ctx: NSManagedObjectContext, dormantBox: MemoDirectoryEntity) {
        components.forEach { $0.isMinimumHeight = false }
        self.containingDirectory.removeFromPages(self)
        dormantBox.addToPages(self)
    }
}

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
    @NSManaged public var isSingleComponentPage: Bool
}

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
