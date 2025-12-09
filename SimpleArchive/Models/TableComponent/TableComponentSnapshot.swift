import Foundation
import CoreData

struct TableComponentSnapshot: ComponentSnapshotType {

    var snapshotID: UUID
    var makingDate: Date
    var description: String
    var saveMode: SnapshotSaveMode
    var detail: TableComponentContents

    init(
        snapshotID: UUID = UUID(),
        makingDate: Date = Date(),
        detail: TableComponentContents,
        description: String,
        saveMode: SnapshotSaveMode
    ) {
        self.snapshotID = snapshotID
        self.makingDate = makingDate
        self.detail = detail
        self.description = description
        self.saveMode = saveMode
    }

    func revert(component: TableComponent) {
        component.componentContents = self.detail
    }
}

