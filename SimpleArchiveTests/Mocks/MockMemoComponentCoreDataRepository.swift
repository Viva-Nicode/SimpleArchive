import Combine
import Foundation

@testable import SimpleArchive

final class MockMemoComponentCoreDataRepository: Mock, MemoComponentCoreDataRepositoryType {

    enum Action: Equatable {
        case createComponentEntity
        case removeComponent
        case updateComponentChanges
        case updateComponentContentChanges
        case captureAutomaticSnapshot
        case captureManualSnapshot
    }

    var actions = MockActions<Action>(expected: [])

    func createComponentEntity(parentPageID: UUID, component: any PageComponent)
        -> AnyPublisher<Void, Error>
    {
        register(.createComponentEntity)
        return Just<Void>.withErrorType(Error.self)
    }

    func removeComponent(parentPageID: UUID, componentID: UUID) {
        register(.removeComponent)
    }

    func updateComponentChanges(componentChanges: PageComponentChangeObject)
        -> AnyPublisher<Void, Error>
    {
        register(.updateComponentChanges)
        return Just<Void>.withErrorType(Error.self)
    }

    func updateComponentContentChanges(modifiedComponent: any PageComponent)
        -> AnyPublisher<Void, Error>
    {
        register(.updateComponentContentChanges)
        return Just<Void>.withErrorType(Error.self)
    }

    func captureSnapshot(snapshotRestorableComponent: any SnapshotRestorablePageComponent, snapShotDescription: String)
        -> AnyPublisher<Void, Error>
    {
        register(.captureManualSnapshot)
        return Just<Void>.withErrorType(Error.self)
    }

    func captureSnapshot(snapshotRestorableComponents: [any SnapshotRestorablePageComponent])
        -> AnyPublisher<Void, Error>
    {
        register(.captureAutomaticSnapshot)
        return Just<Void>.withErrorType(Error.self)
    }
}
