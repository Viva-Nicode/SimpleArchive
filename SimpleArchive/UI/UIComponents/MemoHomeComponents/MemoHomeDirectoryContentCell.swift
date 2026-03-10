import Combine
import UIKit

final class MemoHomeDirectoryContentCell: UICollectionViewCell {

    private(set) var emptyFolderView: UIView = {
        let dropView = UIView()
        dropView.translatesAutoresizingMaskIntoConstraints = false
        return dropView
    }()
    private(set) var emptyFolderImageView: UIImageView = {
        let image = UIImage(named: "emptyFolderImage")?.resized(to: .init(width: 200, height: 200))
        let imageView = UIImageView(image: image)
        return imageView
    }()
    private(set) var emptyFolderLabel: UILabel = {
        $0.text = "Empty Folder"
        $0.font = .systemFont(ofSize: 26, weight: .regular)
        return $0
    }(UILabel())
    private(set) var emptyFolderStackView: UIStackView = {
        let emptyFolderStackView = UIStackView()
        emptyFolderStackView.axis = .vertical
        emptyFolderStackView.alignment = .center
        emptyFolderStackView.spacing = 8
        emptyFolderStackView.translatesAutoresizingMaskIntoConstraints = false
        return emptyFolderStackView
    }()
    private(set) var directoryContentTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.layer.masksToBounds = false
        tableView.clipsToBounds = false
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 100, right: 0)
        tableView.accessibilityIdentifier = "MemoHomeDirectoryContentCellTableView"
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.dragInteractionEnabled = true
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            DirectoryFileItemRowView.self,
            forCellReuseIdentifier: DirectoryFileItemRowView.reuseIdentifier)
        return tableView
    }()

    static let reuseIdentifier = "MemoHomeDirectoryContentCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(directoryContentTableView)

        emptyFolderStackView.addArrangedSubview(emptyFolderImageView)
        emptyFolderStackView.addArrangedSubview(emptyFolderLabel)

        emptyFolderView.addSubview(emptyFolderStackView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            directoryContentTableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            directoryContentTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            directoryContentTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            directoryContentTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        removeEmptyFolderView()
    }

    func removeEmptyFolderView() {
        emptyFolderView.removeFromSuperview()
        emptyFolderView.removeConstraints(emptyFolderView.constraints)
    }

    func showEmptyFolderView() {
        if directoryContentTableView.dataSource?.numberOfSections?(in: directoryContentTableView) == .zero {
            contentView.addSubview(emptyFolderView)
            emptyFolderView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            emptyFolderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            emptyFolderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            emptyFolderView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

            emptyFolderStackView.centerXAnchor.constraint(equalTo: emptyFolderView.centerXAnchor).isActive = true
            emptyFolderStackView.centerYAnchor.constraint(equalTo: emptyFolderView.centerYAnchor).isActive = true
        }
    }

    func configure(datasource: MemoHomeDirectoryContentCellDataSource) {
        self.directoryContentTableView.dataSource = datasource
        self.directoryContentTableView.delegate = datasource
        self.directoryContentTableView.dragDelegate = datasource
        self.directoryContentTableView.dropDelegate = datasource
        self.emptyFolderView.addInteraction(UIDropInteraction(delegate: datasource))
        self.directoryContentTableView.reloadData()
        self.showEmptyFolderView()
    }

    func deleteItem(with index: Int) {
        directoryContentTableView.performBatchUpdates {
            directoryContentTableView.deleteSections(IndexSet(integer: index), with: .fade)
        }
        showEmptyFolderView()
    }

    func insertItem(indices: [Int]) {
        directoryContentTableView.performBatchUpdates {
            for idx in indices {
                directoryContentTableView
                    .insertSections(IndexSet(integer: idx), with: .automatic)
                directoryContentTableView
                    .insertRows(at: [IndexPath(row: 0, section: idx)], with: .automatic)
            }
        }
        removeEmptyFolderView()
    }
}
