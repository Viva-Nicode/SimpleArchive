import AVFAudio
import Combine
import MediaPlayer
import PhotosUI
import UIKit

class MemoPageViewController: UIViewController, ViewControllerType, ComponentSnapshotViewControllerDelegate {
    typealias Input = MemoPageViewInput
    typealias ViewModelType = MemoPageViewModel

    var input = PassthroughSubject<MemoPageViewInput, Never>()
    var viewModel: MemoPageViewModel
    var subscriptions = Set<AnyCancellable>()

    var thumbnail: UIImageView?

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
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private(set) var collectionView: UICollectionView!

    private let newComponentAddButton: UIButton = {
        let newComponentAddButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .regular)
        let buttonImage = UIImage(systemName: "macwindow.badge.plus", withConfiguration: config)

        newComponentAddButton.frame.origin.y = newComponentAddButton.frame.origin.y + 2

        newComponentAddButton.setImage(buttonImage, for: .normal)
        newComponentAddButton.tintColor = .label
        newComponentAddButton.translatesAutoresizingMaskIntoConstraints = false
        return newComponentAddButton
    }()

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

    deinit { print("MemoPageViewController deinit") }

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
                case .viewDidLoad(let pageName, let isReadOnly):
                    setupUI(pageName: pageName, isReadOnly: isReadOnly)
                    setupConstraints(isReadOnly: isReadOnly)

                case .insertNewComponentAtLastIndex(let index):
                    collectionView.insertItems(at: [IndexPath(item: index, section: 0)])
                    collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .top, animated: true)

                case .removeComponentAtIndex(let index):
                    collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])

                case .didMinimizeComponentHeight(let componentIndexMinimized, let isMinimize):
                    updateComponentHeight(componentIndexMinimized: componentIndexMinimized, isMinimize: isMinimize)

                case .maximizeComponent(let component, let index):
                    presentComponentFullScreen(with: component, index: index)

                case .didTappedSnapshotButton(let vm, let itemIndex):
                    let snapshotView = ComponentSnapshotViewController(viewModel: vm)

                    snapshotView.delegate = self
                    selectedComponentIndexForMoveSnapshotView = itemIndex
                    navigationController?.pushViewController(snapshotView, animated: true)

                // MARK: - Table

                case .didAppendTableComponentRow(let componentIndex, let row):
                    performWithComponentViewAt(componentIndex) { (_: TableComponentView, contentView) in
                        contentView.appendRowToRowStackView(row: row)
                    }

                case .didAppendTableComponentColumn(let componentIndex, let column):
                    performWithComponentViewAt(componentIndex) { (_: TableComponentView, contentView) in
                        contentView.appendColumnToColumnStackView(column)
                    }

                case .didEditTableComponentCellValue(let componentIndex, let rowIndex, let cellIndex, let newCellValue):
                    performWithComponentViewAt(componentIndex) { (_: TableComponentView, contentView) in
                        contentView.updateUILabelText(rowIndex: rowIndex, cellIndex: cellIndex, with: newCellValue)
                    }

                case .didRemoveTableComponentRow(let componentIndex, let removedRowIndex):
                    performWithComponentViewAt(componentIndex) { (_: TableComponentView, contentView) in
                        contentView.removeTableComponentRowView(idx: removedRowIndex)
                    }

                case .didEditTableComponentColumn(let componentIndex, let columns):
                    performWithComponentViewAt(componentIndex) { (_: TableComponentView, contentView) in
                        contentView.applyColumns(columns: columns)
                    }

                case .didPresentTableComponentColumnEditPopupView(let columns, let tappedColumnIndex, let componentID):
                    let tableComponentColumnEditPopupView = TableComponentColumnEditPopupView(
                        columns: columns, tappedColumnIndex: tappedColumnIndex)

                    tableComponentColumnEditPopupView.confirmButtonPublisher
                        .sink { colums in
                            self.input.send(.editTableComponentColumn(componentID, colums))
                        }
                        .store(in: &subscriptions)
                    tableComponentColumnEditPopupView.show()

                // MARK: - Audio

                case .didDownloadMusicWithCode(let componentIndex, let appendedTrackIndices):
                    appendNewAudioTracks(componentIndex: componentIndex, appendedTrackIndices: appendedTrackIndices)

                case .presentInvalidDownloadCode(let componentIndex):
                    presentInvalidDownloadCodePopupView(componentIndex: componentIndex)

                case let .didPlayAudioTrack(
                    previousComponentIndex, componentIndex, audioTrackURL, trackIndex, duration, metadata, sampleData):
                    playAudioTrack(
                        previousComponentIndex: previousComponentIndex,
                        componentIndex: componentIndex,
                        audioTrackURL: audioTrackURL,
                        trackIndex: trackIndex,
                        duration: duration,
                        audioMetadata: metadata,
                        audioSampleData: sampleData)

                case .didPresentGallery(let imageView):
                    thumbnail = imageView
                    presentPhotoGallery()

                case let .didEditAudioTrackMetadata(
                    componentIndex, trackIndex, editedMetadata, isNowPlayingTrack, trackIndexAfterEdit):
                    editAudioTrackMetadata(
                        componentIndex, trackIndex, editedMetadata, isNowPlayingTrack, trackIndexAfterEdit)

                case .updateAudioDownloadProgress(let componentIndex, let progress):
                    updateAudioDownloadProgress(componentIndex: componentIndex, progress: progress)

                case let .didTapPlayPauseButton(componentIndex, trackIndex, isPlaying, currentTime):
                    tapPlayPauseButton(
                        componentIndex: componentIndex,
                        trackIndex: trackIndex,
                        isPlaying: isPlaying,
                        currentTime: currentTime)

                case let .didSeekAudioTrack(componentIndex, trackIndex, seek, totalTime):
                    performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
                        if let row = contentView.audioTrackTableView.cellForRow(at: .init(row: trackIndex, section: 0)),
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

                case .outOfSongs(let componentIndex):
                    audioControlBar.updateControlBarStateToNotPlaying()
                    performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
                        contentView
                            .audioTrackTableView
                            .visibleCells
                            .map { $0 as! AudioTableRowView }
                            .forEach { $0.audioVisualizer.removeVisuzlization() }
                    }

                case .didPresentFilePicker:
                    presentFilePicker()
            }
        }
        .store(in: &subscriptions)
    }

    private func presentFilePicker() {
        let supportedTypes: [UTType] = [.audio, .mp3, .wav]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)

        documentPicker.delegate = viewModel
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true)
    }

    private func setupUI(pageName: String, isReadOnly: Bool) {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backButton.addAction(
            UIAction { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }, for: .touchUpInside)

        titleLable.text = pageName

        if !isReadOnly {
            headerView.addSubview(newComponentAddButton)

            newComponentAddButton.throttleTapPublisher()
                .sink { _ in self.presentCreatingNewComponentView() }
                .store(in: &subscriptions)
        }

        view.addSubview(headerView)

        headerView.addSubview(backButton)
        headerView.addSubview(titleLable)

        backgroundView.addArrangedSubview(collectionView)

        collectionView.dataSource = viewModel

        collectionView.dropDelegate = self
        collectionView.dragDelegate = self
        collectionView.delegate = self

        view.addSubview(audioControlBar)
        audioControlBar.isHidden = true
    }

    private func setupConstraints(isReadOnly: Bool) {
        backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        headerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        backButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20).isActive = true
        backButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10).isActive = true

        if !isReadOnly {
            newComponentAddButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20)
                .isActive = true
            newComponentAddButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -5).isActive =
                true
        }

        titleLable.widthAnchor.constraint(equalTo: headerView.widthAnchor, multiplier: 0.6).isActive = true
        titleLable.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10).isActive = true
        titleLable.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true

        collectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor).isActive = true

        audioControlBar.widthAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewWidth).isActive = true
        audioControlBar.heightAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewHeight).isActive = true
        audioControlBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        audioControlBar.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

    func reloadCellForRestoredComponent() {
        if let selectedComponentIndexForMoveSnapshotView {
            let indexPath = IndexPath(item: selectedComponentIndexForMoveSnapshotView, section: 0)
            collectionView.reloadItems(at: [indexPath])
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
        createNewComponentView.delegate = self

        if let sheet = createNewComponentView.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
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

extension MemoPageViewController: CreateNewComponentViewDelegate {
    func createNewComponent(with: ComponentType) {
        input.send(.createNewComponent(with))
    }
}

extension MemoPageViewController: PHPickerViewControllerDelegate {

    func presentPhotoGallery() {
        var configuration = PHPickerConfiguration()

        configuration.selectionLimit = 1
        configuration.filter = .any(of: [.images])

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)

        let itemProvider = results.first?.itemProvider

        if let itemProvider = itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                DispatchQueue.main.async {
                    self.thumbnail?.image = (image as? UIImage)?.audioTrackThumbnailSquared
                }
            }
        }
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
        audioTrackURL: URL,
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

            audioControlBar.isHidden = false

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

        audioControlBar.configure(
            metadata: audioMetadata,
            duration: duration,
            dispatcher: MemoPageAudioComponentActionDispatcher(subject: input)
        )
    }

    private func editAudioTrackMetadata(
        _ componentIndex: Int,
        _ targetTrackIndex: Int,
        _ metadata: AudioTrackMetadata,
        _ isNowPlayingTrack: Bool,
        _ trackIndexAfterEditing: Int?
    ) {
        performWithComponentViewAt(componentIndex) { (_: AudioComponentView, contentView) in
            if let row = contentView.audioTrackTableView.cellForRow(at: .init(row: targetTrackIndex, section: .zero)),
                let audioTableRowView = row as? AudioTableRowView
            {
                audioTableRowView.update(metadata)
            }

            if isNowPlayingTrack {
                audioControlBar.update(with: metadata)
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

    private func tapPlayPauseButton(componentIndex: Int, trackIndex: Int, isPlaying: Bool, currentTime: TimeInterval?) {
        audioControlBar.setControlBarState(isPlaying: isPlaying, currentTime: currentTime)
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
