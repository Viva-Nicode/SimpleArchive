import CoreData
import Foundation

@objc(TableComponentSnapshotEntity)
public class TableComponentSnapshotEntity: NSManagedObject {
    func convertToModel() -> TableComponentSnapshot {
        TableComponentSnapshot(
            snapshotID: self.snapshotID,
            makingDate: self.makingDate,
            contents: self.convertToSnapshotContents()!,
            description: self.snapShotDescription,
            saveMode: .init(rawValue: self.saveMode) ?? .automatic)
    }

    private func convertToSnapshotContents() -> TableComponentContents? {
        var contents = TableComponentContents()
        guard let data = self.contents.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(TableComponentContents.self, from: data)
        else { return nil }

        contents.columns = decoded.columns
        contents.rows = decoded.rows
        contents.cells = decoded.cells
        contents.sortBy = decoded.sortBy

        return contents
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
}

extension TableComponentSnapshotEntity: Identifiable {

}
