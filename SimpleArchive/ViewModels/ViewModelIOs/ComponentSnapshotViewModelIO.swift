import Foundation

enum ComponentSnapshotViewModelInput {
    case viewDidLoad
    case restoreSnapshot
    case removeSnapshot(UUID)
}

enum ComponentSnapshotViewModelOutput {
    case viewDidLoad(SnapshotMetaData?)
    case hasScrolled(SnapshotMetaData)
    case didCompleteRestoreSnapshot
    case didCompleteRemoveSnapshot(SnapshotMetaData?, Int)
}

enum ComponentSnapshotViewModelError: MessageErrorType {
    case unownedError
    case canNotFoundSnapshot(UUID)
    case componentIDMismatchError

    var errorMessage: String {
        switch self {
        case .unownedError:
            return "An unknown error has occurred.\nWe’re sorry for the inconvenience.\nPlease try again later."
        case .canNotFoundSnapshot(_):
            return "No corresponding snapshots found."
        case .componentIDMismatchError:
            return "The ID of the snapshot you want to delete does not match the ID of the snapshot currently being displayed."
        }
    }
}

protocol MessageErrorType: Error {
    var errorMessage: String { get }
}
