import Foundation

enum ComponentSnapshotViewModelInput {
    case viewDidLoad
    case willRestoreSnapshot
    case willRemoveSnapshot(UUID)
    case willUpdateSnapshotMetaData(Int)
}

enum ComponentSnapshotViewModelOutput {
    case viewDidLoad(any SnapshotRestorablePageComponent)
    case didRestoreSnapshot
    case didRemoveSnapshot(SnapshotMetaData?, Int)
    case didUpdateSnapshotMetaData(SnapshotMetaData)
}
