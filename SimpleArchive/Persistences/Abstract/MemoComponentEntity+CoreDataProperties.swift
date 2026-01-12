import Foundation
import CoreData

extension MemoComponentEntity {

    @NSManaged public var id: UUID
    @NSManaged public var creationDate: Date
    @NSManaged public var isMinimumHeight: Bool
    @NSManaged public var renderingOrder: Int
    @NSManaged public var title: String
    @NSManaged public var type: String
    @NSManaged public var containingPage: MemoPageEntity

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemoComponentEntity> {
        return NSFetchRequest<MemoComponentEntity>(entityName: "MemoComponentEntity")
    }

    @nonobjc public class func findById(id: UUID) -> NSFetchRequest<MemoComponentEntity> {
        let fetchRequest = NSFetchRequest<MemoComponentEntity>(entityName: "MemoComponentEntity")
        let fetchPredicate = NSPredicate(format: "%K == %@", (\MemoComponentEntity.id)._kvcKeyPathString!, id as CVarArg)
        fetchRequest.predicate = fetchPredicate
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }
}

extension MemoComponentEntity: Identifiable {

}
