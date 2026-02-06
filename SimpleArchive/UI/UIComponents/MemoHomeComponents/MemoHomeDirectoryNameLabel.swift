import UIKit

final class MemoHomeDirectoryNameLabel: UIStackView {

    private let homePathLabelBackgroundColor = UIColor(hex: "#DEEFFE")
    private let homePathLabelTextColor = UIColor(hex: "#1470F0")
    private let middlePathLabelBackgroundColor = UIColor(hex: "#FAF3D5")
    private let middlePathLabelTextColor = UIColor(hex: "#D6802E")
    private let currentPathLabelBackgroundColor = UIColor(hex: "#DBF8DF")
    private let currentPathLabelTextColor = UIColor(hex: "#44BA5E")
    private var isHomePathLabel = false
    private let chevronImageView: UIImageView = {
        let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.forward"))
        chevronImageView.tintColor = .systemGray2
        chevronImageView.contentMode = .center
        chevronImageView.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
        return chevronImageView
    }()
    private let nameLabel: UILabel = {
        let label = BasePaddingLabel()
        label.clipsToBounds = true
        label.layer.cornerRadius = 12
        label.numberOfLines = 1
        label.font = .systemFont(ofSize: 14, weight: .medium)
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
