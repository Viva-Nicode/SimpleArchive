import Foundation
import Combine

protocol ComponentSnapshotCoreDataRepositoryType {
    func removeSnapshot(componentID: UUID, snapshotID: UUID)
    
    @discardableResult
    func updateComponentContentChanges(modifiedComponent: any PageComponent) -> AnyPublisher<Void, Error>
}
