import UIKit

final class ColumnCarouselCollectionCell: UICollectionViewCell {
    static let reuseIdentifier: String = "reuseColumnCarouselCollectionCellIdentifier"

    private let innerShadowLayer = CALayer()

    private let outerShadowOffset: CGSize = .init(width: -3, height: 3)
    private let outerShadowOpacity: Float = 0.6
    private let outerShadowRadius: CGFloat = 4

    private let innerShadowOffset: CGSize = .init(width: -20, height: 20)
    private let innerShadowOpacity: Float = 0.45
    private let innerShadowRadius: CGFloat = 22

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
        columnTitleLable.textColor = .black
        columnTitleLable.font = .systemFont(ofSize: 14)
        columnTitleLable.translatesAutoresizingMaskIntoConstraints = false
        return columnTitleLable
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureStyle()
        setupUI()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("deinit TableComponentView") }

    private func configureStyle() {
        self.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1)
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = false

        self.layer.shadowColor = UIColor(white: 0.7, alpha: 1).cgColor
        self.layer.shadowOffset = outerShadowOffset
        self.layer.shadowOpacity = outerShadowOpacity
        self.layer.shadowRadius = outerShadowRadius

        innerShadowLayer.frame = bounds
        innerShadowLayer.cornerRadius = layer.cornerRadius
        innerShadowLayer.backgroundColor = backgroundColor?.cgColor
        innerShadowLayer.masksToBounds = true
        self.layer.addSublayer(innerShadowLayer)

        applyInnerShadow()
    }

    private func applyInnerShadow() {
        let radius = layer.cornerRadius
        innerShadowLayer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let path = UIBezierPath(
            roundedRect: innerShadowLayer.bounds.insetBy(dx: -22, dy: -22),
            cornerRadius: radius)
        let cutout = UIBezierPath(
            roundedRect: innerShadowLayer.bounds.insetBy(dx: -18, dy: -18),
            cornerRadius: radius
        )
        .reversing()

        path.append(cutout)

        let topLeftShadow = CAShapeLayer()
        topLeftShadow.frame = innerShadowLayer.bounds
        topLeftShadow.shadowPath = path.cgPath
        topLeftShadow.masksToBounds = true
        topLeftShadow.shadowColor = UIColor.black.cgColor

        topLeftShadow.shadowOffset = innerShadowOffset
        topLeftShadow.shadowOpacity = innerShadowOpacity
        topLeftShadow.shadowRadius = innerShadowRadius

        topLeftShadow.fillRule = .evenOdd

        let bottomRightShadow = CAShapeLayer()
        bottomRightShadow.frame = innerShadowLayer.bounds
        bottomRightShadow.shadowPath = path.cgPath
        bottomRightShadow.masksToBounds = true
        bottomRightShadow.shadowColor = UIColor.black.cgColor

        bottomRightShadow.shadowOffset = innerShadowOffset
        bottomRightShadow.shadowOpacity = innerShadowOpacity
        bottomRightShadow.shadowRadius = innerShadowRadius

        bottomRightShadow.fillRule = .evenOdd

        innerShadowLayer.addSublayer(topLeftShadow)
        innerShadowLayer.addSublayer(bottomRightShadow)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        innerShadowLayer.frame = bounds
        applyInnerShadow()
    }

    private func setupUI() {
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
        columnTitleLable.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    }

    func setColumnTitle(columnTitle: String) {
        columnTitleLable.text = columnTitle
    }

    func setIsSelected(isSelected: Bool) {
        editingCellSeparatorView.isHidden = !isSelected
    }
}
