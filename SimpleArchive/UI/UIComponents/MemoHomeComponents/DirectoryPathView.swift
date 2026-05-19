import UIKit

final class DirectoryPathView: UIScrollView, BaseColorUpdatable {
    private(set) var pathContainerView: UIStackView = {
        let pathContainerView = UIStackView()
        pathContainerView.axis = .horizontal
        pathContainerView.alignment = .center
        pathContainerView.spacing = 12
        pathContainerView.translatesAutoresizingMaskIntoConstraints = false
        return pathContainerView
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        alwaysBounceHorizontal = true
        showsHorizontalScrollIndicator = false
        addSubview(pathContainerView)
    }

    func appendPath(name: String, moveToThisDirectory: @escaping () -> Void) {
        let pathLabel = DirectoryPathLabel(name: name)
        pathLabel.addAction(
            UIAction { _ in
                moveToThisDirectory()
                if let idx = self.pathContainerView.arrangedSubviews.firstIndex(of: pathLabel) {
                    for i in stride(from: self.pathContainerView.arrangedSubviews.count - 1, through: idx + 1, by: -1) {
                        let view = self.pathContainerView.arrangedSubviews[i]
                        self.pathContainerView.removeArrangedSubview(view)
                        view.removeFromSuperview()
                    }
                }
            }, for: .touchUpInside)

        pathContainerView.addArrangedSubview(pathLabel)
        DispatchQueue.main.async {
            self.scrollToTrailing(animated: true)
            self.applyColor()
        }
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            pathContainerView.heightAnchor.constraint(equalToConstant: 50),
            pathContainerView.centerYAnchor.constraint(equalTo: centerYAnchor),
            pathContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            pathContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
    }

    func clear() {
        pathContainerView.arrangedSubviews.forEach {
            pathContainerView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

	func applyColor(_ colorManager: any AppAppearanceManagerType = AppAppearanceManager.shared) {
		pathContainerView.arrangedSubviews.compactMap { $0 as? DirectoryPathLabel }
			.forEach {
				$0.nameLabel.textColor = colorManager.appTintColor
				$0.innerWhiteShadowLayer.shadowOpacity = Float(colorManager.appBaseColorBrightness - 0.25)
			}
	}
}

final class DirectoryPathLabel: UIButton {
    private(set) lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = .systemFont(ofSize: 17)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        return nameLabel
    }()
    private let innerBlackShadowLayer = CAShapeLayer()
    private(set) var innerWhiteShadowLayer = CAShapeLayer()

    private let height: CGFloat = 40
    private let radius: CGFloat = 20

    override func layoutSubviews() {
        super.layoutSubviews()
        innerBlackShadowLayer.removeFromSuperlayer()
        innerWhiteShadowLayer.removeFromSuperlayer()

        let size = CGRect(x: -10, y: 0, width: bounds.width, height: height)

        innerWhiteShadowLayer.frame = size
        innerBlackShadowLayer.frame = size
        nameLabel.layer.addSublayer(innerBlackShadowLayer)
        nameLabel.layer.addSublayer(innerWhiteShadowLayer)

        let path = UIBezierPath(roundedRect: bounds.insetBy(dx: -7, dy: -7), cornerRadius: radius)
        let cutout = UIBezierPath(roundedRect: bounds, cornerRadius: radius).reversing()
        path.append(cutout)

        innerBlackShadowLayer.cornerRadius = radius
        innerBlackShadowLayer.shadowPath = path.cgPath
        innerBlackShadowLayer.masksToBounds = true
        innerBlackShadowLayer.shadowColor = UIColor.black.cgColor
        innerBlackShadowLayer.shadowOffset = .init(width: -4, height: 4)
        innerBlackShadowLayer.shadowOpacity = 0.09
        innerBlackShadowLayer.shadowRadius = 4
        innerBlackShadowLayer.fillRule = .evenOdd

        innerWhiteShadowLayer.cornerRadius = radius
        innerWhiteShadowLayer.shadowPath = path.cgPath
        innerWhiteShadowLayer.masksToBounds = true
        innerWhiteShadowLayer.shadowColor = UIColor.white.cgColor
        innerWhiteShadowLayer.shadowOffset = .init(width: 4, height: -4)
		innerWhiteShadowLayer.shadowOpacity = Float(AppAppearanceManager.shared.appBaseColorBrightness - 0.25)
        innerWhiteShadowLayer.shadowRadius = 5
        innerWhiteShadowLayer.fillRule = .evenOdd
    }

    init(name: String) {
        super.init(frame: .zero)
        nameLabel.text = name
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setDirectoryName(name: String) {
        nameLabel.text = name
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(nameLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: height),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 70),
            widthAnchor.constraint(lessThanOrEqualToConstant: 130),

            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameLabel.heightAnchor.constraint(equalToConstant: height),
        ])
    }
}
