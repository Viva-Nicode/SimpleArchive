import Foundation
import CoreData


extension TableComponentSnapshotEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TableComponentSnapshotEntity> {
        return NSFetchRequest<TableComponentSnapshotEntity>(entityName: "TableComponentSnapshotEntity")
    }

    @NSManaged public var detail: String
    @NSManaged public var makingDate: Date
    @NSManaged public var saveMode: String
    @NSManaged public var snapShotDescription: String
    @NSManaged public var snapshotID: UUID
    @NSManaged public var component: TableComponentEntity

}

extension TableComponentSnapshotEntity : Identifiable {

}
