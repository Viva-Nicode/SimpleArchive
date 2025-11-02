import UIKit

extension MemoHomeTableView: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        directoryContents?.getChildItemSize() ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let storageItem = directoryContents![indexPath.row]!
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: MemoTableRowView.cellId,
                for: indexPath) as! MemoTableRowView

        cell.configure(with: storageItem)
        tableView.isUserInteractionEnabled = true
        return cell
    }
}

extension MemoHomeTableView: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

        let showFileInfomation =
            UIContextualAction(style: .normal, title: "share") { (_, _, success: @escaping (Bool) -> Void) in
                self.subject?.send(.showFileInformation(indexPath.row))
                success(true)
            }

        let removeFile =
            UIContextualAction(style: .normal, title: "remove") { (_, _, success: @escaping (Bool) -> Void) in
                self.subject?.send(.removeFile(indexPath.row))
                tableView.deleteRows(at: [indexPath], with: .fade)
                success(true)
            }

        showFileInfomation.backgroundColor = .systemBlue
        showFileInfomation.image = UIImage(systemName: "info.circle")
        removeFile.backgroundColor = .systemRed
        removeFile.image = UIImage(systemName: "trash.fill")
        removeFile.accessibilityLabel = "removeFile"

        return UISwipeActionsConfiguration(actions: [removeFile, showFileInfomation])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileTapped = directoryContents![indexPath.row]!

        switch fileTapped {
            case is MemoPageModel:
                self.subject?.send(.didTappedPageRow(indexPath.row))

            case is MemoDirectoryModel:
                tableView.isUserInteractionEnabled = false
                self.subject?.send(.didTappedDirectoryRow(indexPath.row))

            default:
                break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 50 }
}

extension MemoHomeTableView: UITableViewDragDelegate {

    func tableView(
        _ tableView: UITableView, itemsForBeginning session: any UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {

        let file = directoryContents![indexPath.row]!

        if let page = file as? MemoPageModel {
            session.localContext = LocalDragContext(
                ispopedFixedDirectoryTable: false,
                isdroppedFixedDirectoryTable: false)

            let itemProvider = NSItemProvider(object: page)
            return [UIDragItem(itemProvider: itemProvider)]
        }
        return []
    }

    func tableView(
        _ tableView: UITableView, dropSessionDidUpdate session: any UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UITableViewDropProposal {

        if session.localDragSession != nil {
            let localDragContext = session.localDragSession!.localContext as! LocalDragContext
            localDragContext.isdroppedFixedDirectoryTable = false
            if localDragContext.ispopedFixedDirectoryTable {
                return UITableViewDropProposal(operation: .copy)
            } else {
                return UITableViewDropProposal(operation: .cancel)
            }
        } else {
            return UITableViewDropProposal(operation: .cancel)
        }
    }
}

extension MemoHomeTableView: UITableViewDropDelegate {

    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        coordinator.session.loadObjects(ofClass: MemoPageModel.self) { [self] items in
            guard let pages = items as? [MemoPageModel] else { return }
            subject?.send(.didPerformDropOperationInHomeTable(pages))
        }
    }

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: MemoPageModel.self)
    }
}
