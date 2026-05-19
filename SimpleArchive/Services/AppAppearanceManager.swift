import UIKit

protocol AppAppearanceManagerType: AnyObject {
    var appBaseColorBrightness: Double { get set }
    var appTintColorBrightness: Double { get set }
    var animaDuration: AppAnimationDuration { get set }

    var appBaseColor: UIColor { get }
    var appTintColor: UIColor { get }
    var appSecondaryTintColor: UIColor { get }
}

final class AppAppearanceManager: AppAppearanceManagerType {
    private init() {
        if let brightness: Double = uds.get(k: "appBaseColorBrightness") {
            self.appBaseColorBrightness = brightness
        } else {
            uds.store(k: "appBaseColorBrightness", v: Double(1.0))
            appBaseColorBrightness = 1.0
        }
        if let brightness: Double = uds.get(k: "appTintColorBrightness") {
            self.appTintColorBrightness = brightness
        } else {
            uds.store(k: "appTintColorBrightness", v: Double(0.0))
            appTintColorBrightness = 0.0
        }
        if let duration: AppAnimationDuration = uds.get(k: "animaDuration") {
            self.animaDuration = duration
        } else {
            uds.store(k: "animaDuration", v: AppAnimationDuration.normal)
            animaDuration = .normal
        }
    }

    private let uds = UserDefaultStack.shared
    static let shared: AppAppearanceManagerType = AppAppearanceManager()

    var appBaseColorBrightness: Double {
        didSet {
            uds.store(k: "appBaseColorBrightness", v: appBaseColorBrightness)
        }
    }
    var appTintColorBrightness: Double {
        didSet {
            uds.store(k: "appTintColorBrightness", v: appTintColorBrightness)
        }
    }
    var animaDuration: AppAnimationDuration {
        didSet {
            uds.store(k: "animaDuration", v: animaDuration)
        }
    }

    var appTintColor: UIColor { UIColor(named: "AppBaseForegroundColor")!.setBrightness(appTintColorBrightness) }
    var appBaseColor: UIColor { UIColor(named: "FixedFileItemBackgroundColor")!.setBrightness(appBaseColorBrightness) }
    var appSecondaryTintColor: UIColor { .gray.setBrightness(1.0 - appBaseColorBrightness) }
}

protocol BaseColorUpdatable: AnyObject {
    func applyColor(_ colorManager: any AppAppearanceManagerType)
}

enum FileItemColor: String, Codable, CaseIterable {
    case red = "RED"
    case green = "GREEN"
    case purple = "PURPLE"
    case blue = "BLUE"
    case orange = "ORANGE"
    case white = "WHITE"

    var color: (bg: UIColor?, title: UIColor?) {
        switch self {
            case .red: (UIColor(hex: "#FCE8EB"), .systemPink)
            case .green: (UIColor(hex: "#DAF5DE"), .systemGreen)
            case .purple: (UIColor(hex: "#E6DFF5"), .systemPurple)
            case .blue: (UIColor(hex: "#D7E9F5"), .systemBlue)
            case .orange: (UIColor(hex: "#FCEAB8"), .systemOrange)
            case .white: (UIColor(named: "FixedFileItemBackgroundColor"), UIColor(hex: "#000000"))
        }
    }
}
