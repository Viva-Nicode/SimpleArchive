import Combine
import CoreData

struct ComponentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType {

    private let coredataStack: PersistentStore

    init(coredataStack: PersistentStore) {
        self.coredataStack = coredataStack
    }

    func removeSnapshot(componentID: UUID, snapshotID: UUID) {
        coredataStack.update { ctx in
            let componentEntity = try ctx.fetch(MemoComponentEntity.findById(id: componentID)).first
            componentEntity?.removeSnapshot(ctx: ctx, snapshotID: snapshotID)
        }
    }

    func updateComponentContentChanges(modifiedComponent: any PageComponent) -> AnyPublisher<Void, any Error> {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: modifiedComponent.id)
            let componentEntity = try ctx.fetch(fetchRequest).first!
            
            modifiedComponent.updatePageComponentEntityContents(in: ctx, entity: componentEntity)

            print("\(modifiedComponent.title)가 coredata에 저장됨")
        }
    }
}
