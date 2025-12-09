import Foundation

struct TableComponentContents: Codable {

    private(set) var columns: [TableComponentColumn]
    private(set) var rows: [TableComponentRow]
    private var cells: [UUID: [UUID: String]]
    var sortBy: SortCriteria

    enum SortCriteria: Codable {
        case created, modified, manual
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
    init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(TableComponentContents.self, from: data)
        else {
            return nil
        }
        self.init()
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
