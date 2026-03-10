import Foundation

enum TextEditorComponentAction: Equatable {
    case insert(range: Range<Int>, text: String)
    case replace(range: Range<Int>, from: String, to: String)

    enum CodingKeys: String, CodingKey {
        case type
        case range
        case text
        case from
        case to
    }

    enum ActionType: String, Codable {
        case insert
        case replace
    }
}
