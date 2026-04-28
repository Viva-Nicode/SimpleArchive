import UIKit

final class MemoHomeDirectoryNameLabel: UIStackView {

    private let homePathLabelBackgroundColor = UIColor(hex: "#1470F0")
    private let homePathLabelTextColor = UIColor(hex: "#DEEFFE")
    private let middlePathLabelBackgroundColor = UIColor(hex: "#D6802E")
    private let middlePathLabelTextColor = UIColor(hex: "#FAF3D5")
    private let currentPathLabelBackgroundColor = UIColor(hex: "#44BA5E")
    private let currentPathLabelTextColor = UIColor(hex: "#DBF8DF")
    private var isHomePathLabel = false
    private let chevronImageView: UIImageView = {
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.forward"))
        chevronImageView.tintColor = .systemGray2
        chevronImageView.contentMode = .center
        chevronImageView.frame = CGRect(x: 0, y: 0, width: 15, height: 15)
        return chevronImageView
    }()
    private let nameLabel: UILabel = {
		let label = BasePaddingLabel(padding: .init(top: 5, left: 13, bottom: 5, right: 13))
        label.clipsToBounds = true
		label.layer.cornerRadius = 16
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.isUserInteractionEnabled = true
        return label
    }()

    init(name: String) {
        super.init(frame: .zero)
        nameLabel.text = name
        axis = .horizontal
        alignment = .center
        spacing = 5
        addArrangedSubview(chevronImageView)
        addArrangedSubview(nameLabel)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(lessThanOrEqualToConstant: 180).isActive = true
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setmiddlePathLabel() {
        guard !isHomePathLabel else { return }
        nameLabel.backgroundColor = middlePathLabelBackgroundColor
        nameLabel.textColor = middlePathLabelTextColor
    }

    func setCurrentPathLabel() {
        guard !isHomePathLabel else { return }
        nameLabel.backgroundColor = currentPathLabelBackgroundColor
        nameLabel.textColor = currentPathLabelTextColor
    }

    func setHomePathLabel() {
        nameLabel.backgroundColor = homePathLabelBackgroundColor
        nameLabel.textColor = homePathLabelTextColor
        removeArrangedSubview(chevronImageView)
        chevronImageView.removeFromSuperview()
        isHomePathLabel = true
    }
}
