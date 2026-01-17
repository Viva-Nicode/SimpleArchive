import Combine
import UIKit

extension TextEditorComponent {
    
    func getCollectionViewSnapShotCell(
        _ collectionView: UICollectionView,
        _ index: IndexPath,
        subject: PassthroughSubject<ComponentSnapshotViewModelInput, Never>
    ) -> UICollectionViewCell {

        let cell =
            collectionView
            .dequeueReusableCell(
                withReuseIdentifier: TextEditorComponentView.identifierForUseCollectionView,
                for: index) as! TextEditorComponentView

        cell.configure(
            snapshotID: snapshots[index.item].snapshotID,
            snapshotDetail: snapshots[index.item].contents,
            title: title,
            createDate: creationDate,
            input: subject)
        return cell
    }
}

extension TableComponent {
    func getCollectionViewSnapShotCell(
        _ collectionView: UICollectionView,
        _ indexPath: IndexPath,
        subject: PassthroughSubject<ComponentSnapshotViewModelInput, Never>
    ) -> UICollectionViewCell {

        let cell =
            collectionView
            .dequeueReusableCell(
                withReuseIdentifier: TableComponentView.reuseTableComponentIdentifier,
                for: indexPath
            ) as! TableComponentView

        cell.configure(
            snapshotID: snapshots[indexPath.item].snapshotID,
            snapshotDetail: snapshots[indexPath.item].contents,
            title: title,
            createDate: creationDate,
            input: subject)

        return cell
    }
}
