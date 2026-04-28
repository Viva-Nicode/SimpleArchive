import Foundation

final class MemoDirectoryModel: NSObject, StorageItem {

    var id: UUID
    var name: String
    var creationDate: Date
    var sortBy: DirectoryContentsSortCriterias
    var itemColor: FileItemColor
    var items: [any StorageItem]
    weak var parentDirectory: MemoDirectoryModel?

    init(
        id: UUID = UUID(),
        name: String,
        creationDate: Date = Date(),
        sortBy: DirectoryContentsSortCriterias = .creationDate,
        itemColor: FileItemColor = .white,
        items: [any StorageItem] = [],
        parentDirectory: MemoDirectoryModel? = nil
    ) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
        self.sortBy = sortBy
        self.itemColor = itemColor
        self.items = items
        self.parentDirectory = parentDirectory
        super.init()
        parentDirectory?.items.append(self)
    }

    func removeStorageItem() {
        for storageItem in items {
            storageItem.removeStorageItem()
        }

        if let idx = parentDirectory?.items.firstIndex(where: { $0.id == id }) {
            parentDirectory?.items.remove(at: idx)
            parentDirectory = nil
        }
    }

    func getFileInformation() -> StorageItemInformationType {
        let containedFileCount = getContainedDirectoryCount()

        return DirectoryInformation(
            containedDirectoryCount: containedFileCount.dirCount - 1,
            containedPageCount: containedFileCount.pageCount)
    }

    func getItemSize() -> Int64 {
        items.map { $0.getItemSize() }.reduce(0, +)
    }

    func sortItems() {
        switch sortBy {
            case .name:
                self.items.sort(by: { $0.name < $1.name })

            case .creationDate:
                self.items.sort(by: { $0.creationDate < $1.creationDate })

            case .manual:
                break
        }
    }

    subscript(_ ID: UUID) -> OperationResultItem<any StorageItem>? {
        if let index = items.firstIndex(where: { $0.id == ID }) {
            return OperationResultItem(index: index, item: items[index])
        }
        return nil
    }

    private func getContainedDirectoryCount() -> (dirCount: Int, pageCount: Int) {
        var result = (dirCount: 1, pageCount: items.filter { $0 is MemoPageModel }.count)
        let childDirectories = items.compactMap { $0 as? MemoDirectoryModel }

        for childDirectory in childDirectories {
            let temp = childDirectory.getContainedDirectoryCount()
            result.dirCount += temp.dirCount
            result.pageCount += temp.pageCount
        }
        return result
    }
}
