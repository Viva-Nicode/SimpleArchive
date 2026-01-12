import Combine
import Foundation

@testable import SimpleArchive

final class MockMemoDirectoryCoreDataRepository: Mock, MemoDirectoryCoreDataRepositoryType {

    enum Action: Equatable {
        case fetchSystemDirectoryEntities
        case createStorageItem
        case moveFileToDormantBox
        case saveFileNameChange
        case saveFileSortCriteria
    }

    var actions = MockActions<Action>(expected: [])

    var fetchSystemDirectoryEntitiesResult: Result<[SystemDirectories: MemoDirectoryModel], Error> = .failure(
        MockError.valueNotSet)
    var createStorageItemResult: Result<Void, Error> = .failure(MockError.valueNotSet)

    func fetchSystemDirectoryEntities(fileCreator: any FileCreatorType)
        -> AnyPublisher<[SystemDirectories: MemoDirectoryModel], Error>
    {
        register(.fetchSystemDirectoryEntities)
        return fetchSystemDirectoryEntitiesResult.publish()
    }

    func createStorageItem(storageItem: any StorageItem) -> AnyPublisher<Void, Error> {
        register(.createStorageItem)
        return Just<Void>.withErrorType(Error.self)
    }

    func moveFileToDormantBox(fileID: UUID) -> AnyPublisher<Void, Error> {
        register(.moveFileToDormantBox)
        return Just<Void>.withErrorType(Error.self)
    }

    func saveFileNameChange(fileID: UUID, newName: String) {
        register(.saveFileNameChange)
    }

    func saveFileSortCriteria(fileID: UUID, newSortCriteria: DirectoryContentsSortCriterias) {
        register(.saveFileSortCriteria)
    }
}
