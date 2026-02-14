import CoreData
import Foundation

struct TextEditorComponentSnapshot: ComponentSnapshotType {
    typealias ComponentType = TextEditorComponent

    var snapshotID: UUID
    var makingDate: Date
    var description: String
    var saveMode: SnapshotSaveMode
    var snapshotContents: String
    var modificationHistory: [TextEditorComponentAction]

    init(
        snapshotID: UUID = UUID(),
        makingDate: Date = Date(),
        contents: String,
        description: String,
        saveMode: SnapshotSaveMode,
        modificationHistory: [TextEditorComponentAction]
    ) {
        self.snapshotID = snapshotID
        self.makingDate = makingDate
        self.snapshotContents = contents
        self.description = description
        self.saveMode = saveMode
        self.modificationHistory = modificationHistory
    }

    func revert(component: TextEditorComponent) {
        component.componentContents = snapshotContents
    }

    func isEqual(to other: any ComponentSnapshotType) -> Bool {
        if let otherSnapshot = other as? Self {
            return self.snapshotContents == otherSnapshot.snapshotContents
        } else {
            return false
        }
    }
}
