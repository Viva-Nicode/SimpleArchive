import CoreData
import Foundation

protocol SnapshotRestorableComponentEntityType: NSObject {
    associatedtype PageComponentSnapshotEntityType: PageComponentSnapshotEntity

    var snapshots: Set<PageComponentSnapshotEntityType> { get set }
    var managedObjectContext: NSManagedObjectContext? { get }

    func findSnapshotEntityByID(snapshotID: UUID) -> PageComponentSnapshotEntity?
    func revertComponentEntityContents(componentModel: any PageComponent)
    func removeSnapshot(snapshotID: UUID)
}

extension SnapshotRestorableComponentEntityType {
    func findSnapshotEntityByID(snapshotID: UUID) -> PageComponentSnapshotEntity? {
        snapshots.first(where: { $0.snapshotID == snapshotID })
    }

    func removeSnapshot(snapshotID: UUID) {
        guard
            let context = managedObjectContext,
            let removedSnapshotIndex = snapshots.firstIndex(where: { $0.snapshotID == snapshotID })
        else { return }

        let removedSnapshot = snapshots.remove(at: removedSnapshotIndex)
        context.delete(removedSnapshot)
    }
}

protocol PageComponentSnapshotEntity: NSManagedObject {
    var snapshotID: UUID { get set }
    var makingDate: Date { get set }
    var saveMode: String { get set }
    var snapShotDescription: String { get set }

    func updateTrackingSnapshotContents(snapshot: any ComponentSnapshotType)
    func updateSnapshotInfo(snapshot: any ComponentSnapshotType)
}

extension PageComponentSnapshotEntity {
    func updateSnapshotInfo(snapshot: any ComponentSnapshotType) {
        makingDate = snapshot.makingDate
        snapShotDescription = snapshot.description
        saveMode = snapshot.saveMode.rawValue
    }
}
