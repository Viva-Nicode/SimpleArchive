import Combine
import Foundation

@testable import SimpleArchive

final class MockComponentSnapshotCoreDataRepository: Mock, ComponentSnapshotCoreDataRepositoryType {

    enum Action: Equatable {
        case revertComponentContents
        case removeSnapshot
    }

    var actions = MockActions<Action>(expected: [])

    func removeSnapshot(componentID: UUID, snapshotID: UUID) {
        register(.removeSnapshot)
    }

    func revertComponentContents(modifiedComponent: any PageComponent) -> AnyPublisher<Void, Error> {
        register(.revertComponentContents)
        return Just<Void>.withErrorType(Error.self)
    }
}
