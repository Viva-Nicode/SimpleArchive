import CoreData
import Foundation

@objc(TextEditorComponentSnapshotEntity)
public class TextEditorComponentSnapshotEntity: NSManagedObject, Identifiable {
    func convertToModel() -> TextEditorComponentSnapshot {
        let converter = JsonConverter.shared
        return TextEditorComponentSnapshot(
            snapshotID: self.snapshotID,
            makingDate: self.makingDate,
            contents: self.contents,
            description: self.snapShotDescription,
            saveMode: .init(rawValue: self.saveMode) ?? .automatic,
            modificationHistory: self.modificationHistory == nil
                ? [] : converter.decode([TextEditorComponentAction].self, jsonString: self.modificationHistory!)!)
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
    @NSManaged public var modificationHistory: String?

}

extension TextEditorComponentSnapshotEntity: PageComponentSnapshotEntity {
    func updateTrackingSnapshotContents(snapshot: any ComponentSnapshotType) {
        let converter = JsonConverter.shared
        if let textEditorComponentSnapshot = snapshot as? TextEditorComponentSnapshot {
            contents = textEditorComponentSnapshot.snapshotContents
            modificationHistory = converter.encode(object: textEditorComponentSnapshot.modificationHistory)
        }
    }
}
