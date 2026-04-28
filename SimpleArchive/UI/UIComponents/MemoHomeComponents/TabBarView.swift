import UIKit

final class TabBarView: UIView {
    private(set) var homeButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "house")
        config.titleAlignment = .center
        config.title = "Home"
        config.imagePlacement = .top
        config.imagePadding = 4
        config.baseForegroundColor = .black
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18)
        var titleAttr = AttributedString("Home")
        titleAttr.font = .systemFont(ofSize: 11)
        config.attributedTitle = titleAttr
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) var hideButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "eye.slash")
        config.title = "Hide"
        config.imagePlacement = .top
        config.imagePadding = 4
        config.baseForegroundColor = .black
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18)
        var titleAttr = AttributedString("Hide")
        titleAttr.font = .systemFont(ofSize: 11)
        config.attributedTitle = titleAttr
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private(set) var settingButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "gearshape")
        config.title = "Setting"
        config.imagePlacement = .top
        config.imagePadding = 4
        config.baseForegroundColor = .black
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18)
        var titleAttr = AttributedString("Setting")
        titleAttr.font = .systemFont(ofSize: 11)
        config.attributedTitle = titleAttr
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
            homeButton.widthAnchor.constraint(equalToConstant: UIView.screenWidth * 0.33),
            homeButton.heightAnchor.constraint(equalToConstant: 60),
            homeButton.leadingAnchor.constraint(equalTo: leadingAnchor),
			homeButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -11.5),

            hideButton.widthAnchor.constraint(equalToConstant: UIView.screenWidth * 0.33),
            hideButton.heightAnchor.constraint(equalToConstant: 60),
            hideButton.leadingAnchor.constraint(equalTo: homeButton.trailingAnchor),
			hideButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -11.5),

            settingButton.widthAnchor.constraint(equalToConstant: UIView.screenWidth * 0.33),
            settingButton.heightAnchor.constraint(equalToConstant: 60),
            settingButton.leadingAnchor.constraint(equalTo: hideButton.trailingAnchor),
			settingButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -11.5),
        ])
    }
}
