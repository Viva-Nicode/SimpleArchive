import CoreData
import Foundation

@objc(TableComponentSnapshotEntity)
public class TableComponentSnapshotEntity: NSManagedObject, Identifiable {
    func convertToModel() -> TableComponentSnapshot {
        TableComponentSnapshot(
            snapshotID: self.snapshotID,
            makingDate: self.makingDate,
            contents: self.convertToSnapshotContents()!,
            description: self.snapShotDescription,
            saveMode: .init(rawValue: self.saveMode) ?? .automatic,
            modificationHistory: convertToModificationHistory)
    }

    private var convertToModificationHistory: [TableComponentAction] {
        guard
            let jsonString = self.modificationHistory,
            !jsonString.isEmpty,
            let data = jsonString.data(using: .utf8)
        else { return [] }

        do {
            return try JSONDecoder().decode([TableComponentAction].self, from: data)
        } catch {
            assertionFailure("Failed to decode modificationHistory: \(error)")
            return []
        }
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

    // MARK: - ⚠️ 이걸 static으로 한게 좀 찜찜하다.
    static func persistTableComponentSnapshotContents(contents: TableComponentContents) -> String {
        guard let encoded = try? JSONEncoder().encode(contents),
            let jsonObject = try? JSONSerialization.jsonObject(with: encoded),
            let sortedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys])
        else { return "" }

        return String(data: sortedData, encoding: .utf8) ?? ""
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
        if let tableComponentSnapshot = snapshot as? TableComponentSnapshot {
            contents = TableComponentSnapshotEntity.persistTableComponentSnapshotContents(
                contents: tableComponentSnapshot.snapshotContents)
            modificationHistory = tableComponentSnapshot.modificationHistory.jsonString
        }
    }
}
