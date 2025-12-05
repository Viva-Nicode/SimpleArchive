import CoreData
import Foundation

@objc(TableComponentEntity)
public class TableComponentEntity: MemoComponentEntity {
    override func convertToModel() -> any PageComponent {
        let tableComponent = TableComponent(
            id: self.id,
            renderingOrder: self.renderingOrder,
            isMinimumHeight: self.isMinimumHeight,
            creationDate: self.creationDate,
            title: self.title,
            detail: TableComponentContent(jsonString: self.detail)!,
            captureState: .captured,
            componentSnapshots: self.snapshots
                .map { $0.convertToModel() }
                .sorted(by: { $0.makingDate > $1.makingDate }))

        return tableComponent
    }

    override func setDetail<T: Codable>(detail: T) {
        self.detail = (detail as! TableComponentContent).jsonString
    }

    override func removeSnapshot(ctx: NSManagedObjectContext, snapshotID: UUID) {
        if let removedSnapshotIndex = snapshots.firstIndex(where: { $0.snapshotID == snapshotID }) {
            let removedSnapshot = snapshots.remove(at: removedSnapshotIndex)
            ctx.delete(removedSnapshot)
        }
    }
}
