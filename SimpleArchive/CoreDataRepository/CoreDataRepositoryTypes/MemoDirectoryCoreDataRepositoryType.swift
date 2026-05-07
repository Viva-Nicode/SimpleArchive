import Combine
import Foundation

protocol MemoDirectoryCoreDataRepositoryType: AnyObject {

    func fetchSystemDirectoryEntities(fileCreator: any FileCreatorType)
        -> AnyPublisher<([SystemDirectories: MemoDirectoryModel],DirectoryContentsRenderInfo), Error>

    @discardableResult
    func createStorageItem(storageItem: any StorageItem, infos: DirectoryContentsRenderInfo) -> AnyPublisher<
        Void, Error
    >

    @discardableResult
    func moveFileToDormantBox(fileID: UUID) -> AnyPublisher<Void, Error>

    func saveFileNameChange(fileID: UUID, newName: String)

    func saveFileItemColor(fileID: UUID, color: FileItemColor)

    func saveFileSortCriteria(
        fileID: UUID, newSortCriteria: DirectoryContentsSortCriterias, infos: DirectoryContentsRenderInfo)

    func moveItemOrder(directoryID: UUID, infos: DirectoryContentsRenderInfo)

    func moveItemLocation(targetDir: MemoDirectoryModel, item: any StorageItem, infos: DirectoryContentsRenderInfo)

    func hideItem(item: any StorageItem, infos: DirectoryContentsRenderInfo)
	
	func unhideItem(item: any StorageItem, infos: DirectoryContentsRenderInfo)
}
