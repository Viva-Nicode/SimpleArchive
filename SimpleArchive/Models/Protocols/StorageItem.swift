import CoreData
import Foundation

protocol StorageItemPersistenceCreatorType {
    func persistDirectory(directory: MemoDirectoryModel)
    func persistPage(page: MemoPageModel)
}

protocol StorageItem: AnyObject, Hashable, Identifiable {
    var id: UUID { get }
    var name: String { get set }
    var creationDate: Date { get }
    var parentDirectory: MemoDirectoryModel? { get set }
    var itemColor: FileItemColor { get set }

    func getFileInformation() -> StorageItemInformationType
    func getItemSize() -> Int64
    func getFilePath() -> String

    func persistToPersistentStorage(using persistence: StorageItemPersistenceCreatorType)
    func removeStorageItem()
}

extension StorageItem {
    func getFilePath() -> String {
        if let parentDirectory {
            parentDirectory.getFilePath() + " > " + name
        } else {
            name
        }
    }
}

protocol StorageItemInformationType {}

struct DirectoryInformation: StorageItemInformationType {
    var containedDirectoryCount: Int
    var containedPageCount: Int
}

struct PageInformation: StorageItemInformationType {
    var pageComponentCounts: [ComponentType: Int]
}

struct OperationResultItem<T> {
    var index: Int
    var item: T
}
