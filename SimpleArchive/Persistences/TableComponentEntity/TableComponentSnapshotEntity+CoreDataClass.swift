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
