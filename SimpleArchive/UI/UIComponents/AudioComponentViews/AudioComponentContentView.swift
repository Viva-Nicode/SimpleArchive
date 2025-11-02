import AVFoundation
import Combine
import UIKit

final class AudioComponentContentView: UIView {

    private var componentID: UUID!
    private var dispatcher: AudioComponentActionDispatcher?
    private var cancels: AnyCancellable?
    private var thumbnameSubscription: AnyCancellable?
    private var editAudioTrackMetadataConfrimButtonSubscription: AnyCancellable?
    private(set) var audioDownloadStatePopupView: AudioDownloadStatePopupView?

    private(set) var audioComponentToolBarStackView: UIStackView = {
        let audioComponentToolBarStackView = UIStackView()
        audioComponentToolBarStackView.axis = .horizontal
        audioComponentToolBarStackView.alignment = .center
        audioComponentToolBarStackView.distribution = .fill
        audioComponentToolBarStackView.spacing = 13
        audioComponentToolBarStackView.isLayoutMarginsRelativeArrangement = true
        audioComponentToolBarStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0, leading: 10, bottom: 0, trailing: 10)
        audioComponentToolBarStackView.translatesAutoresizingMaskIntoConstraints = false
        return audioComponentToolBarStackView
    }()
    private(set) var sortOptionStackView: UIStackView = {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 8
        $0.isLayoutMarginsRelativeArrangement = true
        $0.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10)
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIStackView())
    private(set) var separator: UILabel = {
        $0.text = "|"
        return $0
    }(UILabel())
    private(set) var sortByNameButton: UIButton = {
        $0.setTitle("name", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14)
        return $0
    }(UIButton())
    private(set) var sortBycreateButton: UIButton = {
        $0.setTitle("create date", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14)
        return $0
    }(UIButton())
    private(set) var totalAudioCountLabel: UILabel = {
        $0.font = .systemFont(ofSize: 15)
        return $0
    }(UILabel())
    private(set) var audioAddButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "plus.circle", withConfiguration: config)

        button.setImage(image, for: .normal)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()
    let audioTrackTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.register(AudioTableRowView.self, forCellReuseIdentifier: AudioTableRowView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    var audioTrackTotal: Int = 0

    var addbuttonHeightConstraint: NSLayoutConstraint?
    var toolBarStackViewHeightConstraint: NSLayoutConstraint?
    var sortOptionStackViewHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
    }

    deinit { print("deinit AudioComponentContentView") }

    private func setupUI() {
        audioTrackTableView.backgroundColor = .clear
        audioTrackTableView.delegate = self

        sortBycreateButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray, for: .normal)
        sortByNameButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray, for: .normal)

        totalAudioCountLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray
        separator.textColor = traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray

        addSubview(audioComponentToolBarStackView)
        audioComponentToolBarStackView.addArrangedSubview(totalAudioCountLabel)
        audioComponentToolBarStackView.addArrangedSubview(UIView.spacerView)
        audioComponentToolBarStackView.addArrangedSubview(audioAddButton)
        audioAddButton.tintColor = traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray

        audioAddButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                let popupView = AudioDownloadPopupView()
                cancels = popupView
                    .downloadButtonActionPublisher
                    .sink {
                        self.audioDownloadStatePopupView = AudioDownloadStatePopupView()
                        self.audioDownloadStatePopupView?.disableDismissPopupViewByTapBackground()
                        self.audioDownloadStatePopupView?.show()
                        self.dispatcher?.downloadMusics(componentID: self.componentID, with: $0)
                        self.cancels = nil
                    }
                popupView.show()
            }, for: .touchUpInside)

        sortByNameButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                sortBycreateButton.setTitleColor(
                    traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray, for: .normal)
                sortByNameButton.setTitleColor(.white, for: .normal)
                dispatcher?.changeSortByAudioTracks(componentID: componentID, sortBy: .name)
            }, for: .touchUpInside)

        sortBycreateButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                sortByNameButton.setTitleColor(
                    traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray, for: .normal)
                sortBycreateButton.setTitleColor(.white, for: .normal)
                dispatcher?.changeSortByAudioTracks(componentID: componentID, sortBy: .createDate)
            }, for: .touchUpInside)

        addSubview(sortOptionStackView)
        sortOptionStackView.addArrangedSubview(UIView.spacerView)
        sortOptionStackView.addArrangedSubview(sortByNameButton)
        sortOptionStackView.addArrangedSubview(separator)
        sortOptionStackView.addArrangedSubview(sortBycreateButton)
        addSubview(audioTrackTableView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            audioComponentToolBarStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            audioComponentToolBarStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            audioComponentToolBarStackView.topAnchor.constraint(equalTo: topAnchor),

            sortOptionStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sortOptionStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sortOptionStackView.topAnchor.constraint(equalTo: audioComponentToolBarStackView.bottomAnchor),

            audioTrackTableView.topAnchor.constraint(equalTo: sortOptionStackView.bottomAnchor),
            audioTrackTableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            audioTrackTableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            audioTrackTableView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        addbuttonHeightConstraint = audioAddButton.heightAnchor.constraint(equalToConstant: 44)
        toolBarStackViewHeightConstraint = audioComponentToolBarStackView.heightAnchor.constraint(equalToConstant: 45)
        sortOptionStackViewHeightConstraint = sortOptionStackView.heightAnchor.constraint(equalToConstant: 30)

        addbuttonHeightConstraint?.isActive = true
        toolBarStackViewHeightConstraint?.isActive = true
        sortOptionStackViewHeightConstraint?.isActive = true
    }

    func minimizeContentView(_ isMinimize: Bool) {
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.alpha = isMinimize ? 0 : 1
                self?.addbuttonHeightConstraint?.constant = isMinimize ? 0 : 44
                self?.toolBarStackViewHeightConstraint?.constant = isMinimize ? 0 : 45
                self?.sortOptionStackViewHeightConstraint?.constant = isMinimize ? 0 : 30
                self?.layoutIfNeeded()
            }
        )
    }

    // Single 전용
    func configure(
        content audioComponent: AudioComponent,
        datasource: AudioComponentDataSource,
        dispatcher: AudioComponentActionDispatcher,
        componentID: UUID
    ) {
        self.dispatcher = dispatcher
        self.componentID = componentID
        self.audioTrackTableView.dataSource = datasource

        self.audioTrackTableView.dragDelegate = self
        self.audioTrackTableView.dropDelegate = self
        self.audioTrackTotal = audioComponent.detail.tracks.count
        totalAudioCountLabel.text = "\(audioTrackTotal) audios in total"

        switch audioComponent.detail.sortBy {
            case .name:
                sortByNameButton.setTitleColor(.white, for: .normal)

            case .createDate:
                sortBycreateButton.setTitleColor(.white, for: .normal)

            case .manual:
                break
        }
    }

    // MemoPage 전용 configure
    func configure(
        content audioComponent: AudioComponent,
        dispatcher: AudioComponentActionDispatcher,
        componentID: UUID
    ) {
        self.dispatcher = dispatcher
        self.componentID = componentID
        let datasource = AudioComponentDataSource(
            tracks: audioComponent.detail.tracks,
            sortBy: audioComponent.detail.sortBy)
        self.audioTrackTableView.dataSource = datasource
        dispatcher.storeDataSource(componentID: componentID, datasource: datasource)

        self.audioTrackTableView.dragDelegate = self
        self.audioTrackTableView.dropDelegate = self
        self.audioTrackTotal = audioComponent.detail.tracks.count
        totalAudioCountLabel.text = "\(audioTrackTotal) audios in total"

        switch audioComponent.detail.sortBy {
            case .name:
                sortByNameButton.setTitleColor(.white, for: .normal)

            case .createDate:
                sortBycreateButton.setTitleColor(.white, for: .normal)

            case .manual:
                break
        }

        self.alpha = audioComponent.isMinimumHeight ? 0 : 1
        self.toolBarStackViewHeightConstraint?.constant = audioComponent.isMinimumHeight ? 0 : 45
        self.sortOptionStackViewHeightConstraint?.constant = audioComponent.isMinimumHeight ? 0 : 30
        self.addbuttonHeightConstraint?.constant = audioComponent.isMinimumHeight ? 0 : 44
    }

    func insertRow(trackIndices: [Int]) {
        audioTrackTableView.performBatchUpdates {
            let indexPaths = trackIndices.map { IndexPath(row: $0, section: .zero) }
            audioTrackTableView.insertRows(at: indexPaths, with: .automatic)
            audioTrackTotal += trackIndices.count
            totalAudioCountLabel.text = "\(audioTrackTotal) audios in total"
        }
    }

    func removeRow(trackIndex: Int) {
        audioTrackTableView.performBatchUpdates {
            let indexPath = IndexPath(row: trackIndex, section: .zero)
            audioTrackTableView.deleteRows(at: [indexPath], with: .automatic)
            audioTrackTotal -= 1
            totalAudioCountLabel.text = "\(audioTrackTotal) audios in total"
        }
    }
}

extension AudioComponentContentView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 65 }

    func tableView(
        _ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    )
        -> UISwipeActionsConfiguration?
    {

        let editAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completionHandler in
            guard let self = self else { return }

            if let cell = tableView.cellForRow(at: indexPath), let audioTableRowView = cell as? AudioTableRowView {
                let title = audioTableRowView.titleLabel.text
                let artist = audioTableRowView.artistLabel.text
                let thumbnail = audioTableRowView.thumbnailImageView.image

                let audioTrackEditPopupView = AudioTrackEditPopupView(
                    title: title, artist: artist, thumbnail: thumbnail)

                thumbnameSubscription = audioTrackEditPopupView.thumbnailPublisher
                    .sink { [weak self] in
                        guard let self else { return }
                        self.dispatcher?.presentGallery($0)
                    }

                editAudioTrackMetadataConfrimButtonSubscription = audioTrackEditPopupView.confirmButtonPublisher
                    .sink { [weak self] editedMetadata in
                        guard let self else { return }
                        audioTrackEditPopupView.dismiss()
                        self.dispatcher?
                            .changeAudioTrackMetadata(
                                editMetadata: editedMetadata,
                                componentID: self.componentID,
                                trackIndex: indexPath.row)
                    }
                audioTrackEditPopupView.show()
            }
            completionHandler(true)
        }
        editAction.image = UIImage(systemName: "square.and.pencil")
        editAction.backgroundColor = .systemBlue

        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            dispatcher?.removeAudioTrack(componentID: componentID, trackIndex: indexPath.row)
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash")

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        dispatcher?.playAudioTrack(componentID: componentID, with: indexPath.row)
    }
}

extension AudioComponentContentView: UITableViewDragDelegate {

    func tableView(_ tableView: UITableView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath)
        -> [UIDragItem]
    {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = indexPath.row
        return [dragItem]
    }

    func tableView(
        _ tableView: UITableView, dropSessionDidUpdate session: any UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UITableViewDropProposal {
        if session.localDragSession != nil {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UITableViewDropProposal(operation: .cancel)
        }
    }
}

extension AudioComponentContentView: UITableViewDropDelegate {

    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

        if let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath {

            let fromIndex = sourceIndexPath.row
            let toIndex = destinationIndexPath.row

            dispatcher?.dropAudioTrack(componentID: componentID, src: fromIndex, des: toIndex)

            tableView.performBatchUpdates(
                {
                    tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
                }, completion: nil)

            coordinator.drop(
                item.dragItem,
                toRowAt: IndexPath(item: max(0, destinationIndexPath.item), section: destinationIndexPath.section)
            )

            sortBycreateButton.setTitleColor(
                traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray, for: .normal)
            sortByNameButton.setTitleColor(
                traitCollection.userInterfaceStyle == .dark ? .lightGray : .gray, for: .normal)
        }
    }
}
