import Foundation
import CoreData

extension TextEditorComponentSnapshotEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextEditorComponentSnapshotEntity> {
        return NSFetchRequest<TextEditorComponentSnapshotEntity>(entityName: "TextEditorComponentSnapshotEntity")
    }

    @NSManaged public var contents: String
    @NSManaged public var makingDate: Date
    @NSManaged public var saveMode: String
    @NSManaged public var snapShotDescription: String
    @NSManaged public var snapshotID: UUID
    @NSManaged public var component: TextEditorComponentEntity

}

extension TextEditorComponentSnapshotEntity: Identifiable {

}
