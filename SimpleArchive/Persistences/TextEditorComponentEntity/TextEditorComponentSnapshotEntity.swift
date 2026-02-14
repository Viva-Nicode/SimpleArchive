import CoreData
import Foundation

@objc(TextEditorComponentSnapshotEntity)
public class TextEditorComponentSnapshotEntity: NSManagedObject, Identifiable {
    func convertToModel() -> TextEditorComponentSnapshot {
        TextEditorComponentSnapshot(
            snapshotID: self.snapshotID,
            makingDate: self.makingDate,
            contents: self.contents,
            description: self.snapShotDescription,
            saveMode: .init(rawValue: self.saveMode) ?? .automatic,
            modificationHistory: convertToModificationHistory)
    }

    private var convertToModificationHistory: [TextEditorComponentAction] {
        guard
            let jsonString = self.modificationHistory,
            !jsonString.isEmpty,
            let data = jsonString.data(using: .utf8)
        else { return [] }

        do {
            return try JSONDecoder().decode([TextEditorComponentAction].self, from: data)
        } catch {
            assertionFailure("Failed to decode modificationHistory: \(error)")
            return []
        }
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
        if let textEditorComponentSnapshot = snapshot as? TextEditorComponentSnapshot {
            self.contents = textEditorComponentSnapshot.snapshotContents
            modificationHistory = textEditorComponentSnapshot.modificationHistory.jsonString
        }
    }
}
