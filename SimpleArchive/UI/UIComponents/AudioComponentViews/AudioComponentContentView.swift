import AVFoundation
import Combine
import UIKit

final class AudioComponentContentView: UIView, UIDocumentPickerDelegate {
    private(set) var audioComponentToolBarStackView: UIStackView = {
        let audioComponentToolBarStackView = UIStackView()
        audioComponentToolBarStackView.axis = .horizontal
        audioComponentToolBarStackView.alignment = .center
        audioComponentToolBarStackView.distribution = .fill
        audioComponentToolBarStackView.spacing = 9
        audioComponentToolBarStackView.isLayoutMarginsRelativeArrangement = true
        audioComponentToolBarStackView.directionalLayoutMargins = .init(top: 0, leading: 10, bottom: 0, trailing: 10)
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
        $0.textColor = .gray
        return $0
    }(UILabel())
    private(set) var sortByNameButton: UIButton = {
        $0.setTitle("name", for: .normal)
        $0.setTitleColor(.gray, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14)
        return $0
    }(UIButton())
    private(set) var sortBycreateButton: UIButton = {
        $0.setTitle("create date", for: .normal)
        $0.setTitleColor(.gray, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14)
        return $0
    }(UIButton())
    private(set) var totalAudioCountLabel: UILabel = {
        $0.font = .systemFont(ofSize: 15)
        $0.textColor = .label
        return $0
    }(UILabel())
    private(set) var audioAddButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        let image = UIImage(systemName: "plus.circle", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()
    private(set) var audioAddFromFileSystemButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let image = UIImage(systemName: "folder.badge.plus", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()
    private(set) var audioSearchButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let image = UIImage(systemName: "magnifyingglass", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }()
    private(set) var audioTrackSearchTextField: UnderlineTextField = {
        let audioTrackTitleTextField = UnderlineTextField()
        audioTrackTitleTextField.setTextColor(.label)
        audioTrackTitleTextField.setUnderLineColor(.label)
        audioTrackTitleTextField.placeholder = "Search Keyword"
        audioTrackTitleTextField.alpha = 0
        audioTrackTitleTextField.translatesAutoresizingMaskIntoConstraints = false
        return audioTrackTitleTextField
    }()
    private(set) var audioTrackTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.keyboardDismissMode = .onDrag
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(
            top: 12,
            left: 0,
            bottom: UIConstants.singleAudioViewControllerTableViewFooterHeight,
            right: 0)
        tableView.register(AudioTableRowView.self, forCellReuseIdentifier: AudioTableRowView.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    private(set) var searchingResultLabel: UILabel = {
        let searchingResultLabel = UILabel()
        searchingResultLabel.alpha = 0
        searchingResultLabel.translatesAutoresizingMaskIntoConstraints = false
        searchingResultLabel.font = .systemFont(ofSize: 16)
        searchingResultLabel.textAlignment = .left
        return searchingResultLabel
    }()

    private var addbuttonHeightConstraint: NSLayoutConstraint?
    private var toolBarStackViewHeightConstraint: NSLayoutConstraint?
    private var sortOptionStackViewHeightConstraint: NSLayoutConstraint?
    private var trackSearchTextFieldHeightConstraint: NSLayoutConstraint?
    private var searchingResultLabelHeightConstraint: NSLayoutConstraint?
    private var audioTrackTableViewTopConstraint: NSLayoutConstraint?

    private(set) var dispatcher: AudioComponentActionDispatcher?
    private var downloadAudioActionSubscription: AnyCancellable?
    private var audioComponentDataSource: AudioComponentDataSource?
    private(set) var audioDownloadStatePopupView: AudioDownloadStatePopupView?
    private var audioTrackTotal: Int = 0

    private var isVisibleAudioSearchTextView = false {
        didSet {
            if isVisibleAudioSearchTextView {
                audioTrackSearchTextField.becomeFirstResponder()
            } else {
                audioTrackSearchTextField.resignFirstResponder()
            }

            let isNeedReload = !isVisibleAudioSearchTextView && audioTrackSearchTextField.text != ""

            audioTrackSearchTextField.text = ""
            audioComponentDataSource?.searchingKeywoard = ""
            searchingResultLabel.text = ""

            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                usingSpringWithDamping: 1.0,
                initialSpringVelocity: 2.0,
                options: [.curveEaseOut],
                animations: { [weak self] in
                    guard let self else { return }
                    audioTrackSearchTextField.alpha = isVisibleAudioSearchTextView ? 1 : 0
                    searchingResultLabel.alpha = isVisibleAudioSearchTextView ? 1 : 0

                    trackSearchTextFieldHeightConstraint?.constant = isVisibleAudioSearchTextView ? 40 : 0
                    searchingResultLabelHeightConstraint?.constant = isVisibleAudioSearchTextView ? 15 : 0
                    audioTrackTableViewTopConstraint?.constant = isVisibleAudioSearchTextView ? 20 : 0
                    layoutIfNeeded()
                },
                completion: { [weak self] _ in
                    guard let self else { return }
                    if !isVisibleAudioSearchTextView && isNeedReload {
                        reloadAudioContentsTableView()
                    }
                }
            )
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
		setupAction()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
		setupAction()
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }
	
    private func setupUI() {
        audioTrackTableView.backgroundColor = .clear

        addSubview(audioComponentToolBarStackView)
        audioComponentToolBarStackView.addArrangedSubview(totalAudioCountLabel)
        audioComponentToolBarStackView.addArrangedSubview(UIView.spacerView)
        audioComponentToolBarStackView.addArrangedSubview(audioSearchButton)
        audioComponentToolBarStackView.addArrangedSubview(audioAddFromFileSystemButton)
        audioComponentToolBarStackView.addArrangedSubview(audioAddButton)

        sortOptionStackView.addArrangedSubview(UIView.spacerView)
        sortOptionStackView.addArrangedSubview(sortByNameButton)
        sortOptionStackView.addArrangedSubview(separator)
        sortOptionStackView.addArrangedSubview(sortBycreateButton)

        addSubview(sortOptionStackView)
        addSubview(audioTrackSearchTextField)
        addSubview(searchingResultLabel)
        addSubview(audioTrackTableView)
    }

    private func setupConstraints() {
        trackSearchTextFieldHeightConstraint = audioTrackSearchTextField.heightAnchor.constraint(equalToConstant: 0)
        searchingResultLabelHeightConstraint = searchingResultLabel.heightAnchor.constraint(equalToConstant: 0)
        audioTrackTableViewTopConstraint =
            audioTrackTableView
            .topAnchor.constraint(equalTo: searchingResultLabel.bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            audioComponentToolBarStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            audioComponentToolBarStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            audioComponentToolBarStackView.topAnchor.constraint(equalTo: topAnchor),

            sortOptionStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sortOptionStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sortOptionStackView.topAnchor.constraint(equalTo: audioComponentToolBarStackView.bottomAnchor),

            audioTrackSearchTextField.topAnchor.constraint(equalTo: sortOptionStackView.bottomAnchor, constant: 10),
            audioTrackSearchTextField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            audioTrackSearchTextField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            trackSearchTextFieldHeightConstraint!,

            searchingResultLabel.topAnchor.constraint(equalTo: audioTrackSearchTextField.bottomAnchor, constant: 10),
            searchingResultLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            searchingResultLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            searchingResultLabelHeightConstraint!,

            audioTrackTableViewTopConstraint!,
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
	
	private func setupAction() {
		audioAddButton.addAction(
			UIAction { [weak self] _ in
				guard let self else { return }
				let audioDownloadPopupView = AudioDownloadPopupView()
				downloadAudioActionSubscription = audioDownloadPopupView
					.downloadButtonActionPublisher
					.sink { [weak self] code in
						self?.audioDownloadStatePopupView = AudioDownloadStatePopupView()
						self?.audioDownloadStatePopupView?.show()
						self?.dispatcher?.downloadMusics(with: code)
						self?.downloadAudioActionSubscription = nil
					}
				audioDownloadPopupView.show()
			}, for: .touchUpInside)

		audioAddFromFileSystemButton.addAction(
			UIAction { [weak self] _ in
				guard let self else { return }

				let supportedTypes: [UTType] = [.audio, .mp3, .wav]
				let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)

				documentPicker.delegate = self
				documentPicker.allowsMultipleSelection = true
				parentViewController?.present(documentPicker, animated: true)
			}, for: .touchUpInside)

		audioSearchButton.addAction(
			UIAction { [weak self] _ in
				guard let self else { return }
				isVisibleAudioSearchTextView.toggle()
			}, for: .touchUpInside)

		audioTrackSearchTextField.addTarget(
			self,
			action: #selector(handleTitleTextFieldChange),
			for: .editingChanged)

		sortByNameButton.addAction(
			UIAction { [weak self] _ in
				guard let self else { return }
				sortBycreateButton.setTitleColor(.gray, for: .normal)
				sortByNameButton.setTitleColor(.label, for: .normal)
				dispatcher?.changeSortByAudioTracks(sortBy: .name)
			}, for: .touchUpInside)

		sortBycreateButton.addAction(
			UIAction { [weak self] _ in
				guard let self else { return }
				sortByNameButton.setTitleColor(.gray, for: .normal)
				sortBycreateButton.setTitleColor(.label, for: .normal)
				dispatcher?.changeSortByAudioTracks(sortBy: .createDate)
			}, for: .touchUpInside)
	}

    private func reloadAudioContentsTableView() {
        UIView.animate(
            withDuration: 0.15,
            animations: {
                self.audioTrackTableView.alpha = 0
            },
            completion: { _ in
                self.audioTrackTableView.reloadData()
                UIView.animate(
                    withDuration: 0.15,
                    animations: {
                        self.audioTrackTableView.alpha = 1
                    }
                )
            }
        )
    }

    @objc private func handleTitleTextFieldChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let text = audioTrackSearchTextField.text {
                let keyword = text.trimmingCharacters(in: .whitespacesAndNewlines)
                audioComponentDataSource?.searchingKeywoard = keyword
                if let count = self.audioComponentDataSource?.numberOfVisibleRows() {
                    self.searchingResultLabel.alpha = 1
                    self.searchingResultLabel.text = "Found \(count) results"
                } else {
                    self.searchingResultLabel.alpha = 0
                }
                reloadAudioContentsTableView()
            }
        }
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

    func configure(
        audioComponent: AudioComponent,
        dispatcher: AudioComponentActionDispatcher,
        isComponent: Bool = false
    ) {
        self.dispatcher = dispatcher

        self.audioTrackTableView.delegate = self
        self.audioTrackTableView.dragDelegate = self
        self.audioTrackTableView.dropDelegate = self
        self.audioTrackTableView.isPrefetchingEnabled = false
        audioComponentDataSource = AudioComponentDataSource(audioPageComponent: audioComponent)
        audioTrackTableView.dataSource = audioComponentDataSource

        self.audioTrackTotal = audioComponent.componentContents.tracks.count
        totalAudioCountLabel.text = "\(audioTrackTotal) audios in total"

        switch audioComponent.componentContents.sortBy {
            case .name:
                sortByNameButton.setTitleColor(.label, for: .normal)

            case .createDate:
                sortBycreateButton.setTitleColor(.label, for: .normal)

            case .manual:
                break
        }

        if isComponent {
            let isFolding = audioComponent.isMinimumHeight
            self.alpha = isFolding ? 0 : 1
            self.toolBarStackViewHeightConstraint?.constant = isFolding ? 0 : 45
            self.sortOptionStackViewHeightConstraint?.constant = isFolding ? 0 : 30
            self.addbuttonHeightConstraint?.constant = isFolding ? 0 : 44
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        dispatcher?.importAudioFilesFromFileSystem(urls: urls)
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        audioComponentDataSource?.shouldDisplayRow(indexPath: indexPath) == true ? 65 : 0
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 65 }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
        -> UISwipeActionsConfiguration?
    {
        let editAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            dispatcher?.presentAudioMetaDataEditingPopupView(trackIndex: indexPath.row)
            completionHandler(true)
        }
        editAction.image = UIImage(systemName: "square.and.pencil")
        editAction.backgroundColor = .systemBlue

        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            dispatcher?.removeAudioTrack(trackIndex: indexPath.row)
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash")

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, editAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let audioTrackRow = tableView.cellForRow(at: indexPath) as? AudioTableRowView {
            if audioTrackRow.isHighlighted {
                dispatcher?.playAudioTrack(with: indexPath.row)
            } else {
                audioTrackRow.setHighlighting(true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    audioTrackRow.setHighlighting(false)
                    tableView.deselectRow(at: indexPath, animated: true)
                }
            }
        }
        return indexPath
    }

    func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) { (cell as? AudioTableRowView)?.audioVisualizer.removeVisuzlization() }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let text = audioTrackSearchTextField.text,
            text.trimmingCharacters(in: .whitespacesAndNewlines) == "",
            isVisibleAudioSearchTextView
        {
            isVisibleAudioSearchTextView.toggle()
        }
    }
}

extension AudioComponentContentView: UITableViewDragDelegate {
    func tableView(
        _ tableView: UITableView,
        itemsForBeginning session: any UIDragSession,
        at indexPath: IndexPath
    ) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = indexPath.row
        return [dragItem]
    }
}

extension AudioComponentContentView: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

        if let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath {
            let fromIndex = sourceIndexPath.row
            let toIndex = destinationIndexPath.row

            dispatcher?.moveAudioTrackOrder(src: fromIndex, des: toIndex)

            tableView.performBatchUpdates { tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath) }

            coordinator.drop(
                item.dragItem,
                toRowAt: IndexPath(item: max(0, destinationIndexPath.item), section: destinationIndexPath.section)
            )

            sortBycreateButton.setTitleColor(.gray, for: .normal)
            sortByNameButton.setTitleColor(.gray, for: .normal)
        }
    }

    func tableView(
        _ tableView: UITableView,
        dropSessionDidUpdate session: any UIDropSession,
        withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UITableViewDropProposal {
        if session.localDragSession != nil {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        } else {
            return UITableViewDropProposal(operation: .cancel)
        }
    }
}
