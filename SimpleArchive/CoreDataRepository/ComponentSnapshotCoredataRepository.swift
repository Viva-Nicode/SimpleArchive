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
}
