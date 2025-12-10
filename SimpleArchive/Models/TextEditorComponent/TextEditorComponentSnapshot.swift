import Foundation
import CoreData

struct TextEditorComponentSnapshot: ComponentSnapshotType {

    let snapshotID: UUID
    let makingDate: Date
    let contents: String
    let description: String
    let saveMode: SnapshotSaveMode

    init(
        snapshotID: UUID = UUID(),
        makingDate: Date = Date(),
        contents: String,
        description: String,
        saveMode: SnapshotSaveMode
    ) {
        self.snapshotID = snapshotID
        self.makingDate = makingDate
        self.contents = contents
        self.description = description
        self.saveMode = saveMode
    }

    func revert(component: TextEditorComponent) {
        component.componentContents = self.contents
    }
}
