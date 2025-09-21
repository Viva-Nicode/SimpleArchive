import Combine
import UIKit

extension TextEditorComponent {

    func getCollectionViewComponentCell(
        _ collectionView: UICollectionView,
        _ indexPath: IndexPath,
        isReadOnly: Bool,
        subject: PassthroughSubject<MemoPageViewInput, Never>
    ) -> UICollectionViewCell {

        let cell =
            collectionView
            .dequeueReusableCell(
                withReuseIdentifier: TextEditorComponentView.identifierForUseCollectionView,
                for: indexPath
            ) as! TextEditorComponentView

        cell.configure(component: self, input: subject, isReadOnly: isReadOnly)
        return cell
    }

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
            snapshotDetail: snapshots[index.item].detail,
            title: title,
            createDate: creationDate,
            input: subject)
        return cell
    }
}

extension TableComponent {

    func getCollectionViewComponentCell(
        _ collectionView: UICollectionView,
        _ indexPath: IndexPath,
        isReadOnly: Bool,
        subject: PassthroughSubject<MemoPageViewInput, Never>
    ) -> UICollectionViewCell {
        let cell =
            collectionView
            .dequeueReusableCell(
                withReuseIdentifier: TableComponentView.reuseTableComponentIdentifier,
                for: indexPath
            ) as! TableComponentView

        cell.configure(component: self, input: subject, isReadOnly: false)

        return cell
    }

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
            snapshotDetail: snapshots[indexPath.item].detail,
            title: title,
            createDate: creationDate,
            input: subject)

        return cell
    }
}
