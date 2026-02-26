import Combine
import CoreData
import UIKit

protocol SnapshotRestorablePageComponent: PageComponent {
    associatedtype SnapshotType: ComponentSnapshotType

    var snapshots: [SnapshotType] { get set }
    var captureState: CaptureState { get set }

    func insertTrackingSnapshot(trackingSnapshot: any ComponentSnapshotType)
    func revertComponentContentsUsingSnapshot(snapshotID: UUID)
    func removeSnapshot(at: Int)
}

extension SnapshotRestorablePageComponent {
    func revertComponentContentsUsingSnapshot(snapshotID: UUID) {
        if let targetSnapshotIndex = snapshots.firstIndex(where: { $0.snapshotID == snapshotID }) {
            snapshots[targetSnapshotIndex].revert(component: self as! Self.SnapshotType.ComponentType)
            captureState = .captured
        }
    }
	
    func removeSnapshot(at: Int) { snapshots.remove(at: at) }
}

enum CaptureState: Codable, Equatable {
    case needsCapture
    case captured
}
