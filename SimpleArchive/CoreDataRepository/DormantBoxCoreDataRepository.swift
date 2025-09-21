import Combine
import Foundation

struct DormantBoxCoreDataRepository: DormantBoxCoreDataRepositoryType {

    private let coredataStack: PersistentStore

    init(coredataStack: PersistentStore) {
        self.coredataStack = coredataStack
    }

    func fetchDormantBoxDirectory() -> AnyPublisher<MemoDirectoryModel, Error> {
        let dormantBoxID = SystemDirectories.dormantBoxDirectory.getId()!

        let fetchRequest = MemoDirectoryEntity.findDirectoryEntityById(id: dormantBoxID)
        return coredataStack.fetch(fetchRequest) { $0.convertToModel() }
            .map { $0.first! as! MemoDirectoryModel }
            .eraseToAnyPublisher()
    }

    func restoreFile(restoredFileID: UUID) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in

            let mainDirectoryID = SystemDirectories.mainDirectory.getId()!

            let fetchMainDirectoryEntityRequest =
                MemoDirectoryEntity.findDirectoryEntityById(id: mainDirectoryID)
            let fetchMainDirectoryEntityResult = try ctx.fetch(fetchMainDirectoryEntityRequest)

            let fetchRemoveTargetPageRequest = MemoPageEntity.findPageById(id: restoredFileID)
            let fetchRemoveTargetPageResult = try ctx.fetch(fetchRemoveTargetPageRequest)

            fetchRemoveTargetPageResult.first!.containingDirectory
                .removeFromPages(fetchRemoveTargetPageResult.first!)
            fetchMainDirectoryEntityResult.first!.addToPages(fetchRemoveTargetPageResult.first!)
        }
    }
}
