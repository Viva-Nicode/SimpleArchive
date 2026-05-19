import UIKit

final class TabBarView: UIView, BaseColorUpdatable {
    private(set) lazy var homeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "home")?
            .resized(to: CGSize(width: 35, height: 35))
            .withRenderingMode(.alwaysTemplate)
        config.titleAlignment = .center
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.cornerStyle = .capsule
        config.baseForegroundColor = .systemBlue
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 25)
        var titleAttr = AttributedString("Home")
        titleAttr.font = tabTitleFont
        config.attributedTitle = titleAttr
        let button = UIButton(configuration: config)
        button.isUserInteractionEnabled = false
        button.layer.cornerRadius = 25
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) lazy var hideButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "lock")?
            .resized(to: CGSize(width: 35, height: 35))
            .withRenderingMode(.alwaysTemplate)
        config.titleAlignment = .center
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.cornerStyle = .capsule
        config.baseForegroundColor = inactiveTabColor
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 25)
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) lazy var settingButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(named: "setting")?
            .resized(to: CGSize(width: 35, height: 35))
            .withRenderingMode(.alwaysTemplate)
        config.titleAlignment = .center
        config.imagePlacement = .leading
        config.imagePadding = 4
        config.cornerStyle = .capsule
        config.baseForegroundColor = inactiveTabColor
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 25)
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let tabTitleFont = UIFont.systemFont(ofSize: 16)
    private let inactiveTabColor = UIColor.black.withAlphaComponent(0.35)
    private var currentTap: CurrentTap = .mainDirectory
    private var duration: Double { AppAppearanceManager.shared.animaDuration == .normal ? 0.4 : 0.2 }

    private var homeButtonWidthConstraint: NSLayoutConstraint?
    private var hideButtonWidthConstraint: NSLayoutConstraint?
    private var settingButtonWidthConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurBackgroundView = UIVisualEffectView(effect: blurEffect)

        blurBackgroundView.frame = bounds
        blurBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        addSubview(blurBackgroundView)
        addSubview(homeButton)
        addSubview(hideButton)
        addSubview(settingButton)

        sendSubviewToBack(blurBackgroundView)
    }

    private func setupConstraints() {
        homeButtonWidthConstraint = homeButton.widthAnchor.constraint(equalToConstant: 120)
        hideButtonWidthConstraint = hideButton.widthAnchor.constraint(equalToConstant: 50)
        settingButtonWidthConstraint = settingButton.widthAnchor.constraint(equalToConstant: 50)

        NSLayoutConstraint.activate([
            homeButtonWidthConstraint!,
            homeButton.heightAnchor.constraint(equalToConstant: 50),
            homeButton.centerXAnchor.constraint(
                equalTo: leadingAnchor, constant: (UIView.screenWidth / 6) + 30),
            homeButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),

            hideButtonWidthConstraint!,
            hideButton.heightAnchor.constraint(equalToConstant: 50),
            hideButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            hideButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),

            settingButtonWidthConstraint!,
            settingButton.heightAnchor.constraint(equalToConstant: 50),
            settingButton.centerXAnchor.constraint(
                equalTo: leadingAnchor, constant: (UIView.screenWidth * 5 / 6) - 30),
            settingButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),
        ])
    }

    func changeHome() {
        homeButtonWidthConstraint?.constant = 120

        UIView.transition(with: homeButton, duration: duration, options: .transitionFlipFromTop) { [self] in
            homeButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            homeButton.configuration?.baseForegroundColor = .systemBlue
                .setBrightness(1.8 - AppAppearanceManager.shared.appBaseColorBrightness)
            var titleAttr = AttributedString("Home")
            titleAttr.font = tabTitleFont
            homeButton.configuration?.attributedTitle = titleAttr
            homeButton.layoutIfNeeded()
        }

        switch currentTap {
            case .privateDirectory:
                hideButtonWidthConstraint?.constant = 50
                UIView.transition(
                    with: hideButton, duration: duration, options: .transitionFlipFromBottom
                ) { [self] in
                    hideButton.backgroundColor = .clear
                    hideButton.configuration?.baseForegroundColor = inactiveTabColor
                    hideButton.configuration?.attributedTitle = nil
                    hideButton.layoutIfNeeded()
                }

            case .setting:
                settingButtonWidthConstraint?.constant = 50
                UIView.transition(
                    with: settingButton, duration: duration, options: .transitionFlipFromBottom
                ) {
                    [self] in
                    settingButton.backgroundColor = .clear
                    settingButton.configuration?.baseForegroundColor = inactiveTabColor
                    settingButton.configuration?.attributedTitle = nil
                    settingButton.layoutIfNeeded()
                }

            default: break
        }
        currentTap = .mainDirectory
    }

    func changeHide() {
        hideButtonWidthConstraint?.constant = 120

        UIView.transition(with: hideButton, duration: duration, options: .transitionFlipFromTop) { [self] in
            hideButton.backgroundColor = .systemOrange.withAlphaComponent(0.1)
            hideButton.configuration?.baseForegroundColor = .systemOrange
                .setBrightness(1.8 - AppAppearanceManager.shared.appBaseColorBrightness)
            var titleAttr = AttributedString("Private")
            titleAttr.font = tabTitleFont
            hideButton.configuration?.attributedTitle = titleAttr
            hideButton.layoutIfNeeded()
        }

        switch currentTap {
            case .mainDirectory:
                homeButtonWidthConstraint?.constant = 50
                UIView.transition(
                    with: homeButton, duration: duration, options: .transitionFlipFromBottom
                ) { [self] in
                    homeButton.backgroundColor = .clear
                    homeButton.configuration?.baseForegroundColor = inactiveTabColor
                    homeButton.configuration?.attributedTitle = nil
                    homeButton.layoutIfNeeded()
                }

            case .setting:
                settingButtonWidthConstraint?.constant = 50
                UIView.transition(
                    with: settingButton, duration: duration, options: .transitionFlipFromBottom
                ) {
                    [self] in
                    settingButton.backgroundColor = .clear
                    settingButton.configuration?.baseForegroundColor = inactiveTabColor
                    settingButton.configuration?.attributedTitle = nil
                    settingButton.layoutIfNeeded()
                }

            default: break
        }
        currentTap = .privateDirectory
    }

    func changeSetting() {
        settingButtonWidthConstraint?.constant = 120

        UIView.transition(with: settingButton, duration: duration, options: .transitionFlipFromTop) { [self] in
            settingButton.backgroundColor = .systemPurple.withAlphaComponent(0.1)
            settingButton.configuration?.baseForegroundColor = .systemPurple
                .setBrightness(1.8 - AppAppearanceManager.shared.appBaseColorBrightness)
            var titleAttr = AttributedString("Setting")
            titleAttr.font = tabTitleFont
            settingButton.configuration?.attributedTitle = titleAttr
            settingButton.layoutIfNeeded()
        }

        switch currentTap {
            case .mainDirectory:
                homeButtonWidthConstraint?.constant = 50
                UIView.transition(
                    with: homeButton, duration: duration, options: .transitionFlipFromBottom
                ) { [self] in
                    homeButton.backgroundColor = .clear
                    homeButton.configuration?.baseForegroundColor = inactiveTabColor
                    homeButton.configuration?.attributedTitle = nil
                    homeButton.layoutIfNeeded()
                }
            case .privateDirectory:
                hideButtonWidthConstraint?.constant = 50
                UIView.transition(
                    with: hideButton, duration: duration, options: .transitionFlipFromBottom
                ) { [self] in
                    hideButton.backgroundColor = .clear
                    hideButton.configuration?.baseForegroundColor = inactiveTabColor
                    hideButton.configuration?.attributedTitle = nil
                    hideButton.layoutIfNeeded()
                }

            default: break
        }
        currentTap = .setting
    }

    func applyColor(_ colorManager: any AppAppearanceManagerType = AppAppearanceManager.shared) {
        switch currentTap {
            case .mainDirectory:
                homeButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
                homeButton.configuration?.baseForegroundColor = .systemBlue
                    .setBrightness(1.8 - colorManager.appBaseColorBrightness)
                var titleAttr = AttributedString("Home")
                titleAttr.font = tabTitleFont
                homeButton.configuration?.attributedTitle = titleAttr
                homeButton.layoutIfNeeded()

            case .privateDirectory:
                hideButton.backgroundColor = .systemOrange.withAlphaComponent(0.1)
                hideButton.configuration?.baseForegroundColor = .systemOrange
                    .setBrightness(1.8 - colorManager.appBaseColorBrightness)
                var titleAttr = AttributedString("Private")
                titleAttr.font = tabTitleFont
                hideButton.configuration?.attributedTitle = titleAttr
                hideButton.layoutIfNeeded()

            case .setting:
                settingButton.backgroundColor = .systemPurple.withAlphaComponent(0.1)
                settingButton.configuration?.baseForegroundColor = .systemPurple
                    .setBrightness(1.8 - colorManager.appBaseColorBrightness)
                var titleAttr = AttributedString("Setting")
                titleAttr.font = tabTitleFont
                settingButton.configuration?.attributedTitle = titleAttr
                settingButton.layoutIfNeeded()
        }
    }
}
