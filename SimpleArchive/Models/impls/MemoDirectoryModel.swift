import Foundation

final class MemoDirectoryModel: NSObject, StorageItem {

    var id: UUID
    var name: String
    var creationDate: Date
    weak var parentDirectory: MemoDirectoryModel?

    private var childItems: StorageItemContainer

    init(
        id: UUID = UUID(),
        creationDate: Date = Date(),
        name: String,
        sortBy: DirectoryContentsSortCriterias = .name,
        parentDirectory: MemoDirectoryModel? = nil
    ) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
        self.parentDirectory = parentDirectory
        self.childItems = StorageItemContainer(items: [], sortCriteriable: sortBy.getSortCriteriaObject())
        super.init()
        parentDirectory?.insertChildItem(item: self)
    }

    deinit { print("deinit MemoDirectoryModel : \(name)") }

    func removeStorageItem() {
        for storageItem in childItems.getItems() {
            storageItem.removeStorageItem()
        }

        parentDirectory?.childItems.removeItemByID(with: id)
        parentDirectory = nil
    }

    func getFileInformation() -> StorageItemInformationType {
        let containedFileCount = getContainedDirectoryCount()

        return DirectoryInformation(
            id: id,
            name: name,
            filePath: getFilePath(),
            created: creationDate,
            containedDirectoryCount: containedFileCount.dirCount - 1,
            containedPageCount: containedFileCount.pageCount)
    }

    subscript(_ ID: UUID) -> OperationResultItem<any StorageItem>? {
        childItems.findItemByID(with: ID)
    }

    subscript(_ index: Int) -> (any StorageItem)? {
        childItems.findItemByIndex(with: index)
    }

    func getChildItemSize() -> Int { childItems.getSize() }

    @discardableResult
    func insertChildItem(item: any StorageItem) -> Int {
        childItems.insertItem(item: item)
    }

    @discardableResult
    func removeChildItemByID(with id: UUID) -> (any StorageItem)? {
        childItems.removeItemByID(with: id)
    }

    func getSortBy() -> DirectoryContentsSortCriterias {
        childItems.getSortBy()
    }

    func getChildItems() -> [any StorageItem] {
        childItems.getItems()
    }

    func setSortCriteria(_ sortCriterias: DirectoryContentsSortCriterias) -> [(Int, Int)] {
        childItems.setSortCriteria(newSortCriterias: sortCriterias)
    }

    func renameChildFile(fileID: UUID, newName: String) -> Int? {
        childItems.renameFileByID(fileID: fileID, newName: newName)
    }

    func toggleAscending() -> [(Int, Int)] {
        childItems.toggleAscending()
    }

    private func getContainedDirectoryCount() -> (dirCount: Int, pageCount: Int) {

        var result = (dirCount: 1, pageCount: childItems.getItems().filter { $0 is MemoPageModel }.count)
        let childDirectories = childItems.getItems().compactMap { $0 as? MemoDirectoryModel }

        for childDirectory in childDirectories {
            let temp = childDirectory.getContainedDirectoryCount()
            result.dirCount += temp.dirCount
            result.pageCount += temp.pageCount
        }
        return result
    }
}


