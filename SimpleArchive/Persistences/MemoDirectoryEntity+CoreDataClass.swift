import Foundation
import CoreData

@objc(MemoDirectoryEntity)
public class MemoDirectoryEntity: StorageItemEntity {

    @discardableResult
    override func convertToModel(parentDirectory: MemoDirectoryModel? = nil) -> any StorageItem {
        let directory = MemoDirectoryModel(
            id: self.id,
            creationDate: self.creationDate,
            name: self.name,
            sortBy: .init(rawValue: self.sortBy) ?? .name,
            parentDirectory: parentDirectory)

        self.childDirectories.forEach { $0.convertToModel(parentDirectory: directory) }
        self.pages.forEach { $0.convertToModel(parentDirectory: directory) }

        return directory
    }

    override func moveToDormantBox(in ctx: NSManagedObjectContext, dormantBox: MemoDirectoryEntity) {

        for childDirectory in self.childDirectories {
            childDirectory.moveToDormantBox(in: ctx, dormantBox: dormantBox)
        }

        for childPage in self.pages {
            childPage.moveToDormantBox(in: ctx, dormantBox: dormantBox)
        }

        self.parentDirectory?.removeFromChildDirectories(self)
        ctx.delete(self)
    }
}
