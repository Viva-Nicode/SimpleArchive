import AVFAudio
import Combine
import MediaPlayer
import UIKit

class MemoPageViewController: UIViewController, ViewControllerType {
    typealias Input = MemoPageViewInput
    typealias ViewModelType = MemoPageViewModel

    var input = PassthroughSubject<MemoPageViewInput, Never>()
    var viewModel: MemoPageViewModel
    var subscriptions = Set<AnyCancellable>()

    var selectedPageComponentCell: (any PageComponentViewType)?
    var pageComponentContentViewRect: CGRect?

    private var audioControlBar = AudioControlBarView()

    var selectedComponentIndexForMoveSnapshotView: Int?

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
    private(set) var collectionView: UICollectionView!

    init(viewModel: MemoPageViewModel) {
        self.viewModel = viewModel
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

    deinit { print("deinit MemoPageViewController") }

    override func viewDidLoad() {
        super.viewDidLoad()

        let dynamicHeightFlowLayout = ComponentsPageCollectionViewLayout()

        dynamicHeightFlowLayout.delegate = viewModel
        dynamicHeightFlowLayout.scrollDirection = .vertical
        dynamicHeightFlowLayout.minimumLineSpacing = UIConstants.memoPageViewControllerCollectionViewCellSpacing

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: dynamicHeightFlowLayout)

        collectionView.backgroundColor = .clear
        collectionView.isPrefetchingEnabled = false
        collectionView.keyboardDismissMode = .onDrag

        collectionView.register(
            TextEditorComponentView.self,
            forCellWithReuseIdentifier: TextEditorComponentView.identifierForUseCollectionView)
        collectionView.register(
            TableComponentView.self,
            forCellWithReuseIdentifier: TableComponentView.reuseTableComponentIdentifier)
        collectionView.register(
            AudioComponentView.self,
            forCellWithReuseIdentifier: AudioComponentView.reuseAudioComponentIdentifier)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.collectionView = collectionView
        bind()
        input.send(.viewDidLoad)
    }

    func bind() {
        let output = viewModel.subscribe(input: input.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .viewDidLoad(let pageName):
                    setupUI(pageName: pageName)
                    setupConstraints()

                case .didAppendComponentAt(let index):
                    collectionView.insertItems(at: [IndexPath(item: index, section: 0)])
                    collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .top, animated: true)

                case .didRemoveComponentAt(let index):
                    collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])

                case .didToggleComponentSize(let componentIndexMinimized, let isMinimize):
                    updateComponentHeight(componentIndexMinimized: componentIndexMinimized, isMinimize: isMinimize)

                case .didMaximizeComponent(let component, let index):
                    presentComponentFullScreen(with: component, index: index)

                case .didNavigateSnapshotView(let vm, let itemIndex):
                    let snapshotView = ComponentSnapshotViewController(viewModel: vm)

                    snapshotView.hasRestorePublisher
                        .sink { [weak self] _ in
                            guard let self else { return }
                            if let selectedComponentIndexForMoveSnapshotView {
                                let indexPath = IndexPath(item: selectedComponentIndexForMoveSnapshotView, section: 0)
                                collectionView.reloadItems(at: [indexPath])
                            }
                        }
                        .store(in: &subscriptions)

                    selectedComponentIndexForMoveSnapshotView = itemIndex
                    navigationController?.pushViewController(snapshotView, animated: true)

                case .didCompleteComponentCapture(let componentIndex):
                    let indexPath = IndexPath(item: componentIndex, section: 0)
                    if let cell = collectionView.cellForItem(at: indexPath),
                        let captureableComponentView = cell as? CaptureableComponentView
                    {
                        captureableComponentView.completeSnapshotCapturePopupView()
                    }

                // MARK: - Table

                case .didAppendRowToTableView(let componentIndex, let row):
                    performWithComponentViewAt(componentIndex) { (_: TableComponentView, contentView) in
                        contentView.appendEmptyRowToStackView(rowID: row.id)
                    }

                case .didAppendColumnToTableView(let componentIndex, let column):
                    performWithComponentViewAt(componentIndex) { (_: TableComponentView, contentView) in
                        contentView.appendEmptyColumnToStackView(column: column)
                    }

                case let .didApplyTableCellValueChanges(componentIndex, rowIndex, colIndex, newCellValue):
                    performWithComponentViewAt(componentIndex) { (_: TableComponentView, contentView) in
                        contentView.updateUILabelText(rowIndex: rowIndex, cellIndex: colIndex, with: newCellValue)
                    }

                case .didRemoveRowToTableView(let componentIndex, let removedRowIndex):
                    performWithComponentViewAt(componentIndex) { (_: TableComponentView, contentView) in
                        contentView.removeTableComponentRowView(idx: removedRowIndex)
                    }

                case .didApplyTableColumnChanges(let componentIndex, let columns):
                    performWithComponentViewAt(componentIndex) { (_: TableComponentView, contentView) in
                        contentView.applyColumns(columns: columns)
                    }

                case .didPresentTableColumnEditPopupView(let columns, let tappedColumnIndex, let componentID):
                    let tableComponentColumnEditPopupView = TableComponentColumnEditPopupView(
                        columns: columns, tappedColumnIndex: tappedColumnIndex)

                    tableComponentColumnEditPopupView.confirmButtonPublisher
                        .sink { [weak self] colums in
                            self?.input.send(.willApplyTableColumnChanges(componentID, colums))
                        }
                        .store(in: &subscriptions)

                    tableComponentColumnEditPopupView.show()

                // MARK: - Audio

                case .didAppendAudioTrackRows(let componentIndex, let appendedTrackIndices):
                    appendNewAudioTracks(componentIndex: componentIndex, appendedTrackIndices: appendedTrackIndices)

                case .didPresentInvalidDownloadCode(let componentIndex):
                    presentInvalidDownloadCodePopupView(componentIndex: componentIndex)

                case let .didPlayAudioTrack(
                    previousComponentIndex, componentIndex, trackIndex, duration, metadata, sampleData):
                    playAudioTrack(
                        previousComponentIndex: previousComponentIndex,
                        componentIndex: componentIndex,
                        trackIndex: trackIndex,
                        duration: duration,
                        audioMetadata: metadata,
                        audioSampleData: sampleData)

                case let .didApplyAudioMetadataChanges(
                    componentIndex, trackIndex, editedMetadata, isNowPlayingTrack, trackIndexAfterEdit):
                    applyAudioTrackMetadataChanges(
                        componentIndex: componentIndex,
                        targetTrackIndex: trackIndex,
                        metadata: editedMetadata,
                        isNowPlayingTrack: isNowPlayingTrack,
                        trackIndexAfterEditing: trackIndexAfterEdit)

                case .didUpdateAudioDownloadProgress(let componentIndex, let progress):
                    updateAudioDownloadProgress(componentIndex: componentIndex, progress: progress)

                case let .didToggleAudioPlayingState(componentIndex, trackIndex, isPlaying):
                    setAudioPlayingState(
                        componentIndex: componentIndex,
                        trackIndex: trackIndex,
                        isPlaying: isPlaying)

                case let .didSeekAudioTrack(componentIndex, trackIndex, seek, totalTime):
                    performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
                        let indexPath = IndexPath(row: trackIndex, section: 0)
                        if let row = contentView.audioTrackTableView.cellForRow(at: indexPath),
                            let audioRow = row as? AudioTableRowView
                        {
                            audioRow.audioVisualizer.seekVisuzlization(rate: seek / totalTime!)
                        }
                    }
                    audioControlBar.seek(seek: seek)

                case .didSortAudioTracks(let componentIndex, let before, let after):
                    sortAudioTracks(componentIndex: componentIndex, before: before, after: after)

                case .didRemoveAudioTrack(let componentIndex, let trackIndex):
                    removeAudioTrack(componentIndex: componentIndex, trackIndex: trackIndex)

                case let .didRemoveAudioTrackAndPlayNextAudio(
                    componentIndex, trackIndex, nextIndex, duration, audioMetadata, audioSampleData):
                    removeAudioTrackAndPlayNextAudio(
                        componentIndex: componentIndex,
                        removeAudioRowIndex: trackIndex,
                        nextPlayingAudioRowIndex: nextIndex,
                        duration: duration,
                        audioMetadata: audioMetadata,
                        audioSampleData: audioSampleData
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

        backgroundView.addArrangedSubview(collectionView)

        collectionView.dataSource = viewModel

        collectionView.dropDelegate = self
        collectionView.dragDelegate = self
        collectionView.delegate = self

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

            collectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),

            audioControlBar.widthAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewWidth),
            audioControlBar.heightAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewHeight),
            audioControlBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            audioControlBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
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

        for item in 0..<collectionView.numberOfItems(inSection: .zero) {
            let indexPath = IndexPath(item: item, section: .zero)
            if let cell = collectionView.cellForItem(at: indexPath) as? TextEditorComponentView {
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
                self.collectionView.contentInset.bottom = keyboardHeight
                if let targetIndexPath, keyboardHeight != .zero {
                    self.collectionView.scrollToItem(at: targetIndexPath, at: .bottom, animated: true)
                }
            }
        )
    }

    private func updateComponentHeight(componentIndexMinimized: Int, isMinimize: Bool) {
        let path = IndexPath(item: componentIndexMinimized, section: .zero)
        if let cell = collectionView.cellForItem(at: path),
            let pageComponentView = cell as? (any PageComponentViewType)
        {
            if isMinimize {
                pageComponentView.setMinimizeState(isMinimize)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    UIView.animate(withDuration: 0.3) {
                        self?.collectionView.collectionViewLayout.invalidateLayout()
                    }
                }
            } else {
                collectionView.performBatchUpdates {
                    collectionView.collectionViewLayout.invalidateLayout()
                } completion: { _ in
                    UIView.animate(withDuration: 0.3) {
                        pageComponentView.setMinimizeState(isMinimize)
                    }
                }
            }
        }
    }

    private func presentComponentFullScreen(with targetComponent: any PageComponent, index: Int) {

        selectedPageComponentCell =
            collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? (any PageComponentViewType)

        switch targetComponent {
            case let textEditorComponent as TextEditorComponent:

                let contentView = selectedPageComponentCell!.getContentView() as! UITextView
                pageComponentContentViewRect = contentView.convert(contentView.bounds, to: self.view.window!)

                let fullscreenComponentViewController = FullScreenTextEditorComponentViewController(
                    textEditorComponentModel: textEditorComponent,
                    componentTextView: contentView
                )
                fullscreenComponentViewController.modalPresentationStyle = .fullScreen
                fullscreenComponentViewController.transitioningDelegate = self

                present(fullscreenComponentViewController, animated: true)

            case let tableComponent as TableComponent:

                let contentView = selectedPageComponentCell!.getContentView() as! TableComponentContentView
                pageComponentContentViewRect = contentView.convert(contentView.bounds, to: self.view.window!)

                let fullScreenTableComponentViewController = FullScreenTableComponentViewController(
                    tableComponent: tableComponent,
                    tableComponentContentView: contentView
                )
                fullScreenTableComponentViewController.modalPresentationStyle = .fullScreen
                fullScreenTableComponentViewController.transitioningDelegate = self

                present(fullScreenTableComponentViewController, animated: true)

            case let audioComponent as AudioComponent:
                let contentView = selectedPageComponentCell!.getContentView() as! AudioComponentContentView

                pageComponentContentViewRect = contentView.convert(contentView.bounds, to: self.view.window!)

                let fullScreenAudioComponentViewController = FullScreenAudioComponentViewController(
                    audioComponent: audioComponent,
                    audioComponentContentView: contentView
                )
                fullScreenAudioComponentViewController.modalPresentationStyle = .fullScreen
                fullScreenAudioComponentViewController.transitioningDelegate = self

                present(fullScreenAudioComponentViewController, animated: true)

            default:
                break
        }
    }

    private func presentCreatingNewComponentView() {
        let createNewComponentView = CreateNewComponentView()

        createNewComponentView.componentTypePublisher
            .sink { [weak self] componentType in
                self?.input.send(.willCreateNewComponent(componentType))
            }
            .store(in: &subscriptions)

        if let sheet = createNewComponentView.sheetPresentationController {
            sheet.detents = [.medium()]
        }

        present(createNewComponentView, animated: true)
    }

    private func performWithComponentViewAt<ViewType: PageComponentViewType>(
        _ index: Int, task: (ViewType, ViewType.T) -> Void
    ) {
        let indexPath = IndexPath(item: index, section: .zero)
        if let cell = collectionView.cellForItem(at: indexPath) as? ViewType {
            task(cell, cell.getContentView())
        }
    }
}

extension MemoPageViewController: NavigationViewControllerDismissible {
    func onDismiss() {
        input.send(.viewWillDisappear)
        subscriptions.removeAll()
    }
}

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
        previousComponentIndex: Int?,
        componentIndex: Int,
        trackIndex: Int,
        duration: TimeInterval?,
        audioMetadata: AudioTrackMetadata,
        audioSampleData: AudioSampleData?
    ) {
        if let previousComponentIndex {
            performWithComponentViewAt(previousComponentIndex) { (_: AudioComponentView, contentView) in
                contentView
                    .audioTrackTableView
                    .visibleCells
                    .map { $0 as! AudioTableRowView }
                    .forEach { $0.audioVisualizer.removeVisuzlization() }
            }
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
                if let audioSampleData {
                    targetPlayingAudioRow.audioVisualizer.activateAudioVisualizer(
                        samplesCount: audioSampleData.sampleDataCount,
                        scaledSamples: audioSampleData.scaledSampleData,
                        sampleRate: audioSampleData.sampleRate)
                }
            }
        }

        audioControlBar.isHidden = false

        audioControlBar.state = .play(
            metadata: audioMetadata,
            duration: duration,
            dispatcher: MemoPageAudioComponentActionDispatcher(subject: input))
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
            if let row = contentView.audioTrackTableView.cellForRow(
                at: IndexPath(row: trackIndex, section: .zero)),
                let audioRow = row as? AudioTableRowView
            {
                if isPlaying {
                    audioRow.audioVisualizer.restartVisuzlization()
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
        audioSampleData: AudioSampleData?
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
                if let audioSampleData {
                    targetPlayingAudioRow.audioVisualizer.activateAudioVisualizer(
                        samplesCount: audioSampleData.sampleDataCount,
                        scaledSamples: audioSampleData.scaledSampleData,
                        sampleRate: audioSampleData.sampleRate)
                }
            }
        }

        audioControlBar.isHidden = false

        audioControlBar.state = .play(
            metadata: audioMetadata,
            duration: duration,
            dispatcher: MemoPageAudioComponentActionDispatcher(subject: input))
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

protocol ComponentsPageCollectionViewLayoutDelegate: AnyObject {
    func collectionView(
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat
}

final class ComponentsPageCollectionViewLayout: UICollectionViewFlowLayout {

    weak var delegate: ComponentsPageCollectionViewLayoutDelegate?
    private var cache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.bounds.width - 40
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }
        collectionView.contentInset = UIEdgeInsets(
            top: UIConstants.memoPageViewControllerCollectionViewHeaderHeight,
            left: 0,
            bottom: UIConstants.memoPageViewControllerCollectionViewFooterHeight,
            right: 0)
        cache.removeAll()

        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        let availableWidth = contentWidth - sectionInset.left - sectionInset.right
        var yOffset: CGFloat = sectionInset.top

        for item in 0..<numberOfItems {
            let indexPath = IndexPath(item: item, section: 0)
            let itemHeight =
                delegate?.collectionView(heightForItemAt: indexPath, with: availableWidth)
                ?? itemSize.height

            let frame = CGRect(
                x: (collectionView.bounds.width - availableWidth) / 2,
                y: yOffset,
                width: availableWidth,
                height: itemHeight
            )

            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = frame

            cache.append(attributes)

            yOffset += itemHeight + minimumLineSpacing
            contentHeight = max(contentHeight, frame.maxY + sectionInset.bottom)
        }
    }

    override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        cache.first { $0.representedElementKind == elementKind && $0.indexPath == indexPath }
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        cache.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        cache.first { $0.indexPath == indexPath }
    }
}
