import Combine
import UIKit

final class PageComponentSnapshotViewFactory: PageComponentSnapshotViewFactoryType {

    var input: PassthroughSubject<ComponentSnapshotViewModelInput, Never>
    var indexPath: IndexPath?

    weak var collectionView: UICollectionView?

    init(input: PassthroughSubject<ComponentSnapshotViewModelInput, Never>) {
        self.input = input
    }

    func makeComponentSnapshotView(from snapshot: any ComponentSnapshotType) -> UICollectionViewCell {
        guard let collectionView, let indexPath else { return UICollectionViewCell() }

        switch snapshot {
            case let textComponentSnapshot as TextEditorComponentSnapshot:
                let cell =
                    collectionView
                    .dequeueReusableCell(
                        withReuseIdentifier: TextEditorComponentView.identifierForUseCollectionView,
                        for: indexPath) as! TextEditorComponentView

                cell.configureTextComponentForSnapshotView(
                    snapshotID: textComponentSnapshot.snapshotID,
                    snapshotDetail: textComponentSnapshot.contents,
                    input: input)

                return cell

            case let tableComponentSnapshot as TableComponentSnapshot:
                let cell =
                    collectionView
                    .dequeueReusableCell(
                        withReuseIdentifier: TableComponentView.reuseTableComponentIdentifier,
                        for: indexPath
                    ) as! TableComponentView

                cell.configure(
                    snapshotID: tableComponentSnapshot.snapshotID,
                    snapshotDetail: tableComponentSnapshot.contents,
                    input: input)

                return cell

            default:
                return UICollectionViewCell()
        }
    }
}
