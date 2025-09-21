import Foundation
import CoreData

struct TextEditorComponentSnapshot: ComponentSnapshotType {

    let snapshotID: UUID
    let makingDate: Date
    let detail: String
    let description: String
    let saveMode: SnapshotSaveMode

    init(
        snapshotID: UUID = UUID(),
        makingDate: Date = Date(),
        detail: String,
        description: String,
        saveMode: SnapshotSaveMode
    ) {
        self.snapshotID = snapshotID
        self.makingDate = makingDate
        self.detail = detail
        self.description = description
        self.saveMode = saveMode
    }

    func revert(component: TextEditorComponent) {
        component.detail = self.detail
    }
}
