import Combine
import Foundation

final class TextEditorComponent: NSObject, Codable, PageComponent, SnapshotRestorable {

    var id: UUID
    var renderingOrder: Int
    var isMinimumHeight: Bool
    var type: ComponentType { .text }
    var creationDate: Date
    var title: String
    var detail: String {
        didSet { persistenceState = .unsaved(isMustToStoreSnapshot: !detail.isEmpty) }
    }
    var persistenceState: PersistentState
    var componentDetail: String { detail }

    var snapshots: [TextEditorComponentSnapshot] = []

    init(
        id: UUID = UUID(),
        renderingOrder: Int = 0,
        isMinimumHeight: Bool = false,
        creationDate: Date = Date(),
        title: String = "Memo",
        detail: DetailType = "",
        persistenceState: PersistentState = .synced,
        componentSnapshots: [TextEditorComponentSnapshot] = []
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

    deinit { print("deinit TextEditorComponentModel : \(title)") }

    func assignDetail(subject: PassthroughSubject<String, Never>) -> AnyCancellable {
        subject.assign(to: \.detail, on: self)
    }

    @discardableResult
    func makeSnapshot(desc: String, saveMode: SnapshotSaveMode) -> TextEditorComponentSnapshot {
        let snapshot = TextEditorComponentSnapshot(detail: self.detail, description: desc, saveMode: saveMode)
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
