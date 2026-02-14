import Foundation

// MARK: - ⚠️ json관련 코드가 도메인 레이어에 있다 분리하라.
enum TextEditorComponentAction: Codable, Equatable {
    case insert(range: Range<Int>, text: String)
    case replace(range: Range<Int>, from: String, to: String)

    private enum CodingKeys: String, CodingKey {
        case type
        case range
        case text
        case from
        case to
    }

    private enum ActionType: String, Codable {
        case insert
        case replace
    }

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

extension [TextEditorComponentAction] {
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
