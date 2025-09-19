import Combine
import CoreData
import UIKit

protocol SnapshotRestorable {
    associatedtype SnapshotType: ComponentSnapshotType

    var snapshots: [SnapshotType] { get }

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
