import Foundation
import Combine

protocol ComponentSnapshotCoreDataRepositoryType {
    func removeSnapshot(componentID: UUID, snapshotID: UUID)
    
    @discardableResult
    func revertComponentContents(modifiedComponent: any PageComponent) -> AnyPublisher<Void, Error>
}
