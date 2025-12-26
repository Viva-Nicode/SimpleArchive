import Combine
import Foundation

struct OperationResultItem<T> {
    var index: Int
    var item: T
}

struct StorageItemContainer {

    private var items: [any StorageItem]
    private var sortCriteriable: any DirectoryContentsSortCriteriaType

    init(items: [any StorageItem], sortCriteriable: any DirectoryContentsSortCriteriaType) {
        self.items = items
        self.sortCriteriable = sortCriteriable
        self.items.sort(by: sortCriteriable.howToSort)
    }

    func getSize() -> Int { items.count }

    func getItems() -> [any StorageItem] { items }

    func getSortBy() -> DirectoryContentsSortCriterias { sortCriteriable.sortBy }

    func findItemByID(with itemID: UUID) -> OperationResultItem<any StorageItem>? {
        guard let index = items.firstIndex(where: { $0.id == itemID }) else { return nil }
        return OperationResultItem(index: index, item: items[index])
    }

    func findItemByIndex(with index: Int) -> (any StorageItem)? {
        guard 0..<items.count ~= index else { return nil }
        return items[index]
    }

    @discardableResult
    mutating func insertItem(item: any StorageItem) -> Int {
        let insertIndex = items.firstIndex { sortCriteriable.howToSort(lhs: item, rhs: $0) } ?? items.count
        items.insert(item, at: insertIndex)
        return insertIndex
    }

    @discardableResult
    mutating func removeItemByID(with fileID: UUID) -> (any StorageItem)? {
        if let idx = items.firstIndex(where: { $0.id == fileID }) {
            return items.remove(at: idx)
        }
        return nil
    }

    mutating func renameFileByID(fileID: UUID, newName: String) -> Int? {
        if let reanemToFile = items.first(where: { $0.id == fileID }) {
            reanemToFile.name = newName
        }
        items.sort(by: sortCriteriable.howToSort)
        return items.firstIndex { $0.id == fileID }
    }

    mutating func setSortCriteria(newSortCriterias: DirectoryContentsSortCriterias) -> [(Int, Int)] {
        sortCriteriable = newSortCriterias.getSortCriteriaObject()
        let afterSorted = items.sorted(by: sortCriteriable.howToSort)
        var result: [(Int, Int)] = []

        for (fileIndexBeforeSorting, item) in items.enumerated() {
            let fileIndexAfterSorting = afterSorted.firstIndex { $0.id == item.id }!
            result.append((fileIndexBeforeSorting, fileIndexAfterSorting))
        }

        items = afterSorted
        return result
    }

    mutating func toggleAscending() -> [(Int, Int)] {
        sortCriteriable.isAscending.toggle()
        let afterSorted = items.sorted(by: sortCriteriable.howToSort)
        var result: [(Int, Int)] = []

        for (fileIndexBeforeSorting, item) in items.enumerated() {
            let fileIndexAfterSorting = afterSorted.firstIndex { $0.id == item.id }!
            result.append((fileIndexBeforeSorting, fileIndexAfterSorting))
        }

        items = afterSorted
        return result
    }
}
