import Foundation

protocol UserDefaultStackInterface {
    func store<ValueType: Codable>(k: String, v: ValueType)
    func get<ValueType: Codable>(k: String) -> ValueType?
    func remove(k: String)
    func isExistValue(k: String) -> Bool
}

final class UserDefaultStack: UserDefaultStackInterface {
    private var stack: UserDefaults = UserDefaults(suiteName: "org.azurelight.SimpleArchive.shared")!
    static var shared: UserDefaultStackInterface = UserDefaultStack()

    private init() {}

    func store<ValueType: Codable>(k: String, v: ValueType) {
        if let data = try? JSONEncoder().encode(v) {
            let jsonString = String(data: data, encoding: .utf8)
            stack.set(jsonString, forKey: k)
        }
    }

    func get<ValueType: Codable>(k: String) -> ValueType? {
        if let jsonString = stack.string(forKey: k) {
            guard let data = jsonString.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(ValueType.self, from: data)
        } else {
            return nil
        }
    }

    func isExistValue(k: String) -> Bool { stack.string(forKey: k) != nil }

    func remove(k: String) { stack.removeObject(forKey: k) }
}

extension CGRect {
    init(CCGRect: CodableCGRect) {
        self.init(
            x: CCGRect.x,
            y: CCGRect.y,
            width: CCGRect.w,
            height: CCGRect.h
        )
    }
}

struct CodableCGRect: Codable, Equatable {
    var x: Double
    var y: Double
    var z: Double
    var w: Double
    var h: Double

    init(x: Double, y: Double, z: Double, w: Double, h: Double) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
        self.h = h
    }
}

enum FrameState: Codable, Equatable {
    case origin
    case manual(CodableCGRect)

    var z: Double {
        switch self {
            case .origin: .zero
            case .manual(let rect): rect.z
        }
    }
}

struct ItemRenderInfo: Codable {
    var id: UUID
    var frame: FrameState
}
