import Foundation
import CoreData

@objc(TextEditorComponentSnapshotEntity)
public class TextEditorComponentSnapshotEntity: NSManagedObject {
    func convertToModel() -> TextEditorComponentSnapshot {
        TextEditorComponentSnapshot(
            snapshotID: self.snapshotID,
            makingDate: self.makingDate,
            contents: self.contents,
            description: self.snapShotDescription,
            saveMode: .init(rawValue: self.saveMode) ?? .automatic)
    }
}
