//
//  TableComponentCellEntity+CoreDataProperties.swift
//  SimpleArchive
//
//  Created by Nicode . on 12/9/25.
//
//

import CoreData
import Foundation

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
