import Combine
import Foundation

@testable import SimpleArchive

final class MockMemoComponentCoreDataRepository: Mock, MemoComponentCoreDataRepositoryType {

    enum Action: Equatable {
        case createComponentEntity
        case removeComponent
        case updateComponentChanges
        case saveComponentsDetail
        case captureSnapshot
    }

    var actions = MockActions<Action>(expected: [])

    func createComponentEntity(parentPageID: UUID, component: any PageComponent) -> AnyPublisher<Void, Error> {
        register(.createComponentEntity)
        return Just<Void>.withErrorType(Error.self)
    }

    func removeComponent(parentPageID: UUID, componentID: UUID) {
        register(.removeComponent)
    }

    func updateComponentChanges(componentChanges: PageComponentChangeObject) -> AnyPublisher<Void, Error> {
        register(.updateComponentChanges)
        return Just<Void>.withErrorType(Error.self)
    }

    func saveComponentsDetail(changedComponents: [any PageComponent]) -> AnyPublisher<Void, Error> {
        register(.saveComponentsDetail)
        return Just<Void>.withErrorType(Error.self)
    }

    func captureSnapshot(snapshotRestorableComponent: any SnapshotRestorable, desc: String)
        -> AnyPublisher<Void, Error>
    {
        register(.captureSnapshot)
        return Just<Void>.withErrorType(Error.self)
    }

}
