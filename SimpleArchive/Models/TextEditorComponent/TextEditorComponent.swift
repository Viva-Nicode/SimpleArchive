import Combine
import Foundation

enum TextEditorComponentAction: Codable {
    case insert(range: Range<Int>, text: String)
    case replace(range: Range<Int>, from: String, to: String)
}

final class TextEditorComponent: NSObject, Codable, SnapshotRestorablePageComponent {

    var id: UUID
    var renderingOrder: Int
    var isMinimumHeight: Bool
    var type: ComponentType { .text }
    var creationDate: Date
    var title: String
    var componentContents: String
    var captureState: CaptureState
    var snapshots: [TextEditorComponentSnapshot] = []
    var actions: [TextEditorComponentAction] = []

    init(
        id: UUID = UUID(),
        renderingOrder: Int = 0,
        isMinimumHeight: Bool = false,
        creationDate: Date = Date(),
        title: String = "Memo",
        contents: ContentType = "",
        captureState: CaptureState = .captured,
        componentSnapshots: [TextEditorComponentSnapshot] = []
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

    deinit { print("deinit TextEditorComponentModel : \(title)") }

    @discardableResult
    func makeSnapshot(desc: String, saveMode: SnapshotSaveMode) -> TextEditorComponentSnapshot {
        let snapshot = TextEditorComponentSnapshot(contents: componentContents, description: desc, saveMode: saveMode)
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
