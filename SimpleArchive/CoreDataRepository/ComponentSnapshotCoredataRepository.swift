import Combine
import CoreData

final class ComponentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType {

    private let coredataStack: PersistentStore

    init(coredataStack: PersistentStore) {
        self.coredataStack = coredataStack
    }

    func createComponentSnapshot(snapshots: [InfoForCreateSnapshotEntity]) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in
            for (componentID, snapshot) in snapshots {
                let fetchRequest = MemoComponentEntity.findById(id: componentID)
                let componentEntity = try ctx.fetch(fetchRequest).first!
                let persistence = CoreDataComponentSnapshotPersistenceCreator(parentComponent: componentEntity)

                snapshot.persistToPersistentStorage(using: persistence)
            }
        }
    }

    func removeSnapshot(componentID: UUID, snapshotID: UUID) {
        coredataStack.update { ctx in
            let componentEntity = try ctx.fetch(MemoComponentEntity.findById(id: componentID)).first
            componentEntity?.removeSnapshot(snapshotID: snapshotID)
        }
    }

    func revertComponentContents(modifiedComponent: any PageComponent) -> AnyPublisher<Void, any Error> {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: modifiedComponent.id)
            let componentEntity = try ctx.fetch(fetchRequest).first

            componentEntity?.revertComponentEntityContents(componentModel: modifiedComponent)
        }
    }
}
