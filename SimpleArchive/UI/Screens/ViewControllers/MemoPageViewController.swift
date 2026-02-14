import AVFAudio
import Combine
import MediaPlayer
import UIKit

final class MemoPageViewController: UIViewController {

    var pageViewModel: MemoPageViewModel
    var pageActionDispatcher = PassthroughSubject<MemoPageViewInput, Never>()

    var subscriptions = Set<AnyCancellable>()
    var taskID: UIBackgroundTaskIdentifier = .invalid

    // MARK: - properties pageComponent fullScreen
    var fullscreenTargetComponentView: (any PageComponentViewType)?
    var fullscreenTargetComponentContentsViewFrame: CGRect?

    private var componentCollectionViewDataSource: MemoPageComponentCollectionViewDataSource?
    var snapshotCapturePopupView: SnapshotCapturePopupView?

    private let backgroundView: UIStackView = {
        let backgroundView = UIStackView()
        backgroundView.backgroundColor = .systemBackground
        backgroundView.axis = .vertical
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundView
    }()
    private let headerView: UIView = {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    private let backButton: UIButton = {
        let backButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let buttonImage = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(buttonImage, for: .normal)
        backButton.tintColor = .label
        backButton.translatesAutoresizingMaskIntoConstraints = false
        return backButton
    }()
    private let titleLable: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 23, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private let componentPlusButton: UIButton = {
        let componentPlusButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let buttonImage = UIImage(systemName: "plus", withConfiguration: config)
        componentPlusButton.setImage(buttonImage, for: .normal)
        componentPlusButton.tintColor = .label
        componentPlusButton.translatesAutoresizingMaskIntoConstraints = false
        return componentPlusButton
    }()

    private(set) var pageComponentCollectionView: UICollectionView!
    private var audioControlBar = AudioControlBarView()

    init(pageViewModel: MemoPageViewModel) {
        self.pageViewModel = pageViewModel

        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        let isfreedFromMemory = isMovingFromParent || isBeingDismissed

        if isfreedFromMemory {
            pageComponentCollectionView
                .visibleCells
                .compactMap { $0 as? (any PageComponentViewType) }
                .forEach { $0.freedReferences() }
            componentCollectionViewDataSource?.freedDataSource()
            componentCollectionViewDataSource = nil
            subscriptions.removeAll()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let dynamicHeightFlowLayout = ComponentsPageCollectionViewLayout()

        dynamicHeightFlowLayout.delegate = pageViewModel
        dynamicHeightFlowLayout.scrollDirection = .vertical
        dynamicHeightFlowLayout.minimumLineSpacing = UIConstants.memoPageViewControllerCollectionViewCellSpacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: dynamicHeightFlowLayout)

        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .onDrag
        collectionView.isPrefetchingEnabled = false

        collectionView.register(
            TextEditorComponentView.self,
            forCellWithReuseIdentifier: TextEditorComponentView.reuseIdentifier)
        collectionView.register(
            TableComponentView.self,
            forCellWithReuseIdentifier: TableComponentView.reuseIdentifier)
        collectionView.register(
            AudioComponentView.self,
            forCellWithReuseIdentifier: AudioComponentView.reuseAudioComponentIdentifier)

        collectionView.translatesAutoresizingMaskIntoConstraints = false

        pageComponentCollectionView = collectionView
        bindToMemoPageVM()
        pageActionDispatcher.send(.viewDidLoad)
    }

    func bindToMemoPageVM() {
        let output = pageViewModel.subscribe(input: pageActionDispatcher.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .viewDidLoad(let memoPageData, let audioContentsData):
                    let factory = PageComponentCollectionViewCellFactory(
                        collectionView: pageComponentCollectionView,
                        input: pageActionDispatcher,
                        audioContentsDataContainer: audioContentsData)

                    componentCollectionViewDataSource = MemoPageComponentCollectionViewDataSource(
                        pageComponentViewFactory: factory,
                        memoPage: memoPageData)

                    setupUI(pageName: memoPageData.name)
                    setupConstraints()

                case .didAppendComponentAt(let index):
                    appendNewComponentView(index: index)

                case .didRemovePageComponent(let componentIndex):
                    removePageComponent(componentIndex: componentIndex)

                case .didRenameComponent(let componentIndex, let newName):
                    renamePageComponent(componentIndex: componentIndex, newName: newName)

                case .didToggleFoldingComponent(let componentIndex, let isMinimized):
                    toggleComponentFolding(componentIndex: componentIndex, isMinimized: isMinimized)

                case .didMaximizePageComponent(let componentIndex):
                    presentComponentFullScreen(componentIndex: componentIndex)

                // MARK: - Audio
                case .didAppendAudioTrackRows(let componentIndex, let appendedTrackIndices):
                    appendNewAudioTracks(componentIndex: componentIndex, appendedTrackIndices: appendedTrackIndices)

                case .didPresentInvalidDownloadCode(let componentIndex):
                    presentInvalidDownloadCodePopupView(componentIndex: componentIndex)

                case .didPlayAudioTrack(
                    let componentIndex, let trackIndex, let duration, let metadata, let waveformData):
                    playAudioTrack(
                        componentIndex: componentIndex,
                        trackIndex: trackIndex,
                        duration: duration,
                        audioMetadata: metadata,
                        audioWaveformData: waveformData)

                case .didApplyAudioMetadataChanges(
                    let
                        componentIndex, let trackIndex, let editedMetadata, let isNowPlayingTrack,
                    let trackIndexAfterEdit):
                    applyAudioTrackMetadataChanges(
                        componentIndex: componentIndex,
                        targetTrackIndex: trackIndex,
                        metadata: editedMetadata,
                        isNowPlayingTrack: isNowPlayingTrack,
                        trackIndexAfterEditing: trackIndexAfterEdit)

                case .didUpdateAudioDownloadProgress(let componentIndex, let progress):
                    updateAudioDownloadProgress(componentIndex: componentIndex, progress: progress)

                case .didToggleAudioPlayingState(let componentIndex, let trackIndex, let isPlaying):
                    setAudioPlayingState(
                        componentIndex: componentIndex,
                        trackIndex: trackIndex,
                        isPlaying: isPlaying)

                case .didSeekAudioTrack(let componentIndex, let trackIndex, let seek, let total):
                    performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
                        let indexPath = IndexPath(row: trackIndex, section: 0)
                        if let row = contentView.audioTrackTableView.cellForRow(at: indexPath),
                            let audioRow = row as? AudioTableRowView
                        {
                            audioRow.audioVisualizer.seekVisuzlization(rate: seek / total)
                            self.audioControlBar.seek(seek: seek)
                        }
                    }

                case .didSortAudioTracks(let componentIndex, let before, let after):
                    sortAudioTracks(componentIndex: componentIndex, before: before, after: after)

                case .didRemoveAudioTrack(let componentIndex, let trackIndex):
                    removeAudioTrack(componentIndex: componentIndex, trackIndex: trackIndex)

                case .didRemoveAudioTrackAndPlayNextAudio(
                    let componentIndex, let trackIndex, let nextIndex, let duration, let audioMetadata, let waveformData
                ):
                    removeAudioTrackAndPlayNextAudio(
                        componentIndex: componentIndex,
                        removeAudioRowIndex: trackIndex,
                        nextPlayingAudioRowIndex: nextIndex,
                        duration: duration,
                        audioMetadata: audioMetadata,
                        audioWaveformData: waveformData
                    )

                case .didRemoveAudioTrackAndStopPlaying(let componentIndex, let trackIndex):
                    removeAudioTrackAndStopPlaying(componentIndex: componentIndex, trackIndex: trackIndex)
            }
        }
        .store(in: &subscriptions)
    }

    private func setupUI(pageName: String) {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backButton.addAction(
            UIAction { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }, for: .touchUpInside)

        titleLable.text = pageName

        componentPlusButton.throttleTapPublisher()
            .sink { _ in self.presentCreatingNewComponentView() }
            .store(in: &subscriptions)

        view.addSubview(headerView)

        headerView.addSubview(backButton)
        headerView.addSubview(titleLable)
        headerView.addSubview(componentPlusButton)

        backgroundView.addArrangedSubview(pageComponentCollectionView)

        pageComponentCollectionView.dataSource = componentCollectionViewDataSource
        pageComponentCollectionView.dropDelegate = self
        pageComponentCollectionView.dragDelegate = self
        pageComponentCollectionView.delegate = self

        view.addSubview(audioControlBar)
        audioControlBar.isHidden = true
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.heightAnchor.constraint(equalToConstant: 50),
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),

            titleLable.heightAnchor.constraint(equalToConstant: 50),
            titleLable.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLable.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            componentPlusButton.widthAnchor.constraint(equalToConstant: 50),
            componentPlusButton.heightAnchor.constraint(equalToConstant: 50),
            componentPlusButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),

            pageComponentCollectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            pageComponentCollectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),

            audioControlBar.widthAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewWidth),
            audioControlBar.heightAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewHeight),
            audioControlBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            audioControlBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func appendNewComponentView(index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        pageComponentCollectionView.insertItems(at: [indexPath])
        pageComponentCollectionView.scrollToItem(at: indexPath, at: .top, animated: true)
    }

    private func renamePageComponent(componentIndex: Int, newName: String) {
        let indexPath = IndexPath(item: componentIndex, section: 0)
        if let cell = pageComponentCollectionView.cellForItem(at: indexPath),
            let pageComponentView = cell as? (any PageComponentViewType)
        {
            pageComponentView.titleLabel.text = newName
        }
    }

    private func removePageComponent(componentIndex: Int) {
        let indexPath = IndexPath(item: componentIndex, section: 0)
        pageComponentCollectionView.deleteItems(at: [indexPath])
    }

    private func presentCreatingNewComponentView() {
        let createNewComponentView = CreateNewComponentView()

        createNewComponentView.componentTypePublisher
            .sink { [weak self] componentType in
                guard let self else { return }
                pageActionDispatcher.send(.willCreateNewComponent(componentType))
            }
            .store(in: &subscriptions)

        if let sheet = createNewComponentView.sheetPresentationController {
            sheet.detents = [.medium()]
        }

        present(createNewComponentView, animated: true)
    }

    private func toggleComponentFolding(componentIndex: Int, isMinimized: Bool) {
        let path = IndexPath(item: componentIndex, section: .zero)
        if let cell = pageComponentCollectionView.cellForItem(at: path),
            let pageComponentView = cell as? (any PageComponentViewType)
        {
            if isMinimized {
                pageComponentView.setMinimizeState(isMinimized)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    UIView.animate(withDuration: 0.3) {
                        self?.pageComponentCollectionView.collectionViewLayout.invalidateLayout()
                    }
                }
            } else {
                pageComponentCollectionView.performBatchUpdates {
                    pageComponentCollectionView.collectionViewLayout.invalidateLayout()
                } completion: { _ in
                    UIView.animate(withDuration: 0.3) {
                        pageComponentView.setMinimizeState(isMinimized)
                    }
                }
            }
        }
    }

    private func presentComponentFullScreen(componentIndex: Int) {
        let indexPath = IndexPath(item: componentIndex, section: 0)
        fullscreenTargetComponentView =
            pageComponentCollectionView.cellForItem(at: indexPath) as? (any PageComponentViewType)
        fullscreenTargetComponentView?.attachContentsSnapshotViewDuringPresentingFullScreenAnimation()
        fullscreenTargetComponentView?.presentFullScreenPageComponentView()
    }

    private func performWithComponentViewAt<ViewType: PageComponentViewType>(
        _ index: Int, task: (ViewType, ViewType.T) -> Void
    ) {
        let indexPath = IndexPath(item: index, section: .zero)
        if let cell = pageComponentCollectionView.cellForItem(at: indexPath) as? ViewType {
            task(cell, cell.getContentView())
        }
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let textView = UIResponder.current as? UITextView,
            textView.accessibilityIdentifier == "TextEditorComponentTextView"
        else { return }

        guard
            let userInfo = notification.userInfo,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        var targetIndexPath: IndexPath?

        for item in 0..<pageComponentCollectionView.numberOfItems(inSection: .zero) {
            let indexPath = IndexPath(item: item, section: .zero)
            if let cell = pageComponentCollectionView.cellForItem(at: indexPath) as? TextEditorComponentView {
                if cell.componentContentView == textView {
                    targetIndexPath = indexPath
                    break
                }
            }
        }

        let keyboardHeight = UIScreen.main.bounds.height - endFrame.origin.y
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: {
                self.pageComponentCollectionView.contentInset.bottom = keyboardHeight
                if let targetIndexPath, keyboardHeight != .zero {
                    self.pageComponentCollectionView.scrollToItem(at: targetIndexPath, at: .bottom, animated: true)
                }
            }
        )
    }
}

// MARK: - Audio
extension MemoPageViewController {
    private func appendNewAudioTracks(componentIndex: Int, appendedTrackIndices: [Int]) {
        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
            contentView
                .audioDownloadStatePopupView?
                .dismiss()
            contentView.insertRow(trackIndices: appendedTrackIndices)
        }
    }

    private func playAudioTrack(
        componentIndex: Int,
        trackIndex: Int,
        duration: TimeInterval?,
        audioMetadata: AudioTrackMetadata,
        audioWaveformData: AudioWaveformData?
    ) {
        pageComponentCollectionView
            .visibleCells
            .compactMap { $0 as? AudioComponentView }
            .forEach { acv in
                acv.componentContentView
                    .audioTrackTableView
                    .visibleCells
                    .map { $0 as! AudioTableRowView }
                    .forEach { $0.audioVisualizer.removeVisuzlization() }
            }

        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
            contentView
                .audioTrackTableView
                .visibleCells
                .map { $0 as! AudioTableRowView }
                .forEach { $0.audioVisualizer.removeVisuzlization() }

            let trackIndexPath = IndexPath(row: trackIndex, section: .zero)
            if let row = contentView.audioTrackTableView.cellForRow(at: trackIndexPath),
                let targetPlayingAudioRow = row as? AudioTableRowView
            {
                if let audioWaveformData {
                    targetPlayingAudioRow.audioVisualizer.activateAudioVisualizer(waveFormData: audioWaveformData)
                }
            }
        }

        audioControlBar.isHidden = false

        audioControlBar.state = .play(
            metadata: audioMetadata,
            duration: duration,
            dispatcher: MemoPageAudioComponentActionDispatcher(subject: pageActionDispatcher))
    }

    private func applyAudioTrackMetadataChanges(
        componentIndex: Int,
        targetTrackIndex: Int,
        metadata: AudioTrackMetadata,
        isNowPlayingTrack: Bool,
        trackIndexAfterEditing: Int?
    ) {
        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
            if let row = contentView.audioTrackTableView.cellForRow(at: .init(row: targetTrackIndex, section: .zero)),
                let audioTableRowView = row as? AudioTableRowView
            {
                audioTableRowView.updateAudioMetadata(metadata)
            }

            if isNowPlayingTrack {
                audioControlBar.applyUpdatedMetadata(with: metadata)
            }

            if let trackIndexAfterEditing {
                contentView.audioTrackTableView.performBatchUpdates {
                    let src = IndexPath(row: targetTrackIndex, section: .zero)
                    let des = IndexPath(row: trackIndexAfterEditing, section: .zero)
                    contentView.audioTrackTableView.moveRow(at: src, to: des)
                }
            }
        }
    }

    private func setAudioPlayingState(componentIndex: Int, trackIndex: Int, isPlaying: Bool) {
        audioControlBar.state = isPlaying ? .resume : .pause

        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
            let indexPath = IndexPath(row: trackIndex, section: .zero)
            if let row = contentView.audioTrackTableView.cellForRow(at: indexPath),
                let audioRow = row as? AudioTableRowView
            {
                if isPlaying {
                    audioRow.audioVisualizer.resumeVisuzlization()
                } else {
                    audioRow.audioVisualizer.pauseVisuzlization()
                }
            }
        }
    }

    private func sortAudioTracks(componentIndex: Int, before: [String], after: [String]) {
        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
            let audioTracks = contentView.audioTrackTableView
            audioTracks.performBatchUpdates {
                for (newIndex, item) in after.enumerated() {
                    if let oldIndex = before.firstIndex(of: item),
                        oldIndex != newIndex
                    {
                        let from = IndexPath(row: oldIndex, section: 0)
                        let to = IndexPath(row: newIndex, section: 0)

                        audioTracks.moveRow(at: from, to: to)
                    }
                }
            }
        }
    }

    private func removeAudioTrack(componentIndex: Int, trackIndex: Int) {
        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
            contentView.removeRow(trackIndex: trackIndex)
        }
    }

    private func removeAudioTrackAndPlayNextAudio(
        componentIndex: Int,
        removeAudioRowIndex: Int,
        nextPlayingAudioRowIndex: Int,
        duration: TimeInterval?,
        audioMetadata: AudioTrackMetadata,
        audioWaveformData: AudioWaveformData?
    ) {
        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in

            let removeTrackIndexPath = IndexPath(row: removeAudioRowIndex, section: .zero)
            if let row = contentView.audioTrackTableView.cellForRow(at: removeTrackIndexPath),
                let targetPlayingAudioRow = row as? AudioTableRowView
            {
                targetPlayingAudioRow.audioVisualizer.removeVisuzlization()
            }

            contentView.removeRow(trackIndex: removeAudioRowIndex)

            let trackIndexPath = IndexPath(row: nextPlayingAudioRowIndex, section: .zero)

            if let row = contentView.audioTrackTableView.cellForRow(at: trackIndexPath),
                let targetPlayingAudioRow = row as? AudioTableRowView
            {
                if let audioWaveformData {
                    targetPlayingAudioRow.audioVisualizer.activateAudioVisualizer(waveFormData: audioWaveformData)
                }
            }
        }

        audioControlBar.isHidden = false

        audioControlBar.state = .play(
            metadata: audioMetadata,
            duration: duration,
            dispatcher: MemoPageAudioComponentActionDispatcher(subject: pageActionDispatcher))
    }

    private func removeAudioTrackAndStopPlaying(componentIndex: Int, trackIndex: Int) {
        audioControlBar.state = .stop

        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in

            let removeTrackIndexPath = IndexPath(row: trackIndex, section: .zero)
            if let row = contentView.audioTrackTableView.cellForRow(at: removeTrackIndexPath),
                let targetPlayingAudioRow = row as? AudioTableRowView
            {
                targetPlayingAudioRow.audioVisualizer.removeVisuzlization()
            }

            contentView.removeRow(trackIndex: trackIndex)
        }
    }

    private func updateAudioDownloadProgress(componentIndex: Int, progress: Float) {
        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
            contentView
                .audioDownloadStatePopupView?
                .progress
                .setProgress(progress, animated: true)
        }
    }

    private func presentInvalidDownloadCodePopupView(componentIndex: Int) {
        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
            contentView
                .audioDownloadStatePopupView?
                .setStateToFail()
        }
    }
}
