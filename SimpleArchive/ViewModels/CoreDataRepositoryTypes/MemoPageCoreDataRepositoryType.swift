import Combine
import Foundation

protocol MemoPageCoreDataRepositoryType {

    @discardableResult
    func fixPages(pageIds: [UUID]) -> AnyPublisher<Void, Error>

    @discardableResult
    func unfixPages(parentDirectoryId: UUID, pageIds: [UUID]) -> AnyPublisher<Void, Error>
}
