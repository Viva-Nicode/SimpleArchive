import CoreData
import Foundation

struct TableComponentSnapshot: ComponentSnapshotType {
    typealias ComponentType = TableComponent

    var snapshotID: UUID
    var makingDate: Date
    var description: String
    var saveMode: SnapshotSaveMode
    var snapshotContents: TableComponentContents
    var modificationHistory: [TableComponentAction]

    init(
        snapshotID: UUID = UUID(),
        makingDate: Date = Date(),
        contents: TableComponentContents,
        description: String,
        saveMode: SnapshotSaveMode,
        modificationHistory: [TableComponentAction]
    ) {
        self.snapshotID = snapshotID
        self.makingDate = makingDate
        self.snapshotContents = contents
        self.description = description
        self.saveMode = saveMode
        self.modificationHistory = modificationHistory
    }
	
	func revert(component: TableComponent) {
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
