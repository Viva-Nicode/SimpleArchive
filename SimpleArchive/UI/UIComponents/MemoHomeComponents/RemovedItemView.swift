import UIKit

final class RemovedItemView: UITableViewCell {

    private(set) var itemTitleLabel: UILabel = {
        let itemTitleLabel = UILabel()
        itemTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        return itemTitleLabel
    }()
    private(set) lazy var fileIconImageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.contentMode = .scaleAspectFit
        return $0
    }(UIImageView())

    static let reuseIdentifier = "RemovedItemView"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor(named: "FixedFileItemBackgroundColor")
        contentView.addSubview(itemTitleLabel)
        contentView.addSubview(fileIconImageView)
        let line = CAShapeLayer()
		line.frame = .init(x: 10, y: 46, width: bounds.width + 20, height: 2)
        line.strokeColor = UIColor.systemGray4.cgColor
        line.lineWidth = 2
        line.lineDashPattern = [4, 4]
        let path = UIBezierPath()
        path.move(to: .init(x: 0, y: 0))
        path.addLine(to: .init(x: line.frame.width, y: 0))
        line.path = path.cgPath

        contentView.layer.addSublayer(line)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            fileIconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            fileIconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            fileIconImageView.widthAnchor.constraint(equalToConstant: 40),
            fileIconImageView.heightAnchor.constraint(equalToConstant: 40),

            itemTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            itemTitleLabel.leadingAnchor.constraint(equalTo: fileIconImageView.trailingAnchor, constant: 10),
        ])
    }

    func configure(item: MemoPageModel) {
        itemTitleLabel.text = item.name

        if item.isSingleComponentPage {
            switch item.components.first!.type {
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
