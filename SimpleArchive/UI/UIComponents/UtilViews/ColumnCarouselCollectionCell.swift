import UIKit

final class ColumnCarouselCollectionCell: UICollectionViewCell {
    static let reuseIdentifier: String = "reuseColumnCarouselCollectionCellIdentifier"

    let editingCellSeparatorView: EditingCellSeparatorView = {
        let editingCellSeparatorView = EditingCellSeparatorView()
        editingCellSeparatorView.backgroundColor = .clear
        editingCellSeparatorView.pencilImageView.tintColor = .systemBlue
        editingCellSeparatorView.editingLabel.textColor = .systemBlue
        return editingCellSeparatorView
    }()
    let containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.axis = .vertical
        containerStackView.spacing = 8
        containerStackView.alignment = .center
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        return containerStackView
    }()
    let containerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    let columnTitleLable: UILabel = {
        let columnTitleLable = UILabel()
		columnTitleLable.textColor = AppAppearanceManager.shared.appTintColor
        columnTitleLable.font = .systemFont(ofSize: 14)
        columnTitleLable.textAlignment = .center
        columnTitleLable.adjustsFontSizeToFitWidth = true
        columnTitleLable.minimumScaleFactor = 0.75
        columnTitleLable.translatesAutoresizingMaskIntoConstraints = false
        return columnTitleLable
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
		backgroundColor = AppAppearanceManager.shared.appBaseColor
        layer.cornerRadius = 6
        layer.masksToBounds = false
		layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 1)
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 2

        contentView.addSubview(containerView)
        editingCellSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(editingCellSeparatorView)

        containerView.addSubview(columnTitleLable)
    }

    private func setupConstraints() {
        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        editingCellSeparatorView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10).isActive = true

        columnTitleLable.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
        columnTitleLable.heightAnchor.constraint(equalToConstant: 50).isActive = true
        columnTitleLable.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -8).isActive = true
        columnTitleLable.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    }

    func setColumnTitle(columnTitle: String) {
        columnTitleLable.text = columnTitle
    }

    func setIsSelected(isSelected: Bool) {
        editingCellSeparatorView.isHidden = !isSelected
    }
}
