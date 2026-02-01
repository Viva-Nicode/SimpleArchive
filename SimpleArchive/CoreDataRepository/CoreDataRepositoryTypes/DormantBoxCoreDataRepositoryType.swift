import Combine
import Foundation

protocol DormantBoxCoreDataRepositoryType: AnyObject {
    func fetchDormantBoxDirectory() -> AnyPublisher<MemoDirectoryModel, Error>

    @discardableResult
    func restoreFile(restoredFileID: UUID) -> AnyPublisher<Void, Error>

    @discardableResult
    func permanentRemoveFile(pageID: UUID) -> AnyPublisher<Void, Error>
}
