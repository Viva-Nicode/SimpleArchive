import UIKit

final class ExpendedAudioControlBarTrackListView: UIView {
    private(set) var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
		tableView.isPrefetchingEnabled = false
		
        tableView.rowHeight = 65
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(
            AudioTableRowView.self,
            forCellReuseIdentifier: AudioTableRowView.reuseIdentifier
        )
        return tableView
    }()

    private var audioComponentDataSource: AudioComponentDataSource?

    init() {
		super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }

	deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }
	
    private func setupUI() {
		translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        addSubview(tableView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(audioComponent: AudioComponent) {
        let dataSource = AudioComponentDataSource(audioPageComponent: audioComponent)
        audioComponentDataSource = dataSource
        tableView.dataSource = dataSource
        tableView.reloadData()
		tableView.layoutIfNeeded()
    }
}
