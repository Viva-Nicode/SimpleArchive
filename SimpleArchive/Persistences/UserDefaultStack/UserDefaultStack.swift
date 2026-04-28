import Foundation

protocol UserDefaultStackInterface {
    func store<ValueType: Codable>(k: String, v: ValueType) throws
    func store<T: Codable>(keyTypes: UserDefaultStackKeys, v: T) throws
    func get<T: Codable>(keyTypes: UserDefaultStackKeys) -> T?
    func get<ValueType: Codable>(k: String) -> ValueType?
}

enum UserDefaultStackKeys: String {
    case FileItemManualOrder = "FileItemManualOrder"
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

final class UserDefaultStack: UserDefaultStackInterface {
    private var stack: UserDefaults = UserDefaults(suiteName: "org.azurelight.SimpleArchive.shared")!
    static var shared: UserDefaultStackInterface = UserDefaultStack()

    private init() {
        if stack.object(forKey: UserDefaultStackKeys.FileItemManualOrder.rawValue) == nil {
            let emptyManualSortingInfo = DirectoryContentsRenderInfo()
            let data = try! JSONEncoder().encode(emptyManualSortingInfo)
            let jsonString = String(data: data, encoding: .utf8)
            stack.set(jsonString, forKey: UserDefaultStackKeys.FileItemManualOrder.rawValue)
        }
    }

    func get<T: Codable>(keyTypes: UserDefaultStackKeys) -> T? {
        if let jsonString = stack.string(forKey: keyTypes.rawValue) {
            guard let data = jsonString.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(T.self, from: data)
        } else {
            return nil
        }
    }

    func store<ValueType: Codable>(k: String, v: ValueType) throws {
        let data = try JSONEncoder().encode(v)
        let jsonString = String(data: data, encoding: .utf8)
        stack.set(jsonString, forKey: k)
    }

    func store<T: Codable>(keyTypes: UserDefaultStackKeys, v: T) throws {
        let data = try JSONEncoder().encode(v)
        let jsonString = String(data: data, encoding: .utf8)
        stack.set(jsonString, forKey: keyTypes.rawValue)
    }

    func get<ValueType: Codable>(k: String) -> ValueType? {
        if let jsonString = stack.string(forKey: k) {
            guard let data = jsonString.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(ValueType.self, from: data)
        } else {
            return nil
        }
    }
}
