import UIKit

final class ComponentItemView: UICollectionViewCell {

    private let itemSymbolImageView: UIImageView = {
        let itemSymbolImageView = UIImageView()
        itemSymbolImageView.contentMode = .scaleAspectFill
        itemSymbolImageView.tintColor = .systemGray4
        return itemSymbolImageView
    }()
    private let itemNameLabel: UILabel = {
        let itemNameLabel = UILabel()
        itemNameLabel.font = .systemFont(ofSize: 15, weight: .medium)
        itemNameLabel.textColor = .systemGray
        return itemNameLabel
    }()
    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 5
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    static let reuseIdentifier = "ComponentItemView"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerStackView)
        containerStackView.addArrangedSubview(itemSymbolImageView)
        containerStackView.addArrangedSubview(itemNameLabel)
    }

    private func setupConstraints() {
        containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
        containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
    }

    func configure(with: ComponentType) {
        itemSymbolImageView.image = UIImage(systemName: with.getSymbolSystemName)
        itemNameLabel.text = with.getTitle
    }

    func toggleIsSelect() {
        if itemSymbolImageView.tintColor == .systemGray4 {
            itemSymbolImageView.tintColor = .systemPink
            itemNameLabel.textColor = .systemPink
        } else {
            itemSymbolImageView.tintColor = .systemGray4
            itemNameLabel.textColor = .systemGray4
        }
    }

    func setColorToBlue() {
        itemSymbolImageView.tintColor = .systemBlue
        itemNameLabel.textColor = .label
    }
}
