import Combine
import Foundation

protocol DormantBoxCoreDataRepositoryType {
    func fetchDormantBoxDirectory() -> AnyPublisher<MemoDirectoryModel, Error>

    @discardableResult
    func restoreFile(restoredFileID: UUID) -> AnyPublisher<Void, Error>
}
