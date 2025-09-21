import UIKit
import Combine

class MemoTableRowView: UITableViewCell {

    private let containerStackView: UIStackView = {
        let containerStackView = UIStackView()
        containerStackView.backgroundColor = .systemGray6
        containerStackView.axis = .horizontal
        containerStackView.spacing = 10
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
        containerStackView.addArrangedSubview(containingFileCountLable)
    }

    private func setupConstraints() {
        containerStackView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        containerStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        containerStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        containerStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }

    public func configure(with fileItem: some StorageItem) {

        fileIconImageView.image = UIImage(systemName: fileItem is MemoDirectoryModel ? "folder" : "note.text")
        fileIconImageView.tintColor = fileItem is MemoDirectoryModel ? .magenta : .systemBlue

        fileNameLable.text = fileItem.name

        containingFileCountLable.text = ""

        if let directoryFile = fileItem as? MemoDirectoryModel {
            containingFileCountLable.text = "\(directoryFile.getChildItemSize())"
        }
    }

    func setFileNameLabelText(_ newName: String) {
        fileNameLable.text = newName
    }
}
