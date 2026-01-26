import CoreData
import Foundation

@objc(TableComponentColumnEntity)
public class TableComponentColumnEntity: NSManagedObject {

}

extension TableComponentColumnEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TableComponentColumnEntity> {
        return NSFetchRequest<TableComponentColumnEntity>(entityName: "TableComponentColumnEntity")
    }

    @nonobjc public class func findColumnByID(_ id: UUID) -> NSFetchRequest<TableComponentColumnEntity> {
        let request = NSFetchRequest<TableComponentColumnEntity>(entityName: "TableComponentColumnEntity")
        request.predicate = NSPredicate(
            format: "%K == %@",
            (\TableComponentColumnEntity.id)._kvcKeyPathString!,
            id as CVarArg
        )
        request.fetchLimit = 1
        return request
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var tableComponent: TableComponentEntity
    @NSManaged public var cells: Set<TableComponentCellEntity>

}

extension TableComponentColumnEntity {

    @objc(addCellsObject:)
    @NSManaged public func addToCells(_ value: TableComponentCellEntity)

    @objc(removeCellsObject:)
    @NSManaged public func removeFromCells(_ value: TableComponentCellEntity)

    @objc(addCells:)
    @NSManaged public func addToCells(_ values: NSSet)

    @objc(removeCells:)
    @NSManaged public func removeFromCells(_ values: NSSet)

}

extension TableComponentColumnEntity: Identifiable {

}
