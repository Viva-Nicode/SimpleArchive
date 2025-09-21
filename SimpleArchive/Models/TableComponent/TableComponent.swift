import Foundation

final class TableComponent: NSObject, Codable, PageComponent, SnapshotRestorable {

    var id: UUID
    var renderingOrder: Int
    var isMinimumHeight: Bool
    var type: ComponentType { .table }
    var creationDate: Date
    var title: String
    var detail: TableComponentContent
    var componentDetail: TableComponentContent { detail }
    var persistenceState: PersistentState
    var snapshots: [TableComponentSnapshot] = []

    init(
        id: UUID = UUID(),
        renderingOrder: Int = 0,
        isMinimumHeight: Bool = false,
        creationDate: Date = Date(),
        title: String = "TableMemo",
        detail: DetailType = TableComponentContent(),
        persistenceState: PersistentState = .synced,
        componentSnapshots: [TableComponentSnapshot] = []
    ) {
        self.id = id
        self.renderingOrder = renderingOrder
        self.isMinimumHeight = isMinimumHeight
        self.creationDate = creationDate
        self.title = title
        self.detail = detail
        self.persistenceState = persistenceState
        self.snapshots = componentSnapshots
    }

    deinit { print("deinit TableComponentModel : \(title)") }

    @discardableResult
    func makeSnapshot(desc: String, saveMode: SnapshotSaveMode) -> TableComponentSnapshot {
        let snapshot = TableComponentSnapshot(detail: self.detail, description: desc, saveMode: saveMode)
        snapshots.insert(snapshot, at: 0)
        return snapshot
    }

    func revertToSnapshot(snapshotID: UUID) throws(ComponentSnapshotViewModelError) {
        if let idx = snapshots.firstIndex(where: { $0.snapshotID == snapshotID }) {
            snapshots[idx].revert(component: self)
            persistenceState = .unsaved(isMustToStoreSnapshot: false)
        } else {
            throw .canNotFoundSnapshot(snapshotID)
        }
    }

    func removeSnapshot(snapshotID: UUID) throws(ComponentSnapshotViewModelError) -> (
        nextViewedSnapshotIndex: Int?, removedSnapshotIndex: Int
    ) {
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
