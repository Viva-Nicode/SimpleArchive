import Foundation
import UIKit

final class FixedFileItemView: UICollectionViewCell {
    static let reuseIdentifier = "FixedItem"

    private let innerShadowLayer = CALayer()

    private let outerShadowOffset: CGSize = .init(width: -3, height: 3)
    private let outerShadowOpacity: Float = 0.4
    private let outerShadowRadius: CGFloat = 2

    private let innerShadowOffset: CGSize = .init(width: -7, height: 7)
    private let innerShadowOpacity: Float = 0.4
    private let innerShadowRadius: CGFloat = 12

    private let fileIconImageViewSize = CGSize(width: 40, height: 40)

    private(set) var containerView: UIView = {
        $0.backgroundColor = .clear
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIView())

    private(set) var fileIconImageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIImageView())

    private(set) var titleLabel: UILabel = {
        $0.font = .systemFont(ofSize: 15)
        $0.numberOfLines = 1
        $0.adjustsFontSizeToFitWidth = true
        $0.minimumScaleFactor = 0.7
        $0.textAlignment = .center
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UILabel())

    override init(frame: CGRect) {
        super.init(frame: .zero)
        configureStyle()
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        titleLabel.text = ""
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        innerShadowLayer.frame = bounds
        applyInnerShadow()
    }

    private func setupUI() {
        contentView.addSubview(containerView)
        contentView.backgroundColor = .clear

        containerView.addSubview(fileIconImageView)
        containerView.addSubview(titleLabel)
    }

    private func setupConstraints() {
        let fileName = "file name"
        let font = UIFont.systemFont(ofSize: 15)
        let constraintRect = CGSize(width: 80, height: .max)
        let boundingBox = fileName.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        let contentSpaceHeight = (80 - (boundingBox.size.height + fileIconImageViewSize.height)) * 0.5

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            fileIconImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            fileIconImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: contentSpaceHeight),
            fileIconImageView.widthAnchor.constraint(equalToConstant: fileIconImageViewSize.width),
            fileIconImageView.heightAnchor.constraint(equalToConstant: fileIconImageViewSize.height),

            titleLabel.topAnchor.constraint(equalTo: fileIconImageView.bottomAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 80),
            titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        ])
    }

    private func configureStyle() {
        self.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = false
        
        self.layer.shadowColor = UIColor(named: "FixedFileItemShodowColor")?.cgColor
        self.layer.shadowOffset = outerShadowOffset
        self.layer.shadowOpacity = outerShadowOpacity
        self.layer.shadowRadius = outerShadowRadius

        innerShadowLayer.frame = bounds
        innerShadowLayer.cornerRadius = layer.cornerRadius
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

    func configure(fileName: String, componentType: ComponentType?) {

        self.titleLabel.text = fileName

        if let componentType {
            switch componentType {
                case .text:
                    fileIconImageView.image = UIImage(named: "text")?.resized(to: .init(width: 40, height: 40))

                case .table:
                    fileIconImageView.image = UIImage(named: "table")?.resized(to: .init(width: 40, height: 40))

                case .audio:
                    fileIconImageView.image = UIImage(named: "audio")?.resized(to: .init(width: 40, height: 40))
            }
        } else {
            fileIconImageView.image = UIImage(named: "multi")?.resized(to: .init(width: 40, height: 40))
        }
    }
}
