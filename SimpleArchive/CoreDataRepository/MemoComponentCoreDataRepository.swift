import CSFBAudioEngine
import Combine
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

            component.store(in: ctx, parentPage: parentPageEntity)
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

    func saveComponentsDetail(changedComponents: [any PageComponent]) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in
            for component in changedComponents {
                let fetchRequest = MemoComponentEntity.findById(id: component.id)
                let componentEntity = try ctx.fetch(fetchRequest).first!

                componentEntity.setDetail(detail: component.componentDetail)

                if case .unsaved(true) = component.persistenceState,
                    let snapshotRestorableComponent = component as? any SnapshotRestorable
                {
                    let snapshot = snapshotRestorableComponent.makeSnapshot(desc: "", saveMode: .automatic)
                    snapshot.store(in: ctx, parentComponentId: component.id)
                }
                component.updatePersistenceState(to: .synced)
            }
        }
    }

    func captureSnapshot(snapshotRestorableComponent: any SnapshotRestorable, desc: String) -> AnyPublisher<Void, Error>
    {
        coredataStack.update { ctx in
            let pageComponent = (snapshotRestorableComponent as! any PageComponent)
            let fetchRequest = MemoComponentEntity.findById(id: pageComponent.id)
            let componentEntity = try ctx.fetch(fetchRequest).first!

            componentEntity.setDetail(detail: pageComponent.componentDetail)

            let snapshot = snapshotRestorableComponent.makeSnapshot(desc: desc, saveMode: .manual)
            snapshot.store(in: ctx, parentComponentId: pageComponent.id)

            pageComponent.updatePersistenceState(to: .synced)
        }
    }
}
