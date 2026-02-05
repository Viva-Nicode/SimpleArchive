import CoreData

final class CoreDataStorageItemPersistenceCreator: StorageItemPersistenceCreatorType {
    var context: NSManagedObjectContext?
    var parentDirectoryEntity: MemoDirectoryEntity?

    init(parentDirectoryEntity: MemoDirectoryEntity? = nil) {
        self.parentDirectoryEntity = parentDirectoryEntity
    }

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func persistDirectory(directory: MemoDirectoryModel) {
        guard let context = parentDirectoryEntity?.managedObjectContext ?? self.context else { return }
        let directoryEntity = MemoDirectoryEntity(context: context)

        directoryEntity.id = directory.id
        directoryEntity.name = directory.name
        directoryEntity.sortBy = directory.getSortBy().rawValue
        directoryEntity.creationDate = directory.creationDate
        directoryEntity.childDirectories = []
        directoryEntity.pages = []
        parentDirectoryEntity?.addToChildDirectories(directoryEntity)

        directory.getChildItems()
            .forEach { childStorageItem in
                self.parentDirectoryEntity = directoryEntity
                childStorageItem.persistToPersistentStorage(using: self)
            }
    }

    func persistPage(page: MemoPageModel) {
        guard let context = parentDirectoryEntity?.managedObjectContext else { return }
        let memoPageEntity = MemoPageEntity(context: context)
        memoPageEntity.id = page.id
        memoPageEntity.name = page.name
        memoPageEntity.creationDate = page.creationDate
        memoPageEntity.isSingleComponentPage = page.isSingleComponentPage
        memoPageEntity.components = []

        let persistence = CoreDataPageComponentPersistenceCreator(parentPage: memoPageEntity)

        page.getComponents.forEach {
            $0.persistToPersistentStorage(using: persistence)
        }
        parentDirectoryEntity?.addToPages(memoPageEntity)
    }
}
