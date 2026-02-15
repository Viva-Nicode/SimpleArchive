import Foundation

final class TextEditorComponentActionsJsonConverter: JsonStringCodecType {
    typealias CodableType = [TextEditorComponentAction]

    func encode(_ value: [TextEditorComponentAction]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]

        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    }

    func decode(_ type: [TextEditorComponentAction].Type, from text: String) throws -> [TextEditorComponentAction]? {
        guard !text.isEmpty, let data = text.data(using: .utf8)
        else { return [] }
        return try JSONDecoder().decode([TextEditorComponentAction].self, from: data)
    }
}

extension TextEditorComponentAction: Codable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
            case .insert(let range, let text):
                try container.encode(ActionType.insert, forKey: .type)
                try container.encode(range, forKey: .range)
                try container.encode(text, forKey: .text)

            case .replace(let range, let from, let to):
                try container.encode(ActionType.replace, forKey: .type)
                try container.encode(range, forKey: .range)
                try container.encode(from, forKey: .from)
                try container.encode(to, forKey: .to)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ActionType.self, forKey: .type)

        switch type {
            case .insert:
                let range = try container.decode(Range<Int>.self, forKey: .range)
                let text = try container.decode(String.self, forKey: .text)
                self = .insert(range: range, text: text)

            case .replace:
                let range = try container.decode(Range<Int>.self, forKey: .range)
                let from = try container.decode(String.self, forKey: .from)
                let to = try container.decode(String.self, forKey: .to)
                self = .replace(range: range, from: from, to: to)
        }
    }
}
