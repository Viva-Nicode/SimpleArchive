import Foundation
import CoreData

protocol StorageItem: AnyObject, Hashable, Identifiable {
    var id: UUID { get }
    var name: String { get set }
    var creationDate: Date { get }
    var parentDirectory: MemoDirectoryModel? { get set }

    func getFileInformation() -> StorageItemInformationType
    func getFilePath() -> String

    func store(in ctx: NSManagedObjectContext, parentDirectory: MemoDirectoryEntity?)
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
