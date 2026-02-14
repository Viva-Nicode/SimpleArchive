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
            contents: self.convertToContentsModel(),
            captureState: .captured,
            componentSnapshots: self.snapshots
                .map { $0.convertToModel() }
                .sorted(by: { $0.makingDate > $1.makingDate })
        )

        return tableComponent
    }

    override func removeSnapshot(snapshotID: UUID) {
        guard
            let context = managedObjectContext,
            let removedSnapshotIndex = snapshots.firstIndex(where: { $0.snapshotID == snapshotID })
        else { return }

        let removedSnapshot = snapshots.remove(at: removedSnapshotIndex)
        context.delete(removedSnapshot)
    }

    override func updatePageComponentEntityContents(componentModel: any PageComponent) {
        if let tableComponent = componentModel as? TableComponent,
            let mostRecentAction = tableComponent.actions.last,
            let context = managedObjectContext
        {
            switch mostRecentAction {
                case .appendRow(let row):
                    let rowEntity = TableComponentRowEntity(context: context)
                    rowEntity.id = row.id
                    rowEntity.createdAt = row.createdAt
                    rowEntity.modifiedAt = row.modifiedAt
                    rowEntity.tableComponent = self

                    for case let columnEntity as TableComponentColumnEntity in self.columns {
                        let cellEntity = TableComponentCellEntity(context: context)
                        cellEntity.value = ""

                        cellEntity.column = columnEntity
                        cellEntity.row = rowEntity

                        rowEntity.addToCells(cellEntity)
                        columnEntity.addToCells(cellEntity)
                    }

                    let orderedRows = self.mutableOrderedSetValue(forKey: "rows")
                    orderedRows.add(rowEntity)

                case .appendColumn(let column):
                    let columnEntity = TableComponentColumnEntity(context: context)
                    columnEntity.id = column.id
                    columnEntity.title = column.title
                    columnEntity.tableComponent = self

                    for case let rowEntity as TableComponentRowEntity in self.rows {
                        let cellEntity = TableComponentCellEntity(context: context)
                        cellEntity.value = ""

                        cellEntity.row = rowEntity
                        cellEntity.column = columnEntity

                        columnEntity.addToCells(cellEntity)
                        rowEntity.addToCells(cellEntity)
                    }

                    let orderedColumns = self.mutableOrderedSetValue(forKey: "columns")
                    orderedColumns.add(columnEntity)

                case .removeRow(let rowID):
                    let fetchRequest = TableComponentRowEntity.findRowByID(rowID)
                    if let rowEntity = try? context.fetch(fetchRequest).first { context.delete(rowEntity) }

                case .editColumn(let columns):
                    let columnEntities = self.mutableOrderedSetValue(forKey: "columns")
                    var columnList = columnEntities.array as! [TableComponentColumnEntity]

                    for (index, column) in columns.enumerated() {
                        if let fromIndex = columnList.firstIndex(where: { $0.id == column.id }) {
                            let fromIndexSet = IndexSet(integer: fromIndex)

                            columnEntities.moveObjects(at: fromIndexSet, to: index)
                            columnList.moveElement(src: fromIndex, des: index)
                            columnList[index].title = column.title
                        }
                    }

                    if columns.count < columnList.count {
                        for i in columns.count..<columnList.count {
                            context.delete(columnList[i])
                        }
                    }

                case .editCellValue(let rowID, let columnID, let value):
                    let fetchRequest = TableComponentCellEntity.findCellByID(rowID: rowID, colID: columnID)
                    if let cellEntity = try? context.fetch(fetchRequest).first { cellEntity.value = value }
            }
        }
    }

    override func revertComponentEntityContents(componentModel: any PageComponent) {
        guard
            let tableComponent = componentModel as? TableComponent,
            let context = managedObjectContext
        else { return }

        for case let columnEntity as NSManagedObject in columns {
            context.delete(columnEntity)
        }
        columns.removeAllObjects()

        for case let rowEntity as NSManagedObject in rows {
            context.delete(rowEntity)
        }
        rows.removeAllObjects()

        let orderedColumns = mutableOrderedSetValue(forKey: "columns")

        for col in tableComponent.componentContents.columns {
            let colEntity = TableComponentColumnEntity(context: context)
            colEntity.id = col.id
            colEntity.title = col.title
            colEntity.tableComponent = self

            orderedColumns.add(colEntity)
        }

        let orderedRows = mutableOrderedSetValue(forKey: "rows")

        for row in tableComponent.componentContents.rows {
            let rowEntity = TableComponentRowEntity(context: context)
            rowEntity.id = row.id
            rowEntity.createdAt = row.createdAt
            rowEntity.modifiedAt = row.modifiedAt
            rowEntity.tableComponent = self

            orderedRows.add(rowEntity)
        }

        for case let columnEntity as TableComponentColumnEntity in columns {
            for case let rowEntity as TableComponentRowEntity in rows {
                let cellEntity = TableComponentCellEntity(context: context)
                cellEntity.value = tableComponent.componentContents.cells[rowEntity.id]?[columnEntity.id] ?? ""

                cellEntity.row = rowEntity
                cellEntity.column = columnEntity

                rowEntity.addToCells(cellEntity)
                columnEntity.addToCells(cellEntity)
            }
        }
    }

    override func findSnapshotEntityByID(id: UUID) -> PageComponentSnapshotEntity? {
        snapshots.first(where: { $0.snapshotID == id })
    }

    private func convertToContentsModel() -> TableComponentContents {
        var contents = TableComponentContents()
        contents.sortBy = TableComponentContents.TableRowSortCriteria(rawValue: self.sortBy)!

        let columnEntities = columns.array as! [TableComponentColumnEntity]

        contents.columns = columnEntities.compactMap { colEntity -> TableComponentColumn in
            let id = colEntity.id
            let title = colEntity.title
            return TableComponentColumn(id: id, title: title)
        }

        let rowEntities = self.rows.array as! [TableComponentRowEntity]

        contents.rows = rowEntities.compactMap { rowEntity -> TableComponentRow in
            let id = rowEntity.id
            var row = TableComponentRow(id: id)
            row.createdAt = rowEntity.createdAt
            row.modifiedAt = rowEntity.modifiedAt
            return row
        }

        var restoredCells: [UUID: [UUID: String]] = [:]

        for rowEntity in rowEntities {
            let rowID = rowEntity.id
            let cellEntities = rowEntity.cells

            for cellEntity in cellEntities {
                if cellEntity.value.isEmpty { continue }

                restoredCells[rowID, default: [:]][cellEntity.column.id] = cellEntity.value
            }
        }

        contents.cells = restoredCells
        return contents
    }
}

extension TableComponentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TableComponentEntity> {
        NSFetchRequest<TableComponentEntity>(entityName: "TableComponentEntity")
    }

    @nonobjc public class func findTableComponentEntityById(id: UUID) -> NSFetchRequest<TableComponentEntity> {
        let fetchRequest = NSFetchRequest<TableComponentEntity>(entityName: "TableComponentEntity")
        let fetchPredicate = NSPredicate(
            format: "%K == %@", (\TableComponentEntity.id)._kvcKeyPathString!, id as CVarArg)
        fetchRequest.predicate = fetchPredicate
        fetchRequest.fetchLimit = 1
        return fetchRequest
    }

    @NSManaged public var sortBy: String
    @NSManaged public var columns: NSMutableOrderedSet
    @NSManaged public var rows: NSMutableOrderedSet

    @NSManaged public var snapshots: Set<TableComponentSnapshotEntity>
}

extension TableComponentEntity {

    @objc(addSnapshotsObject:)
    @NSManaged public func addToSnapshots(_ value: TableComponentSnapshotEntity)

    @objc(removeSnapshotsObject:)
    @NSManaged public func removeFromSnapshots(_ value: TableComponentSnapshotEntity)

    @objc(addSnapshots:)
    @NSManaged public func addToSnapshots(_ values: NSSet)

    @objc(removeSnapshots:)
    @NSManaged public func removeFromSnapshots(_ values: NSSet)
}
