import Combine
import Foundation

protocol MemoSingleComponentRepositoryType {
    @discardableResult
    func updateComponentChanges(componentChanges: PageComponentChangeObject) -> AnyPublisher<Void, Error>

    @discardableResult
    func saveComponentsDetail(modifiedComponent: any PageComponent) -> AnyPublisher<Void, Error>

    @discardableResult
    func captureSnapshot(
        snapshotRestorableComponent: any SnapshotRestorablePageComponent,
        saveMode: SnapshotSaveMode,
        snapShotDescription: String,
    ) -> AnyPublisher<Void, Error>

    @discardableResult
    func captureSnapshot(snapshotRestorableComponents: [any SnapshotRestorablePageComponent])
        -> AnyPublisher<Void, Error>
}

protocol MemoComponentCoreDataRepositoryType: MemoSingleComponentRepositoryType {

    @discardableResult
    func createComponentEntity(parentPageID: UUID, component: any PageComponent)
        -> AnyPublisher<Void, any Error>

    func removeComponent(parentPageID: UUID, componentID: UUID)
}
