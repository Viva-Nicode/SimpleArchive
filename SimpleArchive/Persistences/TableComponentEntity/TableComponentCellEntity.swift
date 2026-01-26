import CoreData
import Foundation

@objc(TableComponentCellEntity)
public class TableComponentCellEntity: NSManagedObject {}

extension TableComponentCellEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TableComponentCellEntity> {
        return NSFetchRequest<TableComponentCellEntity>(entityName: "TableComponentCellEntity")
    }

    @nonobjc public class func findCellByID(rowID: UUID, colID: UUID) -> NSFetchRequest<TableComponentCellEntity> {
        let request = NSFetchRequest<TableComponentCellEntity>(entityName: "TableComponentCellEntity")

        request.fetchLimit = 1
        request.predicate = NSPredicate(
            format: "row.id == %@ AND column.id == %@",
            rowID as CVarArg,
            colID as CVarArg
        )

        return request
    }

    @NSManaged public var value: String
    @NSManaged public var row: TableComponentRowEntity
    @NSManaged public var column: TableComponentColumnEntity

}

extension TableComponentCellEntity: Identifiable {

}
