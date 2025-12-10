import Foundation
import CoreData

struct TableComponentSnapshot: ComponentSnapshotType {

    var snapshotID: UUID
    var makingDate: Date
    var description: String
    var saveMode: SnapshotSaveMode
    var contents: TableComponentContents

    init(
        snapshotID: UUID = UUID(),
        makingDate: Date = Date(),
        contents: TableComponentContents,
        description: String,
        saveMode: SnapshotSaveMode
    ) {
        self.snapshotID = snapshotID
        self.makingDate = makingDate
        self.contents = contents
        self.description = description
        self.saveMode = saveMode
    }

    func revert(component: TableComponent) {
        component.componentContents = self.contents
    }
}

