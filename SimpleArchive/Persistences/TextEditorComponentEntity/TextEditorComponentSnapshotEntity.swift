import CoreData
import Foundation

@objc(TextEditorComponentSnapshotEntity)
public class TextEditorComponentSnapshotEntity: NSManagedObject {
    func convertToModel() -> TextEditorComponentSnapshot {
        TextEditorComponentSnapshot(
            snapshotID: self.snapshotID,
            makingDate: self.makingDate,
            contents: self.contents,
            description: self.snapShotDescription,
            saveMode: .init(rawValue: self.saveMode) ?? .automatic)
    }
}

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
