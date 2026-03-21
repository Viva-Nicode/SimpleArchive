import UIKit

final class ExpendedAudioControlBarTrackListView: UIView {
    private(set) var audioTrackTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.isPrefetchingEnabled = false
        tableView.alpha = 0
        tableView.layer.cornerRadius = 22
        tableView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        tableView.rowHeight = 65
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(AudioTableRowView.self, forCellReuseIdentifier: AudioTableRowView.reuseIdentifier)
        return tableView
    }()

    private var audioComponentDataSource: AudioComponentDataSource?
    private var thinConstraints: [NSLayoutConstraint] = []
    private var expendedConstraints: [NSLayoutConstraint] = []

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
        backgroundColor = .clear
        clipsToBounds = true
        layer.cornerRadius = 22
        layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        alpha = 0
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(audioTrackTableView)
    }

    private func setupConstraints() {
        thinConstraints = [
            audioTrackTableView.heightAnchor.constraint(equalToConstant: 350),
            audioTrackTableView.widthAnchor.constraint(equalToConstant: UIView.screenWidth - 60),
            audioTrackTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            audioTrackTableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 350),
        ]

        expendedConstraints = [
            audioTrackTableView.topAnchor.constraint(equalTo: topAnchor),
            audioTrackTableView.widthAnchor.constraint(equalToConstant: UIView.screenWidth - 60),
            audioTrackTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            audioTrackTableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]

        NSLayoutConstraint.activate(thinConstraints)
    }

    func configure(audioComponent: AudioComponent) {
        let dataSource = AudioComponentDataSource(audioPageComponent: audioComponent)
        audioComponentDataSource = dataSource
        audioTrackTableView.dataSource = dataSource
        audioTrackTableView.reloadData()
    }

    func updateLayoytToExpended() {
        NSLayoutConstraint.deactivate(thinConstraints)
        NSLayoutConstraint.activate(expendedConstraints)
        alpha = 1
        audioTrackTableView.alpha = 1
    }

    func updateLayoutToThin() {
        NSLayoutConstraint.deactivate(expendedConstraints)
        NSLayoutConstraint.activate(thinConstraints)
        alpha = 0
        audioTrackTableView.alpha = 0
    }
}
