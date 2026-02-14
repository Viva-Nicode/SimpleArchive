import Combine
import UIKit

final class PageComponentSnapshotViewFactory: PageComponentSnapshotViewFactoryType {

    var input: PassthroughSubject<ComponentSnapshotViewModel.Action, Never>
    var indexPath: IndexPath?

    weak var collectionView: UICollectionView?

    init(input: PassthroughSubject<ComponentSnapshotViewModel.Action, Never>) {
        self.input = input
    }

    func makeComponentSnapshotView(from snapshot: any ComponentSnapshotType) -> UICollectionViewCell {
        guard let collectionView, let indexPath else { return UICollectionViewCell() }

        switch snapshot {
            case let textComponentSnapshot as TextEditorComponentSnapshot:
                let cell =
                    collectionView
                    .dequeueReusableCell(
                        withReuseIdentifier: TextEditorComponentView.reuseIdentifier,
                        for: indexPath) as! TextEditorComponentView

                cell.configureTextComponentForSnapshotView(
                    snapshotID: textComponentSnapshot.snapshotID,
                    snapshotDetail: textComponentSnapshot.snapshotContents,
                    snapshotDispatcher: input)

                return cell

            case let tableComponentSnapshot as TableComponentSnapshot:
                let cell =
                    collectionView
                    .dequeueReusableCell(
                        withReuseIdentifier: TableComponentView.reuseIdentifier,
                        for: indexPath
                    ) as! TableComponentView

                cell.configure(
                    snapshotID: tableComponentSnapshot.snapshotID,
                    snapshotDetail: tableComponentSnapshot.snapshotContents,
                    snapshotActionDispatcher: input)

                return cell

            default:
                return UICollectionViewCell()
        }
    }
}
