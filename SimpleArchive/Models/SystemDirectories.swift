import Foundation

enum SystemDirectories: String, CaseIterable {
    case mainDirectory = "Home"
    case fixedFileDirectory = "FixedFile"
    case dormantBoxDirectory = "DormantBox"

    public var DirectoryName: String {
        switch self {
            case .mainDirectory:
                "Home"
            case .fixedFileDirectory:
                "FixedFile"
            case .dormantBoxDirectory:
                "DormantBox"
        }
    }

    public func setId(_ newValue: UUID) {
        if let data = try? JSONEncoder().encode(newValue) {
            UserDefaults.standard.set(data, forKey: self.rawValue)
        }
    }

    public func getId() -> UUID? {
        if let data = UserDefaults.standard.data(forKey: self.rawValue) {
            let userDefaultValue = try? JSONDecoder().decode(UUID.self, from: data)
            return userDefaultValue
        } else {
            return nil
        }
    }

    public func removeId() {
        UserDefaults.standard.removeObject(forKey: self.rawValue)
    }
}
