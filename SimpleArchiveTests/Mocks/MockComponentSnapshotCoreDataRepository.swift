import Combine
import Foundation

@testable import SimpleArchive

final class MockComponentSnapshotCoreDataRepository: Mock, ComponentSnapshotCoreDataRepositoryType {

    enum Action: Equatable {
        case updateComponentContentChanges
        case removeSnapshot
    }

    var actions = MockActions<Action>(expected: [])

    func updateComponentContentChanges(modifiedComponent: any PageComponent) -> AnyPublisher<Void, any Error> {
        register(.updateComponentContentChanges)
        return Just<Void>.withErrorType(Error.self)
    }

    func removeSnapshot(componentID: UUID, snapshotID: UUID) {
        register(.removeSnapshot)
    }
}
