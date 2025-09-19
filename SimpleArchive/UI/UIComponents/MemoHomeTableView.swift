import UIKit
import Combine

class MemoHomeTableView: UICollectionViewCell {

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.accessibilityIdentifier = "memoHomeTableView"
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.dragInteractionEnabled = true
        tableView.register(MemoTableRowView.self, forCellReuseIdentifier: MemoTableRowView.cellId)
        return tableView
    }()
    private let tableViewContainer: UIStackView = {
        let tableViewContainer = UIStackView()
        tableViewContainer.axis = .vertical
        tableViewContainer.isLayoutMarginsRelativeArrangement = true
        tableViewContainer.layoutMargins = .init(top: 0, left: 15, bottom: 0, right: 15)
        tableViewContainer.translatesAutoresizingMaskIntoConstraints = false
        return tableViewContainer
    }()

    weak var directoryContents: MemoDirectoryModel?
    var subject: PassthroughSubject<MemoHomeSubViewInput, Never>?

    static let reuseIdentifier = "stackCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.dragDelegate = self
        tableView.dropDelegate = self

        tableViewContainer.addArrangedSubview(tableView)
        contentView.addSubview(tableViewContainer)
    }

    private func setupConstraints() {
        tableViewContainer.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        tableViewContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        tableViewContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        tableViewContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }

    public func configure(
        memoDirectoryModel: MemoDirectoryModel,
        subject: PassthroughSubject<MemoHomeSubViewInput, Never>
    ) {
        self.directoryContents = memoDirectoryModel
        self.subject = subject
        tableView.reloadData()
    }
}
