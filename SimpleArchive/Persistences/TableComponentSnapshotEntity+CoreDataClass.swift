import CoreData
import Foundation

@objc(TableComponentSnapshotEntity)
public class TableComponentSnapshotEntity: NSManagedObject {
    func convertToModel() -> TableComponentSnapshot {
        TableComponentSnapshot(
            snapshotID: self.snapshotID,
            makingDate: self.makingDate,
            contents: TableComponentContents(jsonString: self.contents)!,
            description: self.snapShotDescription,
            saveMode: .init(rawValue: self.saveMode) ?? .automatic)
    }
}
