import Combine
import UIKit

final class DirectoryStackDataSource: NSObject, UICollectionViewDataSource {

    private var directoryStack: DirectoryStack
    private var dispatcher: PassthroughSubject<MemoHomeViewInput, Never>
    private var manualSortInfo: DirectoryContentsRenderInfo

    init(
        directoryStack: DirectoryStack,
        dispatcher: PassthroughSubject<MemoHomeViewInput, Never>,
        manualSortInfo: DirectoryContentsRenderInfo
    ) {
        self.directoryStack = directoryStack
        self.dispatcher = dispatcher
        self.manualSortInfo = manualSortInfo
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        directoryStack.stack.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let directoryContents = directoryStack.stack[indexPath.item]

        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: MemoHomeDirectoryContentCell.reuseIdentifier,
                for: indexPath) as! MemoHomeDirectoryContentCell

        let dataSource = DirectoryContentDataSource(
            directoryContents: directoryContents,
            input: dispatcher,
            manualSortInfo: manualSortInfo)

        if let layout = cell.directoryContentTableView.collectionViewLayout as? DirectoryContentsLayout {
            layout.delegate = dataSource
        }

        cell.configure(datasource: dataSource)

        return cell
    }
}
