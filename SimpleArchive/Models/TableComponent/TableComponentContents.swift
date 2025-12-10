import CoreData
import Foundation

struct TableComponentContents: Codable {

    private(set) var columns: [TableComponentColumn]
    private(set) var rows: [TableComponentRow]
    private var cells: [UUID: [UUID: String]]
    var sortBy: TableRowSortCriteria

    enum TableRowSortCriteria: String, Codable {
        case created = "created"
        case modified = "modified"
        case manual = "manual"
    }

    init() {
        self.columns = [TableComponentColumn(title: "column")]
        self.cells = [:]
        self.sortBy = .created
        self.rows = [TableComponentRow()]
    }

    var cellValues: [(rowID: UUID, cells: [String])] {
        rows.map { row in
            (
                rowID: row.id,
                cells: columns.map { column in
                    cells[row.id]?[column.id] ?? ""
                }
            )
        }
    }

    mutating func appendNewColumn(title: String) -> TableComponentColumn {
        let newCol = TableComponentColumn(title: title)
        columns.append(newCol)
        return newCol
    }

    mutating func appendNewRow() -> TableComponentRow {
        let newRow = TableComponentRow()
        self.rows.append(newRow)
        return newRow
    }

    mutating func removeRow(_ rowID: UUID) -> Int {
        guard let index = rows.firstIndex(where: { $0.id == rowID }) else { return -1 }
        rows.remove(at: index)
        cells.removeValue(forKey: rowID)
        return index
    }

    mutating func setColumn(columns: [TableComponentColumn]) {
        self.columns = columns
        if self.columns.isEmpty {
            self.rows = []
            self.cells = [:]
        }
    }

    mutating func editCellValeu(rowID: UUID, colID: UUID, newValue: String) -> (rowIndex: Int, columnIndex: Int) {
        let rowIndex = rows.firstIndex(where: { $0.id == rowID })!
        let columnIndex = columns.firstIndex(where: { $0.id == colID })!
        cells[rowID, default: [:]][colID] = newValue
        rows[rowIndex].modifiedAt = Date()
        return (rowIndex, columnIndex)
    }
}

struct TableComponentColumn: Codable, Identifiable, Hashable {
    let id: UUID
    var title: String

    init(id: UUID = UUID(), title: String) {
        self.id = id
        self.title = title
    }
}

struct TableComponentRow: Codable, Identifiable, Hashable {
    let id: UUID
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID()) {
        self.id = id
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}

extension TableComponentContents {

    init(entity: TableComponentEntity) {

        self.sortBy = TableRowSortCriteria(rawValue: entity.sortBy)!

        let columnEntities = entity.columns.array as! [TableComponentColumnEntity]

        self.columns = columnEntities.compactMap { colEntity -> TableComponentColumn in
            let id = colEntity.id
            let title = colEntity.title
            return TableComponentColumn(id: id, title: title)
        }

        let rowEntities = entity.rows.array as! [TableComponentRowEntity]

        self.rows = rowEntities.compactMap { rowEntity -> TableComponentRow in
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

        self.cells = restoredCells
    }

    func storeTableComponentContent(for tableComponentEntity: TableComponentEntity, in ctx: NSManagedObjectContext) {

        tableComponentEntity.sortBy = self.sortBy.rawValue

        for col in self.columns {
            let colEntity = TableComponentColumnEntity(context: ctx)
            colEntity.id = col.id
            colEntity.title = col.title
            colEntity.tableComponent = tableComponentEntity

            let orderedRows = tableComponentEntity.mutableOrderedSetValue(forKey: "columns")
            orderedRows.add(colEntity)
        }

        for row in self.rows {
            let rowEntity = TableComponentRowEntity(context: ctx)
            rowEntity.id = row.id
            rowEntity.createdAt = row.createdAt
            rowEntity.modifiedAt = row.modifiedAt
            rowEntity.tableComponent = tableComponentEntity

            let orderedRows = tableComponentEntity.mutableOrderedSetValue(forKey: "rows")
            orderedRows.add(rowEntity)
        }

        for case let columnEntity as TableComponentColumnEntity in tableComponentEntity.columns {
            for case let rowEntity as TableComponentRowEntity in tableComponentEntity.rows {
                let cellEntity = TableComponentCellEntity(context: ctx)
                cellEntity.value = cells[rowEntity.id]?[columnEntity.id] ?? ""

                cellEntity.row = rowEntity
                cellEntity.column = columnEntity

                rowEntity.addToCells(cellEntity)
                columnEntity.addToCells(cellEntity)
            }
        }
    }
}

extension TableComponentContents {
    init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(TableComponentContents.self, from: data)
        else { return nil }

        self.columns = decoded.columns
        self.rows = decoded.rows
        self.cells = decoded.cells
        self.sortBy = decoded.sortBy
    }

    var jsonString: String {
        guard let data = try? JSONEncoder().encode(self) else { return "" }
        let result = String(data: data, encoding: .utf8) ?? ""
        return result
    }
}
