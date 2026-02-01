import Combine
import CoreData

final class ComponentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType {

    private let coredataStack: PersistentStore

    init(coredataStack: PersistentStore) {
        self.coredataStack = coredataStack
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
