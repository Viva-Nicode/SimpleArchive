protocol JsonStringCodecType {
    associatedtype CodableType: Codable

    func encode(_ value: CodableType) throws -> String
    func decode(_ type: CodableType.Type, from text: String) throws -> CodableType?
}

protocol JsonStringCodecWrapperType {
    var codableType: Any.Type { get }

    func encodeAny(_ value: Any) throws -> String?
    func decodeAny(from text: String) throws -> Any?
}

struct JsonStringCodecWrapper<Codec: JsonStringCodecType>: JsonStringCodecWrapperType {
    private let codec: Codec

    init(_ codec: Codec) {
        self.codec = codec
    }

    var codableType: Any.Type { Codec.CodableType.self }

    func encodeAny(_ value: Any) throws -> String? {
        guard let typed = value as? Codec.CodableType else { return nil }
        return try codec.encode(typed)
    }

    func decodeAny(from text: String) throws -> Any? {
        try codec.decode(Codec.CodableType.self, from: text)
    }
}
