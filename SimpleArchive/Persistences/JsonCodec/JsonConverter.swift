import Foundation

final class JsonConverter {
    static let shared = JsonConverter()

    private let codecsByType: [ObjectIdentifier: JsonStringCodecWrapperType]

    private init() {
        let registered: [JsonStringCodecWrapperType] = [
            JsonStringCodecWrapper(TableComponentContentsJsonConverter()),
            JsonStringCodecWrapper(TextEditorComponentActionsJsonConverter()),
            JsonStringCodecWrapper(TableComponentActionsJsonConverter()),
        ]

        var map: [ObjectIdentifier: JsonStringCodecWrapperType] = [:]
        for codec in registered {
            map[ObjectIdentifier(codec.codableType)] = codec
        }
        self.codecsByType = map
    }

    func encode<T: Codable>(object: T) -> String {
        guard let codec = codecsByType[ObjectIdentifier(type(of: object))] else { return "" }
        do { return try codec.encodeAny(object) ?? "" } catch { return "" }
    }

    func decode<T: Codable>(_ type: T.Type, jsonString: String) -> T? {
        guard let codec = codecsByType[ObjectIdentifier(type)] else { return nil }
        do { return try codec.decodeAny(from: jsonString) as? T } catch { return nil }
    }
}
