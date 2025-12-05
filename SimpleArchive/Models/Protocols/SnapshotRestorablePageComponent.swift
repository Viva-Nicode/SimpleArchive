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
    func revertToSnapshot(snapshotID: UUID) throws(ComponentSnapshotViewModelError)
    func removeSnapshot(snapshotID: UUID) throws(ComponentSnapshotViewModelError)
        -> (nextViewedSnapshotIndex: Int?, removedSnapshotIndex: Int)

    func getCollectionViewSnapShotCell(
        _ collectionView: UICollectionView,
        _ indexPath: IndexPath,
        subject: PassthroughSubject<ComponentSnapshotViewModelInput, Never>
    ) -> UICollectionViewCell
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
