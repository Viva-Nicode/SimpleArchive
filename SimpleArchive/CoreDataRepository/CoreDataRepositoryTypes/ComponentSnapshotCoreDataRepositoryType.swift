import Combine
import Foundation

protocol ComponentSnapshotCoreDataRepositoryType: AnyObject {

    typealias InfoForCreateSnapshotEntity = (componentID: UUID, snapshot: any ComponentSnapshotType)

    @discardableResult
    func createComponentSnapshot(snapshots: [InfoForCreateSnapshotEntity]) -> AnyPublisher<Void, Error>

    func removeSnapshot(componentID: UUID, snapshotID: UUID)

    @discardableResult
    func revertComponentContents(modifiedComponent: any PageComponent) -> AnyPublisher<Void, Error>
}
