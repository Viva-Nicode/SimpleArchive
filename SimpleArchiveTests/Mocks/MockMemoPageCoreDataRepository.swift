import Combine
import Foundation

@testable import SimpleArchive

final class MockMemoPageCoreDataRepository: Mock, MemoPageCoreDataRepositoryType {

    enum Action: Equatable {
        case fixPages
        case unfixPages
    }

    var actions = MockActions<Action>(expected: [])
    var fixPagesResult: Result<Void, Error> = .failure(MockError.valueNotSet)
    var unfixPagesResult: Result<Void, Error> = .failure(MockError.valueNotSet)

    func fixPages(pageIds: [UUID]) -> AnyPublisher<Void, Error> {
        register(.fixPages)
        return fixPagesResult.publish()
    }

    func unfixPages(parentDirectoryId: UUID, pageIds: [UUID]) -> AnyPublisher<Void, Error> {
        register(.unfixPages)
        return unfixPagesResult.publish()
    }
}
