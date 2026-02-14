import Foundation

enum TableComponentAction: Codable {
    case appendRow(row: TableComponentRow)
    case removeRow(rowID: UUID)
    case appendColumn(column: TableComponentColumn)
    case editColumn(columns: [TableComponentColumn])
    case editCellValue(rowID: UUID, columnID: UUID, value: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case row
        case rowID
        case column
        case columns
        case columnID
        case value
    }

    private enum ActionType: String, Codable {
        case appendRow
        case removeRow
        case appendColumn
        case editColumn
        case editCellValue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
            case .appendRow(let row):
                try container.encode(ActionType.appendRow, forKey: .type)
                try container.encode(row, forKey: .row)

            case .removeRow(let rowID):
                try container.encode(ActionType.removeRow, forKey: .type)
                try container.encode(rowID, forKey: .rowID)

            case .appendColumn(let column):
                try container.encode(ActionType.appendColumn, forKey: .type)
                try container.encode(column, forKey: .column)

            case .editColumn(let columns):
                try container.encode(ActionType.editColumn, forKey: .type)
                try container.encode(columns, forKey: .columns)

            case .editCellValue(let rowID, let columnID, let value):
                try container.encode(ActionType.editCellValue, forKey: .type)
                try container.encode(rowID, forKey: .rowID)
                try container.encode(columnID, forKey: .columnID)
                try container.encode(value, forKey: .value)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ActionType.self, forKey: .type)

        switch type {
            case .appendRow:
                let row = try container.decode(TableComponentRow.self, forKey: .row)
                self = .appendRow(row: row)

            case .removeRow:
                let rowID = try container.decode(UUID.self, forKey: .rowID)
                self = .removeRow(rowID: rowID)

            case .appendColumn:
                let column = try container.decode(TableComponentColumn.self, forKey: .column)
                self = .appendColumn(column: column)

            case .editColumn:
                let columns = try container.decode([TableComponentColumn].self, forKey: .columns)
                self = .editColumn(columns: columns)

            case .editCellValue:
                let rowID = try container.decode(UUID.self, forKey: .rowID)
                let columnID = try container.decode(UUID.self, forKey: .columnID)
                let value = try container.decode(String.self, forKey: .value)
                self = .editCellValue(rowID: rowID, columnID: columnID, value: value)
        }
    }
}

extension [TableComponentAction] {
    var jsonString: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        do {
            let data = try encoder.encode(self)
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            assertionFailure("JSON encoding failed: \(error)")
            return ""
        }
    }
}
