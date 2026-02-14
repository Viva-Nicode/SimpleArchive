import CSFBAudioEngine
import Combine
import CoreData
import Foundation

final class MemoComponentCoreDataRepository: MemoComponentCoreDataRepositoryType {

    private let coredataStack: PersistentStore

    init(coredataStack: PersistentStore) {
        self.coredataStack = coredataStack
    }

    func createComponentEntity(parentPageID: UUID, component: any PageComponent) -> AnyPublisher<Void, any Error> {
        coredataStack.update { ctx in
            let fetchRequest = MemoPageEntity.findPageById(id: parentPageID)
            let parentPageEntity = try ctx.fetch(fetchRequest).first!
            let persistence = CoreDataPageComponentPersistenceCreator(parentPage: parentPageEntity)

            component.persistToPersistentStorage(using: persistence)
        }
    }

    func removeComponentEntity(componentID: UUID) {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: componentID)
            let componentEntity = try ctx.fetch(fetchRequest).first!
            componentEntity.containingPage.removeFromComponents(componentEntity)
            ctx.delete(componentEntity)
        }
    }

    func updateComponentName(componentID: UUID, newName: String) {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: componentID)
            let componentEntity = try ctx.fetch(fetchRequest).first!
            componentEntity.title = newName
        }
    }

    func updateComponentFolding(componentID: UUID, isFolding: Bool) {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: componentID)
            let componentEntity = try ctx.fetch(fetchRequest).first!
            componentEntity.isMinimumHeight = isFolding
        }
    }

    func updateComponentOrdered(componentID: UUID, renderingOrdered: [UUID]) {
        coredataStack.update { ctx in
            try renderingOrdered.enumerated()
                .forEach { (index, id) in
                    let fetchRequest = MemoComponentEntity.findById(id: id)
                    let componentEntity = try ctx.fetch(fetchRequest).first!
                    componentEntity.renderingOrder = index
                }
        }
    }

    func updateComponentContentChanges(modifiedComponent: any PageComponent) -> AnyPublisher<Void, Error> {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: modifiedComponent.id)
            let componentEntity = try ctx.fetch(fetchRequest).first!
            componentEntity.updatePageComponentEntityContents(componentModel: modifiedComponent)
        }
    }

    func updateComponentContentChanges(modifiedComponent: any PageComponent, snapshot: any ComponentSnapshotType)
        -> AnyPublisher<Void, Error>
    {
        coredataStack.update { ctx in
            // 모델과 대응되는 엔티티를 찾아서 영속성에도 컨텐츠 변경사항을 반영한다.
            let fetchRequest = MemoComponentEntity.findById(id: modifiedComponent.id)
            let componentEntity = try ctx.fetch(fetchRequest).first!
            componentEntity.updatePageComponentEntityContents(componentModel: modifiedComponent)

            // 자동캡쳐를 위해 추적되는 스냅샷을 찾고 없으면 만든다.
            if let trackingSnapshotEntity = componentEntity.findSnapshotEntityByID(id: snapshot.snapshotID) {
                trackingSnapshotEntity.updateTrackingSnapshotContents(snapshot: snapshot)
            } else {
                let fetchRequest = MemoComponentEntity.findById(id: modifiedComponent.id)
                let componentEntity = try ctx.fetch(fetchRequest).first!
                let persistence = CoreDataComponentSnapshotPersistenceCreator(parentComponent: componentEntity)

                snapshot.persistToPersistentStorage(using: persistence)
            }
        }
    }

    func updateComponentSnapshotInfo(componentID: UUID, snapshot: any ComponentSnapshotType) {
        coredataStack.update { ctx in
            let fetchRequest = MemoComponentEntity.findById(id: componentID)
            if let componentEntity = try ctx.fetch(fetchRequest).first {
                if let trackingSnapshotEntity = componentEntity.findSnapshotEntityByID(id: snapshot.snapshotID) {
                    trackingSnapshotEntity.updateSnapshotInfo(snapshot: snapshot)
                }
            }
        }
    }
}
