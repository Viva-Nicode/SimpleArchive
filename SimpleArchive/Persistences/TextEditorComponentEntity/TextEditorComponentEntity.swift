import CoreData
import Foundation

@objc(TextEditorComponentEntity)
public class TextEditorComponentEntity: MemoComponentEntity, SnapshotRestorableComponentEntityType {
    override func convertToModel() -> any PageComponent {
        let textEditorComponent = TextEditorComponent(
            id: self.id,
            renderingOrder: self.renderingOrder,
            isMinimumHeight: self.isMinimumHeight,
            creationDate: self.creationDate,
            title: self.title,
            contents: self.contents,
            captureState: .captured,
            componentSnapshots: self.snapshots
                .map { $0.convertToModel() }
                .sorted(by: { $0.makingDate > $1.makingDate }))

        return textEditorComponent
    }

    override func updatePageComponentEntityContents(componentModel: any PageComponent) {
        guard
            let textEditorComponent = componentModel as? TextEditorComponent
        else { return }
        self.contents = textEditorComponent.componentContents
    }

    func revertComponentEntityContents(componentModel: any PageComponent) {
        guard
            let textEditorComponent = componentModel as? TextEditorComponent
        else { return }
        self.contents = textEditorComponent.componentContents
    }
}

extension TextEditorComponentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TextEditorComponentEntity> {
        return NSFetchRequest<TextEditorComponentEntity>(entityName: "TextEditorComponentEntity")
    }

    @nonobjc public class func findTextComponentEntityById(id: UUID) -> NSFetchRequest<TextEditorComponentEntity> {
        let fetchRequest = NSFetchRequest<TextEditorComponentEntity>(entityName: "TextEditorComponentEntity")
        let fetchPredicate = NSPredicate(
            format: "%K == %@", (\TextEditorComponentEntity.id)._kvcKeyPathString!, id as CVarArg)
        fetchRequest.predicate = fetchPredicate
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    @NSManaged public var contents: String
    @NSManaged public var snapshots: Set<TextEditorComponentSnapshotEntity>

}

extension TextEditorComponentEntity {

    @objc(addSnapshotsObject:)
    @NSManaged public func addToSnapshots(_ value: TextEditorComponentSnapshotEntity)

    @objc(removeSnapshotsObject:)
    @NSManaged public func removeFromSnapshots(_ value: TextEditorComponentSnapshotEntity)

    @objc(addSnapshots:)
    @NSManaged public func addToSnapshots(_ values: NSSet)

    @objc(removeSnapshots:)
    @NSManaged public func removeFromSnapshots(_ values: NSSet)

}
