import Foundation

final class TableComponent: NSObject, Codable, SnapshotRestorablePageComponent {

    typealias Coordinate = (rowIndex: Int, columnIndex: Int)

    var id: UUID
    var renderingOrder: Int
    var isMinimumHeight: Bool
    var type: ComponentType { .table }
    var creationDate: Date
    var title: String
    var componentContents: TableComponentContents { didSet { captureState = .needsCapture } }
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

    /* MARK: - 📄 insertTrackingSnapshot(trackingSnapshot:)
     트래킹 스냅샷은 코어데이터 엔티티와 모델상 으로만 존재하고 실제 컴포넌트의 snpashot배열에 들어가있지 않아서 사용자에게 보여지지 않는다.
	 따라서 스냅샷을 snapshot배열에 추가해서 사용자에게 보여지게 만들고 새로운 추적중인 스냅샷을 반환한다.
     이 함수가 쓰이는 이유는 수동캡쳐, 또는 스냅샷으로 복원시이다.
     */
    func insertTrackingSnapshot(trackingSnapshot: any ComponentSnapshotType) {
        if let tableComponentSnapshot = trackingSnapshot as? TableComponentSnapshot {
            snapshots.insert(tableComponentSnapshot, at: 0)
            actions = []
            captureState = .captured
        }
    }
}
