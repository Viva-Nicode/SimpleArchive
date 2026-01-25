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

    func getFileInformation() -> StorageItemInformationType
    func getFilePath() -> String

    func persistToPersistentStorage(using persistence: StorageItemPersistenceCreatorType)
    func removeStorageItem()
}

extension StorageItem {
    func getFilePath() -> String {
        if let parentDirectory {
            parentDirectory.getFilePath() + ">" + name
        } else {
            name
        }
    }
}
