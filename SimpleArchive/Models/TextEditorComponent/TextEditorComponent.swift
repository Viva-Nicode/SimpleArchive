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
}
