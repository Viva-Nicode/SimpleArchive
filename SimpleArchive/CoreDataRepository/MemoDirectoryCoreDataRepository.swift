import Combine
import CoreData

final class MemoDirectoryCoreDataRepository: MemoDirectoryCoreDataRepositoryType {

    private let coredataStack: PersistentStore

    init(coredataStack: PersistentStore) {
        self.coredataStack = coredataStack
    }

    func fetchSystemDirectoryEntities(fileCreator: any FileCreatorType)
        -> AnyPublisher<[SystemDirectories: MemoDirectoryModel], Error>
    {
        let fetchAllDirectoriesRequest = MemoDirectoryEntity.fetchAllRootDirectoriesRequest()

        return coredataStack.fetch(fetchAllDirectoriesRequest) { $0.convertToModel() }
            .map { systemDirectories in

                SystemDirectories.allCases
                    .map {
                        systemDirectoryCase -> [SystemDirectories: MemoDirectoryModel] in

                        if let systemDirectoryID = systemDirectoryCase.getId(),
                            let systemDirectory = systemDirectories.first(where: { $0.id == systemDirectoryID })
                        {
                            return [systemDirectoryCase: systemDirectory as! MemoDirectoryModel]
                        }

                        let systemDirectory = fileCreator.createFile(
                            itemName: systemDirectoryCase.DirectoryName,
                            parentDirectory: nil)

                        systemDirectoryCase.setId(systemDirectory.id)
                        self.coredataStack.update { ctx in
                            let persistence = CoreDataStorageItemPersistenceCreator(context: ctx)
                            systemDirectory.persistToPersistentStorage(using: persistence)
                        }

                        return [systemDirectoryCase: systemDirectory as! MemoDirectoryModel]
                    }
                    .reduce(into: [SystemDirectories: MemoDirectoryModel]()) { result, dict in
                        for (key, value) in dict {
                            result[key] = value
                        }
                    }
            }
            .eraseToAnyPublisher()
    }

    func createStorageItem(storageItem: any StorageItem, infos: DirectoryContentsRenderInfo) -> AnyPublisher<
        Void, Error
    > {
        coredataStack.update { ctx in
            let fetchRequest = MemoDirectoryEntity.findDirectoryEntityById(id: storageItem.parentDirectory!.id)
            let parentDirectoryEntity = try ctx.fetch(fetchRequest).first
            let persistence = CoreDataStorageItemPersistenceCreator(parentDirectoryEntity: parentDirectoryEntity)

            persistence.parentDirectoryEntity = parentDirectoryEntity
            storageItem.persistToPersistentStorage(using: persistence)

            try? UserDefaultStack.shared.store(keyTypes: .FileItemManualOrder, v: infos)
        }
    }

    func moveItemOrder(directoryID: UUID, infos: DirectoryContentsRenderInfo) {
        coredataStack.update { ctx in
            let fetchRequest = MemoDirectoryEntity.findDirectoryEntityById(id: directoryID)
            let fetchResult = try ctx.fetch(fetchRequest).first!

            fetchResult.sortBy = DirectoryContentsSortCriterias.manual.rawValue
            try? UserDefaultStack.shared.store(keyTypes: .FileItemManualOrder, v: infos)
        }
    }

    func moveFileToDormantBox(fileID: UUID) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in
            let dormantBoxID = SystemDirectories.dormantBoxDirectory.getId()!

            let fetchDormantBoxRequest = MemoDirectoryEntity.findDirectoryEntityById(id: dormantBoxID)
            let dormantBoxEntity = try ctx.fetch(fetchDormantBoxRequest).first!

            let fetchRequest = StorageItemEntity.findById(id: fileID)
            let fetchResult = try ctx.fetch(fetchRequest).first!

            fetchResult.moveToDormantBox(dormantBox: dormantBoxEntity)
        }
    }

    func saveFileNameChange(fileID: UUID, newName: String) {
        coredataStack.update { ctx in
            let fetchRequest = StorageItemEntity.findById(id: fileID)
            let fetchResult = try ctx.fetch(fetchRequest).first!

            fetchResult.name = newName
        }
    }

    func saveFileItemColor(fileID: UUID, color: FileItemColor) {
        coredataStack.update { ctx in
            let fetchRequest = StorageItemEntity.findById(id: fileID)
            let fetchResult = try ctx.fetch(fetchRequest).first!

            fetchResult.itemColor = color.rawValue
        }
    }

    func saveFileSortCriteria(
        fileID: UUID, newSortCriteria: DirectoryContentsSortCriterias, infos: DirectoryContentsRenderInfo
    ) {
        coredataStack.update { ctx in
            let fetchRequest = MemoDirectoryEntity.findDirectoryEntityById(id: fileID)
            let fetchResult = try ctx.fetch(fetchRequest).first!

            fetchResult.sortBy = newSortCriteria.rawValue
            try? UserDefaultStack.shared.store(keyTypes: .FileItemManualOrder, v: infos)
        }
    }
}
