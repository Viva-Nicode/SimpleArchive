import Foundation
import CoreData

@objc(StorageItemEntity)
public class StorageItemEntity: NSManagedObject {

    func convertToModel(parentDirectory: MemoDirectoryModel?) -> any StorageItem {
        fatalError("Method is not overridden.")
    }

    func moveToDormantBox(in ctx: NSManagedObjectContext, dormantBox: MemoDirectoryEntity) {
        fatalError("Method is not overridden.")
    }
}
