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
            if let componentEntity = try ctx.fetch(MemoComponentEntity.findById(id: componentID)).first,
                let snapshotRestorableComponentEntity = componentEntity as? (any SnapshotRestorableComponentEntityType)
            {
                snapshotRestorableComponentEntity.removeSnapshot(snapshotID: snapshotID)
            }
        }
    }

    func revertComponentContents(
        modifiedComponent: any PageComponent,
        trackingSnapshot: any ComponentSnapshotType
    ) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: modifiedComponent.id)
            if let componentEntity = try ctx.fetch(fetchRequest).first {
                if let snapshotRestorableComponentEntity = componentEntity
                    as? (any SnapshotRestorableComponentEntityType)
                {
                    if let trackingSnapshotEntity = snapshotRestorableComponentEntity.findSnapshotEntityByID(
                        snapshotID: trackingSnapshot.snapshotID)
                    {
                        trackingSnapshotEntity.updateSnapshotInfo(snapshot: trackingSnapshot)
                    }
                    componentEntity.isMinimumHeight = modifiedComponent.isMinimumHeight
                    snapshotRestorableComponentEntity.revertComponentEntityContents(componentModel: modifiedComponent)
                }
            }
        }
    }
}
