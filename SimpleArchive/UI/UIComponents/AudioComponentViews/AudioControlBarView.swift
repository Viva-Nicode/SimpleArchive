import AVFAudio
import Combine
import MediaPlayer
import SwiftUI
import UIKit

final class AudioControlBarView: UIView, UITableViewDelegate {
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .label
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private let artistLabel: UILabel = {
        let artistLabel = UILabel()
        artistLabel.font = .systemFont(ofSize: 14)
        artistLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .lightGray : .darkGray
        }
        artistLabel.textAlignment = .center
        artistLabel.numberOfLines = 1
        artistLabel.translatesAutoresizingMaskIntoConstraints = false
        return artistLabel
    }()
    private let buttonStackView: UIView = {
        let buttonStackView = UIView()
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        return buttonStackView
    }()
    private let thumbnailImageView: UIImageView = {
        let thumbnailImageView = UIImageView()
        thumbnailImageView.isUserInteractionEnabled = true
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = UIConstants.audioControlBarViewThumbnailWidth / 2
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        return thumbnailImageView
    }()
    private let playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "pause.fill")
        config.baseForegroundColor = .label
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 27, weight: .bold)
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let previousButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "backward.fill")
        config.baseForegroundColor = .label
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 23, weight: .bold)
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "forward.fill")
        config.baseForegroundColor = .label
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 23, weight: .bold)
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private let controlView: UIView = {
        let controlView = UIView()
        controlView.translatesAutoresizingMaskIntoConstraints = false
        return controlView
    }()
    private let currentTimeLabel: UILabel = {
        let currentTimeLabel = UILabel()
        currentTimeLabel.font = .systemFont(ofSize: 13)
        currentTimeLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .lightGray : .darkGray
        }
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        return currentTimeLabel
    }()
    private let totalTimeLabel: UILabel = {
        let totalTimeLabel = UILabel()
        totalTimeLabel.font = .systemFont(ofSize: 13)
        totalTimeLabel.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .lightGray : .darkGray
        }
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        return totalTimeLabel
    }()
    private(set) var audioProgressBar: AudioProgressBar = {
        let progressBar = AudioProgressBar()
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        return progressBar
    }()
    private let blurView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false

        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true

        blurView.layer.borderWidth = 1

        let borderColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? .white.withAlphaComponent(0.3) : .gray.withAlphaComponent(0.4)
        }
        blurView.layer.borderColor = borderColor.cgColor

        return blurView
    }()
    private var blockerView: UIView = {
        let blockerView = UIView()
        blockerView.backgroundColor = .clear
        blockerView.isUserInteractionEnabled = true
        blockerView.translatesAutoresizingMaskIntoConstraints = false
        return blockerView
    }()

    private var subscriptions: Set<AnyCancellable> = []
    private(set) var dispatcher: AudioComponentActionDispatcher?
    private var currentTime: TimeInterval = .zero {
        didSet { currentTimeLabel.text = currentTime.asMinuteSecond }
    }
    var state: AudioControlBarViewState = .initial { didSet { handleState() } }

    private let defaultThumbnailSize = UIConstants.audioControlBarViewThumbnailWidth
    private let thinThumbnailSize = UIConstants.audioControlBarViewThumbnailWidth / 2

    private var thinTitleCenterYConstraint: NSLayoutConstraint!
    private var thinButtonStackCenterYConstraint: NSLayoutConstraint!
    private var controlViewBottomConstraint: NSLayoutConstraint!

    private var expendedContentConstraints: [NSLayoutConstraint] = []

    private var defaultTitleConstraints: [NSLayoutConstraint] = []
    private var thinTitleConstraints: [NSLayoutConstraint] = []

    private var dafaultDetailConstraints: [NSLayoutConstraint] = []

    private var defaultButtonStackConstraints: [NSLayoutConstraint] = []
    private var thinButtonStackConstraints: [NSLayoutConstraint] = []
    private var previousNextButtonConstraints: [NSLayoutConstraint] = []

    private var defaultThumnbnailConstraints: [NSLayoutConstraint] = []
    private var thinThumbnailConstraints: [NSLayoutConstraint] = []
    private var expendedThumbnailConstraints: [NSLayoutConstraint] = []
    private var thinContentConstraints: [NSLayoutConstraint] = []

    private var thinFadeViews: [UIView] { [artistLabel, currentTimeLabel, totalTimeLabel, audioProgressBar] }
    private var thinButtonFadeViews: [UIView] { [previousButton, nextButton] }

    private(set) var audioTrackListView = ExpendedAudioControlBarTrackListView()
    private var selectedAudioTrackIndexPath: IndexPath?

    init() {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
        isHidden = true
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    private func setupUI() {
        addSubview(blurView)
        addSubview(blockerView)

        buttonStackView.addSubview(previousButton)
        buttonStackView.addSubview(playPauseButton)
        buttonStackView.addSubview(nextButton)

        addSubview(thumbnailImageView)
        addSubview(controlView)

        controlView.addSubview(titleLabel)
        controlView.addSubview(artistLabel)
        controlView.addSubview(audioProgressBar)
        controlView.addSubview(currentTimeLabel)
        controlView.addSubview(totalTimeLabel)
        controlView.addSubview(buttonStackView)

        addSubview(audioTrackListView)
        audioTrackListView.alpha = 0
        audioTrackListView.audioTrackTableView.delegate = self

        sendSubviewToBack(blurView)

        layer.cornerRadius = 12
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        defaultThumnbnailConstraints = [
            thumbnailImageView.heightAnchor.constraint(equalToConstant: defaultThumbnailSize),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: defaultThumbnailSize),
            thumbnailImageView.centerYAnchor.constraint(equalTo: controlView.centerYAnchor),
        ]

        thinThumbnailConstraints = [
            thumbnailImageView.heightAnchor.constraint(equalToConstant: thinThumbnailSize),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: thinThumbnailSize),
            thumbnailImageView.centerYAnchor.constraint(equalTo: controlView.centerYAnchor),
        ]

        expendedThumbnailConstraints = [
            thumbnailImageView.heightAnchor.constraint(equalToConstant: defaultThumbnailSize),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: defaultThumbnailSize),
            thumbnailImageView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
        ]

        expendedContentConstraints = [
            audioTrackListView.topAnchor.constraint(equalTo: thumbnailImageView.bottomAnchor, constant: 20),
            audioTrackListView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            audioTrackListView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            audioTrackListView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]

        thinContentConstraints = [
            audioTrackListView.heightAnchor.constraint(equalToConstant: 0),
            audioTrackListView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            audioTrackListView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            audioTrackListView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ]

        thinTitleCenterYConstraint = titleLabel.centerYAnchor.constraint(equalTo: controlView.centerYAnchor)
        thinButtonStackCenterYConstraint = buttonStackView.centerYAnchor.constraint(equalTo: controlView.centerYAnchor)
        controlViewBottomConstraint = controlView.bottomAnchor.constraint(equalTo: bottomAnchor)

        let baseConstraints =
            [
                blurView.topAnchor.constraint(equalTo: topAnchor),
                blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

                blockerView.topAnchor.constraint(equalTo: topAnchor),
                blockerView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blockerView.trailingAnchor.constraint(equalTo: trailingAnchor),
                blockerView.bottomAnchor.constraint(equalTo: bottomAnchor),

                thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),

                controlView.topAnchor.constraint(equalTo: topAnchor),
                controlViewBottomConstraint!,
                controlView.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
                controlView.trailingAnchor.constraint(equalTo: trailingAnchor),

                playPauseButton.widthAnchor.constraint(equalToConstant: 40),
                playPauseButton.heightAnchor.constraint(equalToConstant: 35),
                playPauseButton.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor),
                playPauseButton.centerXAnchor.constraint(equalTo: buttonStackView.centerXAnchor),
            ] + defaultThumnbnailConstraints + thinContentConstraints

        defaultTitleConstraints = [
            titleLabel.topAnchor.constraint(equalTo: controlView.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 180),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
        ]

        dafaultDetailConstraints = [
            artistLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            artistLabel.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            artistLabel.widthAnchor.constraint(equalToConstant: 180),
            artistLabel.heightAnchor.constraint(equalToConstant: 20),

            currentTimeLabel.leadingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: 10),
            currentTimeLabel.bottomAnchor.constraint(equalTo: audioProgressBar.topAnchor),

            totalTimeLabel.trailingAnchor.constraint(equalTo: controlView.trailingAnchor, constant: -10),
            totalTimeLabel.bottomAnchor.constraint(equalTo: audioProgressBar.topAnchor),

            audioProgressBar.topAnchor.constraint(equalTo: artistLabel.bottomAnchor, constant: 20),
            audioProgressBar.widthAnchor.constraint(equalToConstant: 180),
            audioProgressBar.heightAnchor.constraint(equalToConstant: 5),
            audioProgressBar.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
        ]

        defaultButtonStackConstraints = [
            buttonStackView.topAnchor.constraint(equalTo: audioProgressBar.bottomAnchor, constant: 10),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            buttonStackView.widthAnchor.constraint(equalToConstant: 170),
            buttonStackView.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
        ]

        thinTitleConstraints = [
            titleLabel.leadingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: 0),
            titleLabel.widthAnchor.constraint(equalToConstant: 180),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            thinTitleCenterYConstraint!,
        ]

        thinButtonStackConstraints = [
            buttonStackView.heightAnchor.constraint(equalToConstant: 35),
            buttonStackView.widthAnchor.constraint(equalToConstant: 40),
            buttonStackView.trailingAnchor.constraint(equalTo: controlView.trailingAnchor, constant: -12),
            thinButtonStackCenterYConstraint!,
        ]

        previousNextButtonConstraints = [
            previousButton.widthAnchor.constraint(equalToConstant: 45),
            previousButton.heightAnchor.constraint(equalToConstant: 35),
            previousButton.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor),
            previousButton.leadingAnchor.constraint(equalTo: buttonStackView.leadingAnchor),

            nextButton.widthAnchor.constraint(equalToConstant: 45),
            nextButton.heightAnchor.constraint(equalToConstant: 35),
            nextButton.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: buttonStackView.trailingAnchor),
        ]

        NSLayoutConstraint.activate(
            baseConstraints
                + defaultTitleConstraints
                + dafaultDetailConstraints
                + defaultButtonStackConstraints
                + previousNextButtonConstraints
        )
    }

    private func setupActions() {
        playPauseButton.addAction(
            UIAction { [weak self] _ in
                self?.dispatcher?.togglePlayingState()
            }, for: .touchUpInside)

        nextButton.throttleTapPublisher(interval: 1.0)
            .sink { [weak self] _ in
                self?.audioProgressBar.pauseProgress()
                self?.dispatcher?.playNextAudioTrack()
            }
            .store(in: &subscriptions)

        previousButton.throttleTapPublisher(interval: 1.0)
            .sink { [weak self] _ in
                self?.audioProgressBar.pauseProgress()
                self?.dispatcher?.playPreviousAudioTrack()
            }
            .store(in: &subscriptions)

        thumbnailImageView
            .throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                self?.dispatcher?.scrollToActiveAudioTrack()
            }
            .store(in: &subscriptions)
    }

    func seek(seek: TimeInterval) {
        currentTime = seek
        audioProgressBar.setCurrentProgress(seek)
    }

    func applyUpdatedMetadata(with data: AudioTrackMetadata) {
        titleLabel.text = data.title
        artistLabel.text = data.artist
        let thumbnailImage = UIImage(data: data.thumbnail ?? Data())
        thumbnailImageView.image = thumbnailImage
    }

    private func handleState() {
        switch state {
            case .initial:
                break

            case .play(let metadata, let dispatcher):
                configureControlBarForPlayback(metadata: metadata, dispatcher: dispatcher)

            case .resume:
                playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                audioProgressBar.startProgress()

            case .pause:
                playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                audioProgressBar.pauseProgress()

            case .stop:
                updateControlBarStateToStopped()
        }
    }

    private func configureControlBarForPlayback(
        metadata: AudioTrackMetadata,
        dispatcher: AudioComponentActionDispatcher?
    ) {
        if let dispatcher { self.dispatcher = dispatcher }

        currentTime = .zero
        playPauseButton.isEnabled = true
        previousButton.isEnabled = true
        nextButton.isEnabled = true

        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)

        audioProgressBar.isScrubbingEnabled = true
        audioProgressBar.addTarget(
            self,
            action: #selector(sliderValuecomp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel])

        audioProgressBar.updateCurrentTimeLabel = { self.currentTime = $0 }

        titleLabel.text = metadata.title
        artistLabel.text = metadata.artist
        let thumbnailImage = UIImage(data: metadata.thumbnail ?? Data())
        thumbnailImageView.image = thumbnailImage
        totalTimeLabel.text = metadata.duration?.asMinuteSecond

        if let duration = metadata.duration {
            audioProgressBar.minimumValue = .zero
            audioProgressBar.maximumValue = duration
            audioProgressBar.setCurrentProgress(.zero)
            audioProgressBar.startProgress()
        }
    }

    private func updateControlBarStateToStopped() {
        audioProgressBar.setCurrentProgress(.zero)
        audioProgressBar.isScrubbingEnabled = false

        dispatcher = nil

        titleLabel.text = "Not Playing"
        artistLabel.text = "unknown"
        thumbnailImageView.image = UIImage(named: "defaultMusicThumbnail")
        playPauseButton.isEnabled = false
        previousButton.isEnabled = false
        nextButton.isEnabled = false
        currentTimeLabel.text = "0:00"
        totalTimeLabel.text = "0:00"
    }

    @objc private func sliderValuecomp(_ sender: AudioProgressBar) {
        dispatcher?.seekAudioTrack(seek: sender.currentProgress)
    }

    func setAudioControlBarLayoutAsDefault() {
        NSLayoutConstraint.deactivate(
            thinTitleConstraints
                + thinButtonStackConstraints
                + thinThumbnailConstraints
                + expendedThumbnailConstraints
                + expendedContentConstraints
        )
        controlViewBottomConstraint.isActive = true

        NSLayoutConstraint.activate(
            defaultTitleConstraints
                + defaultThumnbnailConstraints
                + dafaultDetailConstraints
                + defaultButtonStackConstraints
                + previousNextButtonConstraints
                + thinContentConstraints
        )

        thinButtonFadeViews.forEach { $0.isHidden = false }
        thinButtonFadeViews.forEach { $0.alpha = 1 }
        thinFadeViews.forEach { $0.isHidden = false }
        thinFadeViews.forEach { $0.alpha = 1 }

        thumbnailImageView.layer.cornerRadius = defaultThumbnailSize / 2

        layer.cornerRadius = 12
        blurView.layer.cornerRadius = 13

        audioTrackListView.alpha = 0
    }

    func setAudioControlBarLayoutAsThin() {
        NSLayoutConstraint.deactivate(
            defaultTitleConstraints
                + defaultButtonStackConstraints
                + previousNextButtonConstraints
                + expendedContentConstraints
                + expendedThumbnailConstraints
                + defaultThumnbnailConstraints
        )

        controlViewBottomConstraint.isActive = false
        controlViewBottomConstraint = controlView.bottomAnchor.constraint(equalTo: bottomAnchor)
        controlViewBottomConstraint.isActive = true

        thumbnailImageView.layer.cornerRadius = thinThumbnailSize / 2
        NSLayoutConstraint.activate(
            thinTitleConstraints
                + thinButtonStackConstraints
                + thinThumbnailConstraints
                + thinContentConstraints
        )

        thinButtonFadeViews.forEach {
            $0.isHidden = false
            $0.alpha = 0
        }
        thinFadeViews.forEach {
            $0.isHidden = false
            $0.alpha = 0
        }

        audioTrackListView.updateLayoutToThin()

        layer.cornerRadius = 35
        blurView.layer.cornerRadius = 35
    }

    func setAudioControlBarLayoutAsExpanded() {
        NSLayoutConstraint.deactivate(
            thinTitleConstraints
                + thinButtonStackConstraints
                + thinThumbnailConstraints
                + thinContentConstraints
                + defaultThumnbnailConstraints
        )

        controlViewBottomConstraint.isActive = false
        controlViewBottomConstraint = controlView.bottomAnchor.constraint(equalTo: audioTrackListView.topAnchor)
        controlViewBottomConstraint.isActive = true

        NSLayoutConstraint.activate(
            defaultTitleConstraints
                + dafaultDetailConstraints
                + defaultButtonStackConstraints
                + previousNextButtonConstraints
                + expendedThumbnailConstraints
                + expendedContentConstraints
        )

        thinButtonFadeViews.forEach { $0.isHidden = false }
        thinButtonFadeViews.forEach { $0.alpha = 1 }
        thinFadeViews.forEach { $0.isHidden = false }
        thinFadeViews.forEach { $0.alpha = 1 }

        thumbnailImageView.layer.cornerRadius = defaultThumbnailSize / 2

        layer.cornerRadius = 12
        blurView.layer.cornerRadius = 13

        audioTrackListView.updateLayoytToExpended()
    }

    func blockTouch() { bringSubviewToFront(blockerView) }

    func unblockTouch() { sendSubviewToBack(blockerView) }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if selectedAudioTrackIndexPath == indexPath {
            dispatcher?.playAudioTrack(with: indexPath.row)
            self.selectedAudioTrackIndexPath = nil
            tableView.deselectRow(at: indexPath, animated: true)
        } else {
            selectedAudioTrackIndexPath = indexPath
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.selectedAudioTrackIndexPath = nil
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
        return indexPath
    }
}

enum AudioControlBarViewState: Equatable {
    case initial
    case play(metadata: AudioTrackMetadata, dispatcher: AudioComponentActionDispatcher?)
    case resume
    case pause
    case stop

    static func == (lhs: AudioControlBarViewState, rhs: AudioControlBarViewState) -> Bool {
        switch (lhs, rhs) {
            case (.initial, .initial),
                (.play, .play),
                (.resume, .resume),
                (.pause, .pause),
                (.stop, .stop):
                return true
            default:
                return false
        }
    }
}
