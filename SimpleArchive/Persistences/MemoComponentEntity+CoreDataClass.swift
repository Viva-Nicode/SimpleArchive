import Foundation
import CoreData

@objc(MemoComponentEntity)
public class MemoComponentEntity: NSManagedObject {

    func convertToModel() -> any PageComponent {
        fatalError("Method is not overridden.")
    }

    func removeSnapshot(ctx: NSManagedObjectContext, snapshotID: UUID) {
        fatalError("Method is not overridden.")
    }
}
