import Combine
import UIKit

final class MemoHomeDirectoryContentCell: UICollectionViewCell {
    private(set) var directoryContentTableView: UICollectionView = {
        let spacing = UIConstants.fileItemSpacing
        let layout = DirectoryContentsLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.alwaysBounceVertical = true
        collectionView.register(FileItemView.self, forCellWithReuseIdentifier: FileItemView.reuseIdentifier)
        collectionView.isPrefetchingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = true
        collectionView.contentInset = .init(top: 0, left: 0, bottom: 100, right: 0)
        collectionView.accessibilityIdentifier = "MemoHomeDirectoryContentCellTableView"
        collectionView.backgroundColor = .clear
        collectionView.dragInteractionEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
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
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.addSubview(directoryContentTableView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            directoryContentTableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            directoryContentTableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            directoryContentTableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            directoryContentTableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    private(set) var directoryContentDataSource: DirectoryContentDataSource?

    func configure(datasource: DirectoryContentDataSource) {
        directoryContentDataSource = datasource
        directoryContentTableView.dataSource = datasource
        directoryContentTableView.delegate = datasource
        directoryContentTableView.reloadData()
        directoryContentTableView.collectionViewLayout.invalidateLayout()
    }

    func deleteItem(with index: Int) {
        directoryContentTableView.performBatchUpdates {
            directoryContentTableView.deleteItems(at: [IndexPath(item: index, section: 0)])
        }
    }

    func insertItem(indices: [Int]) {
        directoryContentTableView.performBatchUpdates {
            for idx in indices {
                let paths = [IndexPath(item: idx, section: 0)]
                directoryContentTableView.insertItems(at: paths)
            }
        }
    }
}
