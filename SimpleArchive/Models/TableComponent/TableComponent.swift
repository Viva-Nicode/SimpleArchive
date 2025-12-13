import Foundation

enum TableComponentAction: Codable {
    case appendRow(row: TableComponentRow)
    case removeRow(rowID: UUID)
    case appendColumn(column: TableComponentColumn)
    case editColumn(columns: [TableComponentColumn])
    case editCellValue(rowID: UUID, columnID: UUID, value: String)
}

final class TableComponent: NSObject, Codable, SnapshotRestorablePageComponent {

    var id: UUID
    var renderingOrder: Int
    var isMinimumHeight: Bool
    var type: ComponentType { .table }
    var creationDate: Date
    var title: String
    var componentContents: TableComponentContents
    var captureState: CaptureState
    var snapshots: [TableComponentSnapshot] = []
    var actions: [TableComponentAction] = []

    init(
        id: UUID = UUID(),
        renderingOrder: Int = 0,
        isMinimumHeight: Bool = false,
        creationDate: Date = Date(),
        title: String = "TableMemo",
        contents: ContentType = TableComponentContents(),
        captureState: CaptureState = .captured,
        componentSnapshots: [TableComponentSnapshot] = []
    ) {
        self.id = id
        self.renderingOrder = renderingOrder
        self.isMinimumHeight = isMinimumHeight
        self.creationDate = creationDate
        self.title = title
        self.componentContents = contents
        self.captureState = captureState
        self.snapshots = componentSnapshots
    }

    deinit { print("deinit TableComponentModel : \(title)") }

    @discardableResult
    func makeSnapshot(desc: String, saveMode: SnapshotSaveMode) -> TableComponentSnapshot {
        let snapshot = TableComponentSnapshot(contents: componentContents, description: desc, saveMode: saveMode)
        snapshots.insert(snapshot, at: 0)
        return snapshot
    }

    func revertToSnapshot(snapshotID: UUID) throws(ComponentSnapshotViewModelError) {
        if let idx = snapshots.firstIndex(where: { $0.snapshotID == snapshotID }) {
            snapshots[idx].revert(component: self)
            setCaptureState(to: .captured)
        } else {
            throw .canNotFoundSnapshot(snapshotID)
        }
    }

    func removeSnapshot(snapshotID: UUID) throws(ComponentSnapshotViewModelError)
        -> (nextViewedSnapshotIndex: Int?, removedSnapshotIndex: Int)
    {
        guard let removedIndex = snapshots.firstIndex(where: { $0.snapshotID == snapshotID }) else {
            throw ComponentSnapshotViewModelError.canNotFoundSnapshot(snapshotID)
        }

        snapshots.remove(at: removedIndex)
        let nextSnapshotIndex = snapshots.indices.contains(removedIndex) ? removedIndex : snapshots.count - 1

        return (
            nextViewedSnapshotIndex: snapshots.isEmpty ? nil : nextSnapshotIndex,
            removedSnapshotIndex: removedIndex
        )
    }
}
