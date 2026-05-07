import UIKit

final class DirectoryPathView: UIScrollView {
    private var pathContainerView: UIStackView = {
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
}

final class DirectoryPathLabel: UIButton {
    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = .black
        nameLabel.font = .systemFont(ofSize: 17)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        return nameLabel
    }()

    private let height: CGFloat = 40
    private let radius: CGFloat = 20

    override func layoutSubviews() {
        super.layoutSubviews()

        nameLabel.layer.sublayers?.removeAll()

        let size = CGRect(x: -10, y: 0, width: bounds.width, height: height)
        let innerShadowLayer = CAShapeLayer()

        innerShadowLayer.frame = size
        nameLabel.layer.insertSublayer(innerShadowLayer, at: 0)

        let path = UIBezierPath(roundedRect: size.insetBy(dx: -7, dy: -7), cornerRadius: radius)
        let cutout = UIBezierPath(roundedRect: size, cornerRadius: radius).reversing()
        path.append(cutout)

        innerShadowLayer.cornerRadius = radius
        innerShadowLayer.shadowPath = path.cgPath
        innerShadowLayer.masksToBounds = true
        innerShadowLayer.shadowColor = UIColor.black.cgColor
        innerShadowLayer.shadowOffset = .init(width: 5, height: 3)
        innerShadowLayer.shadowOpacity = 0.09
        innerShadowLayer.shadowRadius = 4
        innerShadowLayer.fillRule = .evenOdd
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
        backgroundColor = .appBaseColor
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .init(width: -2.5, height: 2.5)
        layer.shadowOpacity = 0.07
        layer.shadowRadius = 2
        layer.cornerRadius = radius
        layer.masksToBounds = false
        clipsToBounds = false
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
