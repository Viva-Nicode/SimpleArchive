import Foundation
import CoreData

@objc(TextEditorComponentSnapshotEntity)
public class TextEditorComponentSnapshotEntity: NSManagedObject {
    func convertToModel() -> TextEditorComponentSnapshot {
        TextEditorComponentSnapshot(
            snapshotID: self.snapshotID,
            makingDate: self.makingDate,
            detail: self.detail,
            description: self.snapShotDescription,
            saveMode: .init(rawValue: self.saveMode) ?? .automatic)
    }
}
