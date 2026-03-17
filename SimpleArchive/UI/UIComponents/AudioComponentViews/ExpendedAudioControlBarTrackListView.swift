import UIKit

final class ExpendedAudioControlBarTrackListView: UIView {
    private(set) var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.isPrefetchingEnabled = false
        tableView.alpha = 0
        tableView.rowHeight = 65
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(AudioTableRowView.self, forCellReuseIdentifier: AudioTableRowView.reuseIdentifier)
        return tableView
    }()

    private var audioComponentDataSource: AudioComponentDataSource?
    private var thin: [NSLayoutConstraint] = []
    private var expended: [NSLayoutConstraint] = []

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
        clipsToBounds = true
        alpha = 0
        addSubview(tableView)
    }

    private func setupConstraints() {
        thin = [
            tableView.heightAnchor.constraint(equalToConstant: 350),
            tableView.widthAnchor.constraint(equalToConstant: UIView.screenWidth - 60),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 350),
        ]

        expended = [
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.widthAnchor.constraint(equalToConstant: UIView.screenWidth - 60),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]

        NSLayoutConstraint.activate(thin)
    }

    func configure(audioComponent: AudioComponent) {
        let dataSource = AudioComponentDataSource(audioPageComponent: audioComponent)
        audioComponentDataSource = dataSource
        tableView.dataSource = dataSource
        tableView.reloadData()
    }

    func updateLayoytToExpended() {
        NSLayoutConstraint.deactivate(thin)
        NSLayoutConstraint.activate(expended)
        alpha = 1
        tableView.alpha = 1
    }

    func updateLayoutToThin() {
        NSLayoutConstraint.deactivate(expended)
        NSLayoutConstraint.activate(thin)
        alpha = 0
        tableView.alpha = 0
    }
}
