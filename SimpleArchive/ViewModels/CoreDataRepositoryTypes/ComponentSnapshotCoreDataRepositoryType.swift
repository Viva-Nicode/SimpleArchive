import Foundation
import Combine

protocol ComponentSnapshotCoreDataRepositoryType {
    func removeSnapshot(componentID: UUID, snapshotID: UUID)
    
    @discardableResult
    func saveComponentsDetail(modifiedComponent: any PageComponent) -> AnyPublisher<Void, Error>
}
