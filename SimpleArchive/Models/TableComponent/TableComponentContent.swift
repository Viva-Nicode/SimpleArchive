import Foundation

final class TableComponentContent: Codable {
    enum TableComponentRowSortCriterias: Codable {
        case modify
        case name(columnID: UUID)
        case create
    }

    private(set) var columns: [TableComponentColumn]
    private(set) var rows: [TableComponentRow]
    private(set) var sortby: TableComponentRowSortCriterias

    init(
        columns: [TableComponentColumn] = [.init(columnTitle: "column")],
        rows: [TableComponentRow] = [],
        sortby: TableComponentRowSortCriterias = .create
    ) {
        self.columns = columns
        self.rows = [TableComponentRow(columns: columns)]
        self.sortby = sortby
    }

    init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let tableComponentContent = try decoder.decode(TableComponentContent.self, from: data)
            self.columns = tableComponentContent.columns
            self.rows = tableComponentContent.rows
            self.sortby = tableComponentContent.sortby
        } catch {
            return nil
        }
    }

    func appendNewRow() -> TableComponentRow {
        let newRow = TableComponentRow(columns: self.columns)
        self.rows.append(newRow)
        return newRow
    }

    func removeRow(_ rowID: UUID) -> Int {
        let idx = rows.firstIndex(where: { $0.id == rowID })!
        rows.remove(at: idx)
        return idx
    }

    func appendNewColumn(columnTitle: String) -> (TableComponentColumn, [TableComponentCell]) {
        let newColumn = TableComponentColumn(columnTitle: columnTitle)
        self.columns.append(newColumn)
        return (newColumn, (0..<rows.count).map { rows[$0].appendCell() })
    }

    func editCellValeu(_ cellID: UUID, _ newCellValue: String) -> (Int, Int) {
        let rowIndex = self.rows.firstIndex(where: { $0.cells.contains(where: { $0.id == cellID }) })!
        let cellIndex = rows[rowIndex].cells.firstIndex(where: { $0.id == cellID })!
        rows[rowIndex].cells[cellIndex].setValue(value: newCellValue)
        return (rowIndex, cellIndex)
    }

    func setColumn(_ changedColumns: [TableComponentColumn]) {

        for rowindex in 0..<rows.count {
            var newCells: [TableComponentCell] = []
            for changedcolumn in changedColumns {
                if let idx = columns.firstIndex(where: { $0.id == changedcolumn.id }) {
                    newCells.append(rows[rowindex].cells[idx])
                }
            }
            rows[rowindex].cells = newCells
        }

        columns = changedColumns

        columns.forEach { print($0.columnTitle) }
        rows.forEach { print($0.cells.map { $0.value }) }
    }

    var jsonString: String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted

            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                return ""
            }
        } catch {
            return ""
        }
    }

    func getData() -> [[String]] {
        return []
    }
}
