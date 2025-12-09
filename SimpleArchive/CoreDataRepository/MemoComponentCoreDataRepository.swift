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

    func saveComponentsDetail(modifiedComponent: any PageComponent) -> AnyPublisher<Void, any Error> {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: modifiedComponent.id)
            let componentEntity = try ctx.fetch(fetchRequest).first!
            
            modifiedComponent.storeEntityContents(entity: componentEntity)
                        
            print("\(modifiedComponent.title)가 coredata에 저장됨")
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
                snapshot.store(in: ctx, parentComponentId: snapshotRestorableComponent.id)

                snapshotRestorableComponent.setCaptureState(to: .captured)
                print("\(componentEntity.title)가 켑쳐됨")
            }
        }
    }

    func captureSnapshot(
        snapshotRestorableComponent: any SnapshotRestorablePageComponent,
        saveMode: SnapshotSaveMode,
        snapShotDescription: String = ""
    ) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in

            let fetchRequest = MemoComponentEntity.findById(id: snapshotRestorableComponent.id)
            let componentEntity = try ctx.fetch(fetchRequest).first!

            let snapshot = snapshotRestorableComponent.makeSnapshot(desc: snapShotDescription, saveMode: saveMode)
            snapshot.store(in: ctx, parentComponentId: snapshotRestorableComponent.id)

            snapshotRestorableComponent.setCaptureState(to: .captured)
            print("\(componentEntity.title)가 켑쳐됨")
        }
    }
}
