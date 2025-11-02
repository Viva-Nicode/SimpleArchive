import Combine
import UIKit

class MemoTableRowView: UITableViewCell {

    private let containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.backgroundColor = .systemGray6
        containerStackView.axis = .horizontal
        containerStackView.spacing = 10
        containerStackView.alignment = .center
        containerStackView.distribution = .fill
        containerStackView.isLayoutMarginsRelativeArrangement = true
        containerStackView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
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

    static let cellId = "MemoTableRowView"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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

    public func configure(with fileItem: some StorageItem) {
        fileNameLable.text = fileItem.name

        if let directory = fileItem as? MemoDirectoryModel {
            fileIconImageView.image = UIImage(systemName: "folder")
            fileIconImageView.tintColor = .magenta
            containingFileCountLable.text = "\(directory.getChildItemSize())"
        } else if let page = fileItem as? MemoPageModel {
            if page.isSingleComponentPage {
                switch page.getComponents.first!.type {

                    case .text:
                        fileIconImageView.image = UIImage(systemName: "note.text")
                        fileIconImageView.tintColor = .systemGreen
                        containingFileCountLable.text = ""

                    case .table:
                        fileIconImageView.image = UIImage(systemName: "tablecells")
                        fileIconImageView.tintColor = .yellow
                        containingFileCountLable.text = ""

                    case .audio:
                        fileIconImageView.image = UIImage(systemName: "music.note.list")
                        fileIconImageView.tintColor = .orange
                        containingFileCountLable.text =
                            "\((page.getComponents.first as! AudioComponent).detail.tracks.count)"
                }
            } else {
                fileIconImageView.image = UIImage(systemName: "macwindow")
                fileIconImageView.tintColor = .systemBlue
                containingFileCountLable.text = "\(page.getComponents.count)"
            }
        }
    }

    func setFileNameLabelText(_ newName: String) {
        fileNameLable.text = newName
    }
}
