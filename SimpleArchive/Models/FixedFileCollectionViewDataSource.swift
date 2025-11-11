import Combine
import UIKit

final class FixedFileCollectionViewDataSource: NSObject, UICollectionViewDataSource {

    private(set) var fixedFileDirectory: MemoDirectoryModel
    var input: PassthroughSubject<MemoHomeViewInput, Never>?

    init(fixedFileDirectory: MemoDirectoryModel) {
        self.fixedFileDirectory = fixedFileDirectory
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        fixedFileDirectory.getChildItemSize()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let storageItem = fixedFileDirectory[indexPath.item]!
        let cell =
            collectionView
            .dequeueReusableCell(
                withReuseIdentifier: FixedFileItemView.reuseIdentifier,
                for: indexPath) as! FixedFileItemView

        var fileItemType: ComponentType?

        if let page = storageItem as? MemoPageModel {
            if page.isSingleComponentPage {
                fileItemType = page.getComponents.first?.type
            }
        }

        cell.configure(fileName: storageItem.name, componentType: fileItemType)
        return cell
    }
}

extension FixedFileCollectionViewDataSource: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        input?.send(.didTappedFixedPageRow(indexPath.item))
    }
}

extension FixedFileCollectionViewDataSource: UICollectionViewDragDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        itemsForBeginning session: any UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {

        if let file = fixedFileDirectory[indexPath.item],
            let page = file as? MemoPageModel
        {
            let nsstringUUID = page.id.uuidString as NSString
            let itemProvider = NSItemProvider(object: nsstringUUID)
            return [UIDragItem(itemProvider: itemProvider)]
        }
        return []
    }
}

extension FixedFileCollectionViewDataSource: UICollectionViewDropDelegate {
    func collectionView(
        _ collectionView: UICollectionView, performDropWith coordinator: any UICollectionViewDropCoordinator
    ) {
        coordinator.session.loadObjects(ofClass: NSString.self) { [self] items in
            guard let objects = items as? [NSString] else { return }
            let ids = objects.compactMap { UUID(uuidString: $0 as String) }
            input?.send(.didPerformDropOperationInFixedTable(ids))
        }
    }
}
