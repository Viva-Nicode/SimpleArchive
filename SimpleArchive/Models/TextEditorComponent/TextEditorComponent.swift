import Combine
import Foundation

final class TextEditorComponent: NSObject, Codable, SnapshotRestorablePageComponent {

    var id: UUID
    var renderingOrder: Int
    var isMinimumHeight: Bool
    var type: ComponentType { .text }
    var creationDate: Date
    var title: String
    var componentContents: String { didSet { captureState = .needsCapture } }
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

    deinit { myLog(String(describing: Swift.type(of: self)), "\(title)", c: .purple) }

    func insertTrackingSnapshot(trackingSnapshot: any ComponentSnapshotType) {
        if let textEditorComponentSnapshot = trackingSnapshot as? TextEditorComponentSnapshot {
            snapshots.insert(textEditorComponentSnapshot, at: 0)
            actions = []
            captureState = .captured
        }
    }

    func revertComponentContentsUsingSnapshot(snapshotID: UUID) {
        if let targetSnapshotIndex = snapshots.firstIndex(where: { $0.snapshotID == snapshotID }) {
            snapshots[targetSnapshotIndex].revert(component: self)
            captureState = .captured
        }
    }

    // MARK: - ⚠️ 얘가 암시적으로 뷰 관련 로직에 영향을 받는 로직 아니야?
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
