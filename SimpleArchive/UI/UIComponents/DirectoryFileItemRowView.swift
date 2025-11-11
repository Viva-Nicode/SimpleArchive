import Combine
import UIKit

class DirectoryFileItemRowView: UITableViewCell {

    private let innerShadowLayer = CALayer()
    private let innerShadowOffset: CGSize = .init(width: -7, height: 7)
    private let innerShadowOpacity: Float = 0.43
    private let innerShadowRadius: CGFloat = 12

    override func layoutSubviews() {
        super.layoutSubviews()
        innerShadowLayer.frame = bounds
        applyInnerShadow()
    }

    private func configureStyle() {
        containerStackView.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
        containerStackView.layer.cornerRadius = 10
        contentView.layer.cornerRadius = 10
        layer.cornerRadius = 10
        containerStackView.layer.masksToBounds = false

        innerShadowLayer.frame = bounds
        innerShadowLayer.cornerRadius = layer.cornerRadius
        innerShadowLayer.backgroundColor = backgroundColor?.cgColor
        innerShadowLayer.masksToBounds = true
        containerStackView.layer.addSublayer(innerShadowLayer)

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

    private let containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.backgroundColor = .systemGray6
        containerStackView.axis = .horizontal
        containerStackView.layer.cornerRadius = 10
        containerStackView.layer.masksToBounds = false
        containerStackView.clipsToBounds = false
        containerStackView.spacing = 17
        containerStackView.alignment = .center
        containerStackView.distribution = .fill
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.layoutMargins = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        return containerStackView
    }()
    private let fileIconImageView: UIImageView = {
        let fileIconImageView = UIImageView()
        fileIconImageView.contentMode = .scaleAspectFit
        fileIconImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        fileIconImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return fileIconImageView
    }()
    private let fileNameLable: UILabel = {
        let nameLable = UILabel()
        nameLable.textColor = .label
        nameLable.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLable.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return nameLable
    }()
    private let containingFileCountLable: UILabel = {
        let containingFileCountLable = UILabel()
        containingFileCountLable.textColor = .systemGray2
        return containingFileCountLable
    }()

    static let reuseIdentifier = "DirectoryFileItemRowView"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        configureStyle()
        setupUI()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(containerStackView)

        containerStackView.addArrangedSubview(fileIconImageView)
        containerStackView.addArrangedSubview(fileNameLable)
        containerStackView.addArrangedSubview(UIView.spacerView)
        containerStackView.addArrangedSubview(containingFileCountLable)
    }

    private func setupConstraints() {
        containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }

    func configure(with fileItem: some StorageItem) {
        fileNameLable.text = fileItem.name

        if let directory = fileItem as? MemoDirectoryModel {
            fileIconImageView.image = UIImage(named: "folder")?.resized(to: .init(width: 40, height: 40))
            containingFileCountLable.text = "\(directory.getChildItemSize())"
        } else if let page = fileItem as? MemoPageModel {
            if page.isSingleComponentPage {
                switch page.getComponents.first!.type {

                    case .text:
                        fileIconImageView.image = UIImage(named: "text")?.resized(to: .init(width: 40, height: 40))
                        containingFileCountLable.text =
                            "\((page.getComponents.first as! TextEditorComponent).detail.count)"

                    case .table:
                        fileIconImageView.image = UIImage(named: "table")?.resized(to: .init(width: 40, height: 40))
                        containingFileCountLable.text = ""

                    case .audio:
                        fileIconImageView.image = UIImage(named: "audio")?.resized(to: .init(width: 40, height: 40))
                        containingFileCountLable.text =
                            "\((page.getComponents.first as! AudioComponent).detail.tracks.count)"
                }
            } else {
                fileIconImageView.image = UIImage(named: "multi")?.resized(to: .init(width: 40, height: 40))
                containingFileCountLable.text = "\(page.getComponents.count)"
            }
        }
    }

    func setFileNameLabelText(_ newName: String) {
        fileNameLable.text = newName
    }
}
