import CoreData
import Foundation

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

struct TableComponentContents: Codable {

    var columns: [TableComponentColumn]
    var rows: [TableComponentRow]
    var cells: [UUID: [UUID: String]]
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
