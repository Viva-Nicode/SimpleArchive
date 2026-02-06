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

    deinit { myLog(String(describing: Swift.type(of: self)), "\(title)", c: .purple) }

    @discardableResult
    func makeSnapshot(desc: String, saveMode: SnapshotSaveMode) -> TableComponentSnapshot {
        let snapshot = TableComponentSnapshot(contents: componentContents, description: desc, saveMode: saveMode)
        snapshots.insert(snapshot, at: 0)
        return snapshot
    }

    func revertToSnapshot(snapshotID: UUID) {
        if let targetSnapshotIndex = snapshots.firstIndex(where: { $0.snapshotID == snapshotID }) {
            snapshots[targetSnapshotIndex].revert(component: self)
            setCaptureState(to: .captured)
        }
    }

    func removeSnapshot(snapshotID: UUID) -> RemoveSnapshotResult {
        let targetSnapshotIndex = snapshots.firstIndex(where: { $0.snapshotID == snapshotID })!
        let nextSnapshotIndex =
            targetSnapshotIndex + 1 <= snapshots.count - 1
            ? targetSnapshotIndex + 1 : targetSnapshotIndex - 1
        let nextSnapshot =
            nextSnapshotIndex < 0
            ? nil : snapshots[nextSnapshotIndex]
        let result = RemoveSnapshotResult(
            removeSnapshotIndex: targetSnapshotIndex,
            nextSnapshotID: nextSnapshot?.snapshotID,
            nextSnapshotMetaData: nextSnapshot?.getSnapshotMetaData()
        )
        snapshots.remove(at: targetSnapshotIndex)
        return result
    }
}
