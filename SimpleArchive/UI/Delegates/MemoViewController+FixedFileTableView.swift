import UIKit

extension MemoHomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        input.send(.didTappedFixedPageRow(indexPath.row))
    }
}

class LocalDragContext {
    var ispopedFixedDirectoryTable: Bool
    var isdroppedFixedDirectoryTable: Bool

    init(ispopedFixedDirectoryTable: Bool, isdroppedFixedDirectoryTable: Bool) {
        self.ispopedFixedDirectoryTable = ispopedFixedDirectoryTable
        self.isdroppedFixedDirectoryTable = isdroppedFixedDirectoryTable
    }
}

extension MemoHomeViewController: UITableViewDragDelegate {

    // 드래그가 시작되었을 때 드래그된 요소를 드래그 가능한 객체로만들어 반환해주는 함수
    func tableView(_ tableView: UITableView, itemsForBeginning session: any UIDragSession,
        at indexPath: IndexPath) -> [UIDragItem] {

        let file = viewModel.fixedFileDirectory[indexPath.row]!

        if let page = file as? MemoPageModel {
            session.localContext = LocalDragContext(
                ispopedFixedDirectoryTable: true,
                isdroppedFixedDirectoryTable: true)

            let itemProvider = NSItemProvider(object: page)
            return [UIDragItem(itemProvider: itemProvider)]
        }
        return []
    }

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: any UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {

        if session.localDragSession != nil {
            let localDragContext = session.localDragSession!.localContext as! LocalDragContext
            localDragContext.isdroppedFixedDirectoryTable = true
            if localDragContext.ispopedFixedDirectoryTable {
                return UITableViewDropProposal(operation: .cancel)
            } else {
                return UITableViewDropProposal(operation: .copy)
            }
        } else {
            return UITableViewDropProposal(operation: .cancel)
        }
    }
}

extension MemoHomeViewController: UITableViewDropDelegate {

    /// 드랍이 발생했을 때
    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        coordinator.session.loadObjects(ofClass: MemoPageModel.self) { [self] items in
            guard let pages = items as? [MemoPageModel] else { return }
            input.send(.didPerformDropOperationInFixedTable(pages))
        }
    }

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: MemoPageModel.self)
    }
}

extension MemoHomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize { collectionView.bounds.size }
}


