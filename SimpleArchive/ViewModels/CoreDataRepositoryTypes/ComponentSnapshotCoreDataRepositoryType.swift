import Foundation

protocol ComponentSnapshotCoreDataRepositoryType {
    func removeSnapshot(componentID: UUID, snapshotID: UUID)
}
