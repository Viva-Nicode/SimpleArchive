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

    func revertComponentContents(
        modifiedComponent: any PageComponent,
        trackingSnapshot: any ComponentSnapshotType
    ) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: modifiedComponent.id)
            if let componentEntity = try ctx.fetch(fetchRequest).first {
                if let trackingSnapshotEntity = componentEntity.findSnapshotEntityByID(id: trackingSnapshot.snapshotID)
                {
                    trackingSnapshotEntity.updateSnapshotInfo(snapshot: trackingSnapshot)
                }

                /* MARK: - 📄 NOTE
                 폴딩된 상태에서 revert하는 경우 펴져야 해서 isMinimumHeight도 바꿔준다.
                 */
                componentEntity.isMinimumHeight = modifiedComponent.isMinimumHeight
                componentEntity.revertComponentEntityContents(componentModel: modifiedComponent)
			}else{
				myLog("컴포넌트 엔티티를 찾을 수 없음")
			}
        }
    }
}
