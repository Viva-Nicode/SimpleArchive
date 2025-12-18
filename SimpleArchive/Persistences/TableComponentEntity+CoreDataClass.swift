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
            contents: TableComponentContents(entity: self),
            captureState: .captured,
            componentSnapshots: self.snapshots
                .map { $0.convertToModel() }
                .sorted(by: { $0.makingDate > $1.makingDate }))

        return tableComponent
    }

    override func removeSnapshot(ctx: NSManagedObjectContext, snapshotID: UUID) {
        if let removedSnapshotIndex = snapshots.firstIndex(where: { $0.snapshotID == snapshotID }) {
            let removedSnapshot = snapshots.remove(at: removedSnapshotIndex)
            ctx.delete(removedSnapshot)
        }
    }

    override func updatePageComponentEntityContents(
        in ctx: NSManagedObjectContext,
        componentModel: any PageComponent
    ) {
        if let tableComponent = componentModel as? TableComponent,
            let mostRecentAction = tableComponent.actions.last
        {
            switch mostRecentAction {
                case .appendRow(let row):
                    let rowEntity = TableComponentRowEntity(context: ctx)
                    rowEntity.id = row.id
                    rowEntity.createdAt = row.createdAt
                    rowEntity.modifiedAt = row.modifiedAt
                    rowEntity.tableComponent = self

                    for case let columnEntity as TableComponentColumnEntity in self.columns {
                        let cellEntity = TableComponentCellEntity(context: ctx)
                        cellEntity.value = ""

                        cellEntity.column = columnEntity
                        cellEntity.row = rowEntity

                        rowEntity.addToCells(cellEntity)
                        columnEntity.addToCells(cellEntity)
                    }

                    let orderedRows = self.mutableOrderedSetValue(forKey: "rows")
                    orderedRows.add(rowEntity)

                case .appendColumn(let column):
                    let columnEntity = TableComponentColumnEntity(context: ctx)
                    columnEntity.id = column.id
                    columnEntity.title = column.title
                    columnEntity.tableComponent = self

                    for case let rowEntity as TableComponentRowEntity in self.rows {
                        let cellEntity = TableComponentCellEntity(context: ctx)
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
                    if let rowEntity = try? ctx.fetch(fetchRequest).first {
                        ctx.delete(rowEntity)
                    }

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
                            ctx.delete(columnList[i])
                        }
                    }

                case .editCellValue(let rowID, let columnID, let value):
                    let fetchRequest = TableComponentCellEntity.findCellByID(rowID: rowID, colID: columnID)

                    if let cellEntity = try? ctx.fetch(fetchRequest).first {
                        cellEntity.value = value
                    }
            }
        }
    }
}
