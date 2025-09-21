import Combine
import UIKit

extension MemoPageViewController: UICollectionViewDelegateFlowLayout {

    /// 셀 사이즈
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath
    ) -> CGSize {

        let height =
            viewModel.memoPage[indexPath.item].isMinimumHeight
            ? UIConstants.componentMinimumHeight : collectionView.bounds.size.width - 40

        return CGSize(width: collectionView.bounds.size.width - 40, height: height)
    }

    /// 헤더 사이즈
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 30)
    }

    /// 푸터 사이즈
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 70)
    }

    /// 셀 사이 간격
    func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat { 25 }
}

extension MemoPageViewController: UICollectionViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}

extension MemoPageViewController: UICollectionViewDragDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: any UIDragSession, at indexPath: IndexPath
    ) -> [UIDragItem] {

        let dragedComponent = viewModel.memoPage[indexPath.item]

        switch dragedComponent.type {
            case .text:
                let itemProvider = NSItemProvider(object: dragedComponent as! TextEditorComponent)
                return [UIDragItem(itemProvider: itemProvider)]

            case .table:
                let itemProvider = NSItemProvider(object: dragedComponent as! TableComponent)
                return [UIDragItem(itemProvider: itemProvider)]
        }
    }

    func collectionView(
        _ collectionView: UICollectionView, dropSessionDidUpdate session: any UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
        if session.localDragSession != nil {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UICollectionViewDropProposal(operation: .cancel)
        }
    }
}

extension MemoPageViewController: UICollectionViewDropDelegate {

    func collectionView(
        _ collectionView: UICollectionView, performDropWith coordinator: any UICollectionViewDropCoordinator
    ) {

        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

        if let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath {
            collectionView.performBatchUpdates(
                {
                    input.send(.changeComponentOrder(sourceIndexPath.item, destinationIndexPath.item))
                    collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
                }, completion: nil)

            coordinator.drop(
                item.dragItem,
                toItemAt: IndexPath(item: max(0, destinationIndexPath.item), section: destinationIndexPath.section)
            )
        }
    }

    func collectionView(_ collectionView: UICollectionView, canHandle session: any UIDropSession) -> Bool {
        let supportedClasses: [NSItemProviderReading.Type] = [TextEditorComponent.self, TableComponent.self]
        return supportedClasses.contains { session.canLoadObjects(ofClass: $0) }
    }
}
