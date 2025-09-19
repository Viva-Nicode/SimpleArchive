import Foundation
import CoreData

extension MemoDirectoryEntity {

    @nonobjc public class func fetchAllRootDirectoriesRequest() -> NSFetchRequest<MemoDirectoryEntity> {
        let request = NSFetchRequest<MemoDirectoryEntity>(entityName: "MemoDirectoryEntity")
        request.predicate = NSPredicate(format: "parentDirectory == nil")
        return request
    }

    @nonobjc public class func findDirectoryEntityById(id: UUID) -> NSFetchRequest<MemoDirectoryEntity> {
        let fetchRequest = NSFetchRequest<MemoDirectoryEntity>(entityName: "MemoDirectoryEntity")
        let fetchPredicate = NSPredicate(format: "%K == %@", (\MemoDirectoryEntity.id)._kvcKeyPathString!, id as CVarArg)
        fetchRequest.predicate = fetchPredicate
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    @NSManaged public var sortBy: String
    @NSManaged public var childDirectories: Set<MemoDirectoryEntity>
    @NSManaged public var pages: Set<MemoPageEntity>
    @NSManaged public var parentDirectory: MemoDirectoryEntity?

}

// MARK: Generated accessors for childDirectories
extension MemoDirectoryEntity {

    @objc(addChildDirectoriesObject:)
    @NSManaged public func addToChildDirectories(_ value: MemoDirectoryEntity)

    @objc(removeChildDirectoriesObject:)
    @NSManaged public func removeFromChildDirectories(_ value: MemoDirectoryEntity)

    @objc(addChildDirectories:)
    @NSManaged public func addToChildDirectories(_ values: NSSet)

    @objc(removeChildDirectories:)
    @NSManaged public func removeFromChildDirectories(_ values: NSSet)

}

// MARK: Generated accessors for pages
extension MemoDirectoryEntity {

    @objc(addPagesObject:)
    @NSManaged public func addToPages(_ value: MemoPageEntity)

    @objc(removePagesObject:)
    @NSManaged public func removeFromPages(_ value: MemoPageEntity)

    @objc(addPages:)
    @NSManaged public func addToPages(_ values: NSSet)

    @objc(removePages:)
    @NSManaged public func removeFromPages(_ values: NSSet)

}
