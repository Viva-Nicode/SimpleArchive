import Combine
import UIKit

final class MemoHomeDirectoryContentCellDataSource: NSObject, UITableViewDataSource {

    private var directoryContents: MemoDirectoryModel
    private var input: PassthroughSubject<MemoHomeSubViewInput, Never>

    init(
        directoryContents: MemoDirectoryModel,
        input: PassthroughSubject<MemoHomeSubViewInput, Never>
    ) {
        self.directoryContents = directoryContents
        self.input = input
    }

    deinit { print("deinit MemoHomeDirectoryContentCellDataSource") }

    func numberOfSections(in tableView: UITableView) -> Int {
        directoryContents.getChildItemSize()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let storageItem = directoryContents[indexPath.section]!
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: DirectoryFileItemRowView.reuseIdentifier,
                for: indexPath) as! DirectoryFileItemRowView

        cell.configure(with: storageItem)
        tableView.isUserInteractionEnabled = true
        return cell
    }
}

extension MemoHomeDirectoryContentCellDataSource: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

        let showFileInfomation =
            UIContextualAction(style: .normal, title: "share") { (_, _, success: @escaping (Bool) -> Void) in
                self.input.send(.showFileInformation(indexPath.section))
                success(true)
            }

        let removeFile =
            UIContextualAction(style: .normal, title: "remove") { (_, _, success: @escaping (Bool) -> Void) in
                self.input.send(.removeFile(indexPath.section))
                success(true)
            }

        showFileInfomation.backgroundColor = .systemBlue
        showFileInfomation.image = UIImage(systemName: "info.circle")
        removeFile.backgroundColor = .systemRed
        removeFile.image = UIImage(systemName: "trash.fill")
        removeFile.accessibilityLabel = "removeFile"

        let config = UISwipeActionsConfiguration(actions: [removeFile, showFileInfomation])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileTapped = directoryContents[indexPath.section]!

        switch fileTapped {
            case is MemoPageModel:
                input.send(.didTappedPageRow(indexPath.section))

            case is MemoDirectoryModel:
                tableView.isUserInteractionEnabled = false
                input.send(.didTappedDirectoryRow(indexPath.section))

            default:
                break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 70 }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 13 }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}

extension MemoHomeDirectoryContentCellDataSource: UITableViewDragDelegate {
    func tableView(
        _ tableView: UITableView,
        itemsForBeginning session: any UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {

        if let file = directoryContents[indexPath.section],
            let page = file as? MemoPageModel
        {
            let nsstringUUID = page.id.uuidString as NSString
            let itemProvider = NSItemProvider(object: nsstringUUID)
            return [UIDragItem(itemProvider: itemProvider)]
        }
        return []
    }
}

extension MemoHomeDirectoryContentCellDataSource: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        coordinator.session.loadObjects(ofClass: NSString.self) { [self] items in
            guard let nsstrings = items as? [NSString] else { return }
            let ids = nsstrings.compactMap { UUID(uuidString: $0 as String) }
            input.send(.didPerformDropOperationInHomeTable(ids))
        }
    }

    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: NSString.self)
    }

}

extension MemoHomeDirectoryContentCellDataSource: UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: NSString.self) { [self] items in
            guard let nsstrings = items as? [NSString] else { return }
            let ids = nsstrings.compactMap { UUID(uuidString: $0 as String) }
            input.send(.didPerformDropOperationInHomeTable(ids))
        }
    }

    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        UIDropProposal(operation: .move)
    }

    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        session.canLoadObjects(ofClass: NSString.self)
    }
}
