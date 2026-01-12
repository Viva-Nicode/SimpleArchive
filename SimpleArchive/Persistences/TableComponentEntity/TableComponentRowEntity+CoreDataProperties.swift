//
//  TableComponentRowEntity+CoreDataProperties.swift
//  SimpleArchive
//
//  Created by Nicode . on 12/9/25.
//
//

import CoreData
import Foundation

extension TableComponentRowEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TableComponentRowEntity> {
        return NSFetchRequest<TableComponentRowEntity>(entityName: "TableComponentRowEntity")
    }

    @nonobjc public class func findRowByID(_ id: UUID) -> NSFetchRequest<TableComponentRowEntity> {
        let request = NSFetchRequest<TableComponentRowEntity>(entityName: "TableComponentRowEntity")
        request.predicate = NSPredicate(
            format: "%K == %@",
            (\TableComponentRowEntity.id)._kvcKeyPathString!,
            id as CVarArg
        )
        request.fetchLimit = 1
        return request
    }

    @NSManaged public var createdAt: Date
    @NSManaged public var id: UUID
    @NSManaged public var modifiedAt: Date
    @NSManaged public var tableComponent: TableComponentEntity
    @NSManaged public var cells: Set<TableComponentCellEntity>

}

// MARK: Generated accessors for cells
extension TableComponentRowEntity {

    @objc(addCellsObject:)
    @NSManaged public func addToCells(_ value: TableComponentCellEntity)

    @objc(removeCellsObject:)
    @NSManaged public func removeFromCells(_ value: TableComponentCellEntity)

    @objc(addCells:)
    @NSManaged public func addToCells(_ values: NSSet)

    @objc(removeCells:)
    @NSManaged public func removeFromCells(_ values: NSSet)

}

extension TableComponentRowEntity: Identifiable {

}
