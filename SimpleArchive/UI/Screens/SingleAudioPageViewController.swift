import Combine
import SFBAudioEngine
import UIKit

final class SingleAudioPageViewController: UIViewController, ViewControllerType {

    private(set) var titleLable: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private(set) var backgroundImageView: UIImageView = {
        let backgroundImageView = UIImageView()
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundImageView
    }()
    private(set) var backgroundImageWindow: UIView = {
        let backgroundImageWindow = UIView()
        backgroundImageWindow.alpha = 0
        backgroundImageWindow.translatesAutoresizingMaskIntoConstraints = false
        return backgroundImageWindow
    }()
    private(set) var audioComponentContentView: AudioComponentContentView = {
        let audioComponentContentView = AudioComponentContentView()
        audioComponentContentView.backgroundColor = .clear
        audioComponentContentView.translatesAutoresizingMaskIntoConstraints = false
        return audioComponentContentView
    }()

    typealias Input = SingleAudioPageInput
    typealias ViewModelType = SingleAudioPageViewModel

    var input = PassthroughSubject<SingleAudioPageInput, Never>()
    var viewModel: SingleAudioPageViewModel
    var subscriptions = Set<AnyCancellable>()

    private var audioControlBar = AudioControlBarView()

    override func viewDidLoad() {
        bind()
        input.send(.viewDidLoad)
    }

    init(viewModel: SingleAudioPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        print("deinit SingleAudioPageViewController")
    }

    func bind() {
        let output = viewModel.subscribe(input: input.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .viewDidLoad(let pageTitle, let audioComponent, let dataSource):
                    setupUI(pageTitle: pageTitle)
                    setupConstraints()
                    audioComponentContentView.configure(
                        trackCount: audioComponent.detail.tracks.count,
                        sortBy: audioComponent.detail.sortBy,
                        datasource: dataSource,
                        dispatcher: SinglePageAudioComponentActionDispatcher(subject: input),
                        componentID: audioComponent.id)

                case .didPresentInvalidDownloadCode:
                    audioComponentContentView
                        .audioDownloadStatePopupView?
                        .setStateToFail()

                case .didAppendAudioTrackRows(let appededIndices):
                    insertNewAudioTracks(appededIndices: appededIndices)

                case let .didPlayAudioTrack(trackIndex, duration, metadata, audioSampleData):
                    playAudioTrack(
                        trackIndex: trackIndex,
                        duration: duration,
                        audioMetadata: metadata,
                        audioSampleData: audioSampleData)

                case let .didApplyAudioMetadataChanges(
                    trackIndex, editedMetadata, isNowPlayingTrack, trackIndexAfterEdit):
                    applyAudioTrackMetadataChanges(
                        targetTrackIndex: trackIndex,
                        metadata: editedMetadata,
                        isNowPlayingTrack: isNowPlayingTrack,
                        trackIndexAfterEditing: trackIndexAfterEdit)

                case .didSortAudioTracks(let before, let after):
                    sortAudioTracks(before: before, after: after)

                case .didUpdateAudioDownloadProgress(let progress):
                    audioComponentContentView
                        .audioDownloadStatePopupView?
                        .progress
                        .setProgress(progress, animated: true)

                case let .didToggleAudioPlayingState(isPlaying, nowPlayingAudioIndex):
                    setAudioPlayingState(
                        isPlaying: isPlaying, nowPlayingAudioIndex: nowPlayingAudioIndex!)

                case .didSeekAudioTrack(let seek, let totalTime, let nowPlayingAudioIndex):
                    performWithAudioTrackRowAt(nowPlayingAudioIndex!) { row in
                        row.audioVisualizer.seekVisuzlization(rate: seek / totalTime!)
                    }
                    audioControlBar.seek(seek: seek)

                case .didRemoveAudioTrack(let trackIndex):
                    audioComponentContentView.removeRow(trackIndex: trackIndex)

                case let .didRemoveAudioTrackAndPlayNextAudio(
                    removeTrackIndex, nextPlayTrackIndex, duration, metadata, sampleData):
                    removeAudioTrackAndPlayNextAudio(
                        removeTrackIndex: removeTrackIndex,
                        nextPlayTrackIndex: nextPlayTrackIndex,
                        duration: duration,
                        metadata: metadata,
                        sampleData: sampleData)

                case .didRemoveAudioTrackAndStopPlaying(let removeTrackIndex):
                    removeAudioTrackAndStopPlaying(removeTrackIndex: removeTrackIndex)
            }
        }
        .store(in: &subscriptions)
    }

    private func setupUI(pageTitle: String) {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundImageView)
        backgroundImageView.alpha = 0
        backgroundImageWindow.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        backgroundImageView.addSubview(backgroundImageWindow)

        titleLable.text = pageTitle
        view.addSubview(titleLable)
        view.addSubview(audioComponentContentView)
        audioComponentContentView.backgroundColor = .clear

        view.addSubview(audioControlBar)

        audioControlBar.isHidden = true
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backgroundImageWindow.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageWindow.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundImageWindow.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageWindow.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            titleLable.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            titleLable.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            audioComponentContentView.topAnchor.constraint(equalTo: titleLable.bottomAnchor, constant: 10),
            audioComponentContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            audioComponentContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            audioComponentContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            audioControlBar.widthAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewWidth),
            audioControlBar.heightAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewHeight),
            audioControlBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            audioControlBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func playAudioTrack(
        trackIndex: Int,
        duration: TimeInterval?,
        audioMetadata: AudioTrackMetadata,
        audioSampleData: AudioSampleData?
    ) {
        audioComponentContentView
            .audioTrackTableView
            .visibleCells
            .map { $0 as! AudioTableRowView }
            .forEach { $0.audioVisualizer.removeVisuzlization() }

        if let thumbnailImageData = audioMetadata.thumbnail {
            updateBackgroundImage(with: UIImage(data: thumbnailImageData))
        }

        audioControlBar.isHidden = false

        performWithAudioTrackRowAt(trackIndex) { row in
            if let audioSampleData {
                row.audioVisualizer.activateAudioVisualizer(
                    samplesCount: audioSampleData.sampleDataCount,
                    scaledSamples: audioSampleData.scaledSampleData,
                    sampleRate: audioSampleData.sampleRate
                )
            }
        }
        audioControlBar.state = .play(
            metadata: audioMetadata,
            duration: duration,
            dispatcher: SinglePageAudioComponentActionDispatcher(subject: input)
        )
    }

    private func applyAudioTrackMetadataChanges(
        targetTrackIndex: Int,
        metadata: AudioTrackMetadata,
        isNowPlayingTrack: Bool,
        trackIndexAfterEditing: Int?
    ) {
        performWithAudioTrackRowAt(targetTrackIndex) { row in
            row.update(metadata)
        }

        if isNowPlayingTrack {
            if let thumbnailImageData = metadata.thumbnail {
                updateBackgroundImage(with: UIImage(data: thumbnailImageData))
            }
            audioControlBar.applyUpdatedMetadata(with: metadata)
        }

        if let trackIndexAfterEditing {
            audioComponentContentView.audioTrackTableView.performBatchUpdates {
                let src = IndexPath(row: targetTrackIndex, section: .zero)
                let des = IndexPath(row: trackIndexAfterEditing, section: .zero)
                self.audioComponentContentView.audioTrackTableView.moveRow(at: src, to: des)
            }
        }
    }

    private func setAudioPlayingState(isPlaying: Bool, nowPlayingAudioIndex: Int) {
        audioControlBar.state = isPlaying ? .resume : .pause
        performWithAudioTrackRowAt(nowPlayingAudioIndex) { row in
            if isPlaying {
                row.audioVisualizer.restartVisuzlization()
            } else {
                row.audioVisualizer.pauseVisuzlization()
            }
        }
    }

    private func insertNewAudioTracks(appededIndices: [Int]) {
        audioComponentContentView
            .audioDownloadStatePopupView?
            .dismiss()
        audioComponentContentView.insertRow(trackIndices: appededIndices)
    }

    private func removeAudioTrackAndPlayNextAudio(
        removeTrackIndex: Int,
        nextPlayTrackIndex: Int,
        duration: TimeInterval?,
        metadata: AudioTrackMetadata,
        sampleData: AudioSampleData?
    ) {
        performWithAudioTrackRowAt(removeTrackIndex) { row in
            row.audioVisualizer.removeVisuzlization()
        }

        audioComponentContentView.removeRow(trackIndex: removeTrackIndex)

        if let thumbnailImageData = metadata.thumbnail {
            updateBackgroundImage(with: UIImage(data: thumbnailImageData))
        }

        audioControlBar.isHidden = false

        performWithAudioTrackRowAt(nextPlayTrackIndex) { row in
            if let sampleData {
                row.audioVisualizer.activateAudioVisualizer(
                    samplesCount: sampleData.sampleDataCount,
                    scaledSamples: sampleData.scaledSampleData,
                    sampleRate: sampleData.sampleRate
                )
            }
        }
        audioControlBar.state = .play(
            metadata: metadata,
            duration: duration,
            dispatcher: SinglePageAudioComponentActionDispatcher(subject: input)
        )
    }

    private func removeAudioTrackAndStopPlaying(removeTrackIndex: Int) {
        audioComponentContentView.removeRow(trackIndex: removeTrackIndex)
        audioControlBar.state = .stop
        updateBackgroundImage(with: nil)
    }

    private func sortAudioTracks(before: [String], after: [String]) {
        let trackTable = audioComponentContentView.audioTrackTableView
        trackTable.performBatchUpdates {
            for (newIndex, item) in after.enumerated() {
                if let oldIndex = before.firstIndex(of: item),
                    oldIndex != newIndex
                {
                    let from = IndexPath(row: oldIndex, section: 0)
                    let to = IndexPath(row: newIndex, section: 0)

                    trackTable.moveRow(at: from, to: to)
                }
            }
        }
    }

    private func updateBackgroundImage(with image: UIImage?) {
        UIView.transition(
            with: self.backgroundImageView, duration: 1, options: .transitionCrossDissolve,
            animations: {
                self.backgroundImageView.image = image?.blurred(radius: 7)
            }, completion: nil)

        UIView.animate(
            withDuration: 1,
            animations: {
                self.backgroundImageWindow.alpha =
                    image == nil ? 0 : self.traitCollection.userInterfaceStyle == .dark ? 0.4 : 0.3
                self.backgroundImageView.alpha = image == nil ? 0 : 1
            }
        )
    }

    private func performWithAudioTrackRowAt(_ index: Int, task: (AudioTableRowView) -> Void) {
        let indexPath = IndexPath(row: index, section: .zero)
        if let row = audioComponentContentView.audioTrackTableView.cellForRow(at: indexPath),
            let audioTableRow = row as? AudioTableRowView
        {
            task(audioTableRow)
        }
    }
}

extension SingleAudioPageViewController: NavigationViewControllerDismissible {
    func onDismiss() {
        input.send(.viewWillDisappear)
        subscriptions.removeAll()
    }
}
