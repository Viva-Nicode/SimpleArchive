enum AppAnimationDuration: String, Codable {
    case normal = "normal"
    case fast = "fast"
}

protocol UserContentsConfigurationManagerType: AnyObject {
    var isEnableTextMemoSummarization: Bool { get set }
}

final class UserContentsConfigurationManager: UserContentsConfigurationManagerType {
    private let uds = UserDefaultStack.shared

    var isEnableTextMemoSummarization: Bool {
        didSet {
            uds.store(k: "isEnableTextMemoSummarization", v: isEnableTextMemoSummarization)
        }
    }

    init() {
        if let isEnableTextMemoSummarization: Bool = uds.get(k: "isEnableTextMemoSummarization") {
            self.isEnableTextMemoSummarization = isEnableTextMemoSummarization
        } else {
            uds.store(k: "isEnableTextMemoSummarization", v: false)
            isEnableTextMemoSummarization = false
        }
    }
}
