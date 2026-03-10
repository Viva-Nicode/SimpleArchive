import CoreData
import Foundation

@objc(TableComponentSnapshotEntity)
public class TableComponentSnapshotEntity: NSManagedObject, Identifiable {
    func convertToModel() -> TableComponentSnapshot {
        let converter = JsonConverter.shared
        return TableComponentSnapshot(
            snapshotID: self.snapshotID,
            makingDate: self.makingDate,
            contents: converter.decode(TableComponentContents.self, jsonString: self.contents)!,
            description: self.snapShotDescription,
            saveMode: .init(rawValue: self.saveMode) ?? .automatic,
            modificationHistory: self.modificationHistory == nil
                ? [] : converter.decode([TableComponentAction].self, jsonString: self.modificationHistory!)!)
    }
}

extension TableComponentSnapshotEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TableComponentSnapshotEntity> {
        return NSFetchRequest<TableComponentSnapshotEntity>(entityName: "TableComponentSnapshotEntity")
    }

    @NSManaged public var contents: String
    @NSManaged public var makingDate: Date
    @NSManaged public var saveMode: String
    @NSManaged public var snapShotDescription: String
    @NSManaged public var snapshotID: UUID
    @NSManaged public var component: TableComponentEntity
    @NSManaged public var modificationHistory: String?
}

extension TableComponentSnapshotEntity: PageComponentSnapshotEntity {
    func updateTrackingSnapshotContents(snapshot: any ComponentSnapshotType) {
        let converter = JsonConverter.shared
        if let tableComponentSnapshot = snapshot as? TableComponentSnapshot {
            contents = converter.encode(object: tableComponentSnapshot.snapshotContents)
            modificationHistory = converter.encode(object: tableComponentSnapshot.modificationHistory)
        }
    }
}
