import Foundation

final class TableComponentActionsJsonConverter: JsonStringCodecType {
    typealias CodableType = [TableComponentAction]

    func encode(_ value: [TableComponentAction]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    }

    func decode(_ type: [TableComponentAction].Type, from text: String) throws -> [TableComponentAction]? {
        guard !text.isEmpty, let data = text.data(using: .utf8)
        else { return [] }
        return try JSONDecoder().decode([TableComponentAction].self, from: data)
    }
}

extension TableComponentAction: Codable {
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
