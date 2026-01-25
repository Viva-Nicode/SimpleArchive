import CSFBAudioEngine
import Combine
import CoreData
import Foundation

struct MemoComponentCoreDataRepository: MemoComponentCoreDataRepositoryType {

    private let coredataStack: PersistentStore

    init(coredataStack: PersistentStore) {
        self.coredataStack = coredataStack
    }

    func createComponentEntity(parentPageID: UUID, component: any PageComponent) -> AnyPublisher<Void, any Error> {
        coredataStack.update { ctx in
            let fetchRequest = MemoPageEntity.findPageById(id: parentPageID)
            let parentPageEntity = try ctx.fetch(fetchRequest).first!
            let persistence = CoreDataPageComponentPersistenceCreator(context: ctx, parentPage: parentPageEntity)

            component.persistToPersistentStorage(using: persistence)
        }
    }

    func removeComponent(parentPageID: UUID, componentID: UUID) {
        coredataStack.update { ctx in
            let parentPageEntity = try ctx.fetch(MemoPageEntity.findPageById(id: parentPageID)).first!
            let componentEntity = try ctx.fetch(MemoComponentEntity.findById(id: componentID)).first!

            parentPageEntity.removeFromComponents(componentEntity)
            ctx.delete(componentEntity)
        }
    }

    func updateComponentChanges(componentChanges: PageComponentChangeObject) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: componentChanges.componentIdChanged)
            let componentEntity = try ctx.fetch(fetchRequest).first!

            if let newTitile = componentChanges.title {
                componentEntity.title = newTitile
            }

            if let newHeight = componentChanges.isMinimumHeight {
                componentEntity.isMinimumHeight = newHeight
            }

            try componentChanges.componentIdListRenderingOrdered?.enumerated()
                .forEach { (index, id) in
                    let fetchRequest = MemoComponentEntity.findById(id: id)
                    let componentEntity = try ctx.fetch(fetchRequest).first!

                    componentEntity.renderingOrder = index
                }
        }
    }

    func updateComponentContentChanges(modifiedComponent: any PageComponent) -> AnyPublisher<Void, any Error> {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: modifiedComponent.id)
            let componentEntity = try ctx.fetch(fetchRequest).first!

            componentEntity.updatePageComponentEntityContents(in: ctx, componentModel: modifiedComponent)
        }
    }

    func captureSnapshot(snapshotRestorableComponents: [any SnapshotRestorablePageComponent])
        -> AnyPublisher<Void, Error>
    {
        coredataStack.update { ctx in
            for snapshotRestorableComponent in snapshotRestorableComponents {
                let fetchRequest = MemoComponentEntity.findById(id: snapshotRestorableComponent.id)
                let componentEntity = try ctx.fetch(fetchRequest).first!
                let snapshot = snapshotRestorableComponent.makeSnapshot(desc: "", saveMode: .automatic)
                let persistence = CoreDataComponentSnapshotPersistenceCreator(
                    context: ctx, parentComponent: componentEntity)

                snapshot.persistToPersistentStorage(using: persistence)
                snapshotRestorableComponent.setCaptureState(to: .captured)
            }
        }
    }

    func captureSnapshot(
        snapshotRestorableComponent: any SnapshotRestorablePageComponent,
        snapShotDescription: String = ""
    ) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in

            let fetchRequest = MemoComponentEntity.findById(id: snapshotRestorableComponent.id)
            let componentEntity = try ctx.fetch(fetchRequest).first!
            let snapshot = snapshotRestorableComponent.makeSnapshot(desc: snapShotDescription, saveMode: .manual)
            let persistence = CoreDataComponentSnapshotPersistenceCreator(
                context: ctx, parentComponent: componentEntity)

            snapshot.persistToPersistentStorage(using: persistence)
            snapshotRestorableComponent.setCaptureState(to: .captured)
        }
    }
}
