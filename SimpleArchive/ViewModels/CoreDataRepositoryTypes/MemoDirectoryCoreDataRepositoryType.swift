import Combine
import Foundation

protocol MemoDirectoryCoreDataRepositoryType {

    func fetchSystemDirectoryEntities(fileCreator: any FileCreatorType) -> AnyPublisher<
        [SystemDirectories: MemoDirectoryModel], Error
    >

    @discardableResult
    func createStorageItem(storageItem: any StorageItem) -> AnyPublisher<Void, Error>

    @discardableResult
    func moveFileToDormantBox(fileID: UUID) -> AnyPublisher<Void, Error>

    func saveFileNameChange(fileID: UUID, newName: String)

    func saveFileSortCriteria(fileID: UUID, newSortCriteria: SortCriterias)
}
