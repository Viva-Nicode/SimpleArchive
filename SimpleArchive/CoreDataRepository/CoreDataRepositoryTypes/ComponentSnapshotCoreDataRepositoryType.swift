import Combine
import Foundation

protocol ComponentSnapshotCoreDataRepositoryType: AnyObject {
    func removeSnapshot(componentID: UUID, snapshotID: UUID)

    @discardableResult
    func revertComponentContents(modifiedComponent: any PageComponent) -> AnyPublisher<Void, Error>
}
