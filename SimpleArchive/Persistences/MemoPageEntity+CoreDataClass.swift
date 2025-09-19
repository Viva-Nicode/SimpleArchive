import CoreData
import Foundation

@objc(MemoPageEntity)
public class MemoPageEntity: StorageItemEntity {

    @discardableResult
    override func convertToModel(parentDirectory: MemoDirectoryModel?) -> any StorageItem {
        let page = MemoPageModel(
            id: self.id,
            name: self.name,
            creationDate: self.creationDate,
            isSingleComponentPage: self.isSingleComponentPage,
            parentDirectory: parentDirectory,
            components: self.components
                .compactMap { $0.convertToModel() }
                .sorted { $0.renderingOrder < $1.renderingOrder })

        return page
    }

    override func moveToDormantBox(in ctx: NSManagedObjectContext, dormantBox: MemoDirectoryEntity) {
        components.forEach { $0.isMinimumHeight = false }
        self.containingDirectory.removeFromPages(self)
        dormantBox.addToPages(self)
    }
}
