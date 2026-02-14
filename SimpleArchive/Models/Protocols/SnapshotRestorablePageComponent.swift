import Combine
import CoreData
import UIKit

protocol SnapshotRestorablePageComponent: PageComponent {
    associatedtype SnapshotType: ComponentSnapshotType

    var snapshots: [SnapshotType] { get set }
    var captureState: CaptureState { get set }

    func insertTrackingSnapshot(trackingSnapshot: any ComponentSnapshotType)
    func revertComponentContentsUsingSnapshot(snapshotID: UUID)
    func removeSnapshot(snapshotID: UUID) -> RemoveSnapshotResult
}

struct RemoveSnapshotResult {
    var removeSnapshotIndex: Int
    var nextSnapshotID: UUID?
    var nextSnapshotMetaData: SnapshotMetaData?
}

enum CaptureState: Codable, Equatable {
    case needsCapture
    case captured
}
