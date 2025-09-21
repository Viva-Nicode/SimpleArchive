import Foundation
import CoreData

@objc(TextEditorComponentEntity)
public class TextEditorComponentEntity: MemoComponentEntity {

    override func convertToModel() -> any PageComponent {
        let textEditorComponent = TextEditorComponent(
            id: self.id,
            renderingOrder: self.renderingOrder,
            isMinimumHeight: self.isMinimumHeight,
            creationDate: self.creationDate,
            title: self.title,
            detail: self.detail,
            persistenceState: .synced,
            componentSnapshots: self.snapshots
                .map { $0.convertToModel() }
                .sorted(by: { $0.makingDate > $1.makingDate }))

        return textEditorComponent
    }

    override func setDetail<T:Codable>(detail: T) {
        self.detail = detail as! String
    }

    override func removeSnapshot(ctx: NSManagedObjectContext, snapshotID: UUID) {
        if let removedSnapshotIndex = snapshots.firstIndex(where: { $0.snapshotID == snapshotID }) {
            let removedSnapshot = snapshots.remove(at: removedSnapshotIndex)
            ctx.delete(removedSnapshot)
        }
    }
}
