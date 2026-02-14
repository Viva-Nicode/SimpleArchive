import Combine
import Foundation

typealias InfoForCreateSnapshotEntity = (componentID: UUID, snapshot: any ComponentSnapshotType)

protocol ComponentSnapshotCoreDataRepositoryType: AnyObject {

    @discardableResult
    func createComponentSnapshot(snapshots: [InfoForCreateSnapshotEntity]) -> AnyPublisher<Void, Error>

    func removeSnapshot(componentID: UUID, snapshotID: UUID)

    @discardableResult
    func revertComponentContents(
        modifiedComponent: any PageComponent,
        trackingSnapshot: any ComponentSnapshotType
    ) -> AnyPublisher<Void, Error>
}
