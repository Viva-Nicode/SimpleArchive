import Foundation

enum TableComponentAction: Equatable {
    case appendRow(row: TableComponentRow)
    case removeRow(rowID: UUID)
    case appendColumn(column: TableComponentColumn)
    case editColumn(columns: [TableComponentColumn])
    case editCellValue(rowID: UUID, columnID: UUID, value: String)

    enum CodingKeys: String, CodingKey {
        case type
        case row
        case rowID
        case column
        case columns
        case columnID
        case value
    }

    enum ActionType: String, Codable {
        case appendRow
        case removeRow
        case appendColumn
        case editColumn
        case editCellValue
    }
}
