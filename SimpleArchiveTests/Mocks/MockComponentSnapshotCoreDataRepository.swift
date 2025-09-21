import Foundation

@testable import SimpleArchive

final class MockComponentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType {
    func removeSnapshot(componentID: UUID, snapshotID: UUID) {}
}
