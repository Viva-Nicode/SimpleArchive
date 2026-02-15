import Foundation

final class TableComponentContentsJsonConverter: JsonStringCodecType {
    typealias CodableType = TableComponentContents

    func encode(_ value: TableComponentContents) throws -> String {
        guard let encoded = try? JSONEncoder().encode(value),
            let jsonObject = try? JSONSerialization.jsonObject(with: encoded),
            let sortedData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys])
        else { return "" }

        return String(data: sortedData, encoding: .utf8) ?? ""
    }

    func decode(_ type: TableComponentContents.Type, from text: String) throws -> TableComponentContents? {
        var contents = TableComponentContents()
        guard let data = text.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(TableComponentContents.self, from: data)
        else { return nil }

        contents.columns = decoded.columns
        contents.rows = decoded.rows
        contents.cells = decoded.cells
        contents.sortBy = decoded.sortBy

        return contents
    }
}
