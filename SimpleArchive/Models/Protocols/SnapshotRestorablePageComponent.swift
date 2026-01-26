import Combine
import CoreData
import UIKit

protocol SnapshotRestorablePageComponent: PageComponent {
    associatedtype SnapshotType: ComponentSnapshotType

    var snapshots: [SnapshotType] { get }
    var captureState: CaptureState { get set }

    func setCaptureState(to state: CaptureState)
    func currentIfUnsaved() -> Self?

    @discardableResult
    func makeSnapshot(desc: String, saveMode: SnapshotSaveMode) -> SnapshotType
    func revertToSnapshot(snapshotID: UUID)
    func removeSnapshot(snapshotID: UUID) -> RemoveSnapshotResult
}

struct RemoveSnapshotResult {
    var removeSnapshotIndex: Int
    var nextSnapshotID: UUID?
    var nextSnapshotMetaData: SnapshotMetaData?
}

extension SnapshotRestorablePageComponent {
    func setCaptureState(to state: CaptureState) {
        self.captureState = state
    }

    func currentIfUnsaved() -> Self? {
        switch self.captureState {
            case .needsCapture:
                return self

            case .captured:
                return nil
        }
    }
}

enum CaptureState: Codable, Equatable {
    case needsCapture
    case captured
}
