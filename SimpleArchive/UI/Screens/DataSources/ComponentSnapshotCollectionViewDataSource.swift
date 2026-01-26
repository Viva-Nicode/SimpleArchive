import Combine
import UIKit

final class ComponentSnapshotCollectionViewDataSource: NSObject, UICollectionViewDataSource {

    private let snapshotRestorableComponent: any SnapshotRestorablePageComponent
    private let factory: PageComponentSnapshotViewFactory

    init(
        snapshotRestorableComponent: any SnapshotRestorablePageComponent,
        factory: PageComponentSnapshotViewFactory
    ) {
        self.snapshotRestorableComponent = snapshotRestorableComponent
        self.factory = factory
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        snapshotRestorableComponent.snapshots.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        factory.indexPath = indexPath
        let snapshot = snapshotRestorableComponent.snapshots[indexPath.item]
        return factory.makeComponentSnapshotView(from: snapshot)
    }
}
