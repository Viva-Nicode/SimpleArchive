import Combine
import Foundation

protocol MemoComponentRepositoryForSingleComponent {
    @discardableResult
    func updateComponentChanges(componentChanges: PageComponentChangeObject) -> AnyPublisher<Void, Error>

    @discardableResult
    func saveComponentsDetail(changedComponents: [any PageComponent]) -> AnyPublisher<Void, Error>

    @discardableResult
    func captureSnapshot(snapshotRestorableComponent: any SnapshotRestorable, desc: String) -> AnyPublisher<Void, Error>
}

protocol MemoComponentCoreDataRepositoryType: MemoComponentRepositoryForSingleComponent {

    @discardableResult
    func createComponentEntity(parentPageID: UUID, component: any PageComponent)
        -> AnyPublisher<Void, any Error>

    func removeComponent(parentPageID: UUID, componentID: UUID)
}
