import UIKit

final class TabBarView: UIView {
    private(set) var homeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "house")
        config.titleAlignment = .center
        config.imagePlacement = .leading
        config.imagePadding = 4
        config.cornerStyle = .capsule
        config.baseForegroundColor = .systemBlue
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18)
        var titleAttr = AttributedString("Home")
        titleAttr.font = .systemFont(ofSize: 13)
        config.attributedTitle = titleAttr
        let button = UIButton(configuration: config)
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) var hideButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "eye.slash")
        config.titleAlignment = .center
        config.imagePlacement = .leading
        config.imagePadding = 4
        config.cornerStyle = .capsule
        config.baseForegroundColor = .black
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18)
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) var settingButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "gearshape")
        config.titleAlignment = .center
        config.imagePlacement = .leading
        config.imagePadding = 4
        config.cornerStyle = .capsule
        config.baseForegroundColor = .black
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18)
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func changeHome() {
        homeButton.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        homeButton.configuration?.baseForegroundColor = .systemBlue
        var titleAttr = AttributedString("Home")
        titleAttr.font = .systemFont(ofSize: 13)
        homeButton.configuration?.attributedTitle = titleAttr

        hideButton.backgroundColor = .clear
        hideButton.configuration?.baseForegroundColor = .black
        hideButton.configuration?.attributedTitle = nil

        settingButton.backgroundColor = .clear
        settingButton.configuration?.baseForegroundColor = .black
        settingButton.configuration?.attributedTitle = nil
    }
	
    func changeHide() {
        homeButton.backgroundColor = .clear
        homeButton.configuration?.baseForegroundColor = .black
        homeButton.configuration?.attributedTitle = nil

        hideButton.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        hideButton.configuration?.baseForegroundColor = .systemOrange
        var titleAttr = AttributedString("Hide")
        titleAttr.font = .systemFont(ofSize: 13)
        hideButton.configuration?.attributedTitle = titleAttr

        settingButton.backgroundColor = .clear
        settingButton.configuration?.baseForegroundColor = .black
        settingButton.configuration?.attributedTitle = nil
    }

    func changeSetting() {
        homeButton.backgroundColor = .clear
        homeButton.configuration?.baseForegroundColor = .black
        homeButton.configuration?.attributedTitle = nil

        hideButton.backgroundColor = .clear
        hideButton.configuration?.baseForegroundColor = .black
        hideButton.configuration?.attributedTitle = nil

        settingButton.backgroundColor = .systemPurple.withAlphaComponent(0.1)
        settingButton.configuration?.baseForegroundColor = .systemPurple
        var titleAttr = AttributedString("Setting")
        titleAttr.font = .systemFont(ofSize: 13)
        settingButton.configuration?.attributedTitle = titleAttr
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
        NSLayoutConstraint.activate([
            homeButton.widthAnchor.constraint(equalToConstant: 100),
            homeButton.heightAnchor.constraint(equalToConstant: 50),
            homeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: (UIView.screenWidth - 300) / 2),
            homeButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),

            hideButton.widthAnchor.constraint(equalToConstant: 100),
            hideButton.heightAnchor.constraint(equalToConstant: 50),
            hideButton.leadingAnchor.constraint(equalTo: homeButton.trailingAnchor),
            hideButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),

            settingButton.widthAnchor.constraint(equalToConstant: 100),
            settingButton.heightAnchor.constraint(equalToConstant: 50),
            settingButton.leadingAnchor.constraint(equalTo: hideButton.trailingAnchor),
            settingButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -7),
        ])
    }
}
