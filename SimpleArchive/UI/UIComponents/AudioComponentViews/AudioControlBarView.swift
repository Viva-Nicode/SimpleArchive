import AVFAudio
import Combine
import MediaPlayer
import SwiftUI
import UIKit

final class AudioControlBarView: UIView {

    enum AudioControlBarViewState {
        case initial
        case play(metadata: AudioTrackMetadata, dispatcher: AudioComponentActionDispatcher?)
        case resume
        case pause
        case stop
    }

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
    private let audioProgressBar: AudioProgressBar = {
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

    private var subscriptions: Set<AnyCancellable> = []
    private(set) var dispatcher: AudioComponentActionDispatcher?
    private var currentTime: TimeInterval = .zero {
        didSet { currentTimeLabel.text = currentTime.asMinuteSecond }
    }
    var state: AudioControlBarViewState = .initial { didSet { handleState() } }

    private var isThinLayoutApplied = false

    private let defaultThumbnailSize = UIConstants.audioControlBarViewThumbnailWidth
    private let thinThumbnailSize = UIConstants.audioControlBarViewThumbnailWidth / 2

    private var thumbnailWidthConstraint: NSLayoutConstraint!
    private var thumbnailHeightConstraint: NSLayoutConstraint!
    private var thumbnailCenterYConstraint: NSLayoutConstraint!

    private var thinTitleCenterYConstraint: NSLayoutConstraint!
    private var thinButtonStackCenterYConstraint: NSLayoutConstraint!

    private var defaultTitleConstraints: [NSLayoutConstraint] = []
    private var thinTitleConstraints: [NSLayoutConstraint] = []

    private var dafaultDetailConstraints: [NSLayoutConstraint] = []

    private var defaultButtonStackConstraints: [NSLayoutConstraint] = []
    private var thinButtonStackConstraints: [NSLayoutConstraint] = []
    private var previousNextButtonConstraints: [NSLayoutConstraint] = []

    private var thinFadeViews: [UIView] { [artistLabel, currentTimeLabel, totalTimeLabel, audioProgressBar] }
    private var thinButtonFadeViews: [UIView] { [previousButton, nextButton] }

    private var panGesture: UIPanGestureRecognizer?
    private var panStartPointInWindow: CGPoint?
    private var panStartOriginY: CGFloat = 0

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
        sendSubviewToBack(blurView)

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

        layer.cornerRadius = 12
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        thumbnailWidthConstraint = thumbnailImageView.widthAnchor.constraint(equalToConstant: defaultThumbnailSize)
        thumbnailHeightConstraint = thumbnailImageView.heightAnchor.constraint(equalToConstant: defaultThumbnailSize)
        thumbnailCenterYConstraint = thumbnailImageView.centerYAnchor.constraint(equalTo: centerYAnchor)
        thinTitleCenterYConstraint = titleLabel.centerYAnchor.constraint(equalTo: controlView.centerYAnchor)
        thinButtonStackCenterYConstraint = buttonStackView.centerYAnchor.constraint(equalTo: controlView.centerYAnchor)

        let baseConstraints = [
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            thumbnailWidthConstraint!,
            thumbnailHeightConstraint!,
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            thumbnailCenterYConstraint!,

            controlView.topAnchor.constraint(equalTo: topAnchor),
            controlView.bottomAnchor.constraint(equalTo: bottomAnchor),
            controlView.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            controlView.trailingAnchor.constraint(equalTo: trailingAnchor),

            playPauseButton.widthAnchor.constraint(equalToConstant: 40),
            playPauseButton.heightAnchor.constraint(equalToConstant: 35),
            playPauseButton.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor),
            playPauseButton.centerXAnchor.constraint(equalTo: buttonStackView.centerXAnchor),
        ]

		defaultTitleConstraints = [
            titleLabel.topAnchor.constraint(equalTo: controlView.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 180),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
        ]

		thinTitleConstraints = [
            titleLabel.leadingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: buttonStackView.leadingAnchor, constant: -8),
            thinTitleCenterYConstraint!,
            titleLabel.heightAnchor.constraint(equalToConstant: 28),
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

            audioProgressBar.widthAnchor.constraint(equalToConstant: 180),
            audioProgressBar.heightAnchor.constraint(equalToConstant: 5),
            audioProgressBar.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            audioProgressBar.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: -10),
        ]

		defaultButtonStackConstraints = [
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            buttonStackView.widthAnchor.constraint(equalToConstant: 170),
            buttonStackView.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: controlView.bottomAnchor, constant: -10),
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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction))
        addGestureRecognizer(panGesture!)
        audioProgressBar.setGesture(panGesture: panGesture!)
    }

    @objc func panGestureAction(_ sender: UIPanGestureRecognizer) {
        guard let window = self.window else { return }
        let currentPoint = sender.location(in: window)

        switch sender.state {
            case .began:
                panStartPointInWindow = currentPoint
                panStartOriginY = frame.origin.y

            case .changed:
                guard let start = panStartPointInWindow else { return }
                let deltaY = currentPoint.y - start.y
                frame.origin.y = panStartOriginY + deltaY

                if deltaY > 0 {
                    self.alpha = 1 - deltaY * 0.004
                }

            case .ended, .cancelled, .failed:
                guard let start = panStartPointInWindow else { return }
                let deltaY = currentPoint.y - start.y

                if deltaY > 0 {
                    let movedDown = deltaY
                    myLog("ended: moved DOWN \(movedDown)")
                    if movedDown >= (isThinLayoutApplied ? 30.0 : 100.0) {
                        audioProgressBar.pauseProgress()
                        UIView.animate(withDuration: 0.3) {
                            self.alpha = 0
                            self.frame.origin.y += 100
                        } completion: { _ in
                            self.alpha = 1
                            self.isHidden = true
                            self.dispatcher?.dissmissAudioControlBar()
                        }
                        return
                    }
                } else if deltaY < 0 {
                    let movedUp = -deltaY
                    myLog("ended: moved UP \(movedUp)")

                }

                UIView.animate(
                    withDuration: 0.4,
                    delay: 0,
                    usingSpringWithDamping: 0.45,
                    initialSpringVelocity: 0.7,
                    options: [.curveEaseInOut]
                ) {
                    self.frame.origin.y = self.panStartOriginY
                    self.alpha = 1
                }

                panStartPointInWindow = nil

            default:
                break
        }
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
        guard isThinLayoutApplied else { return }
        isThinLayoutApplied = false

        NSLayoutConstraint.deactivate(thinTitleConstraints + thinButtonStackConstraints)
        NSLayoutConstraint.activate(
			defaultTitleConstraints
                + dafaultDetailConstraints
                + defaultButtonStackConstraints
                + previousNextButtonConstraints
        )

		thinButtonFadeViews.forEach { $0.isHidden = false }
		thinButtonFadeViews.forEach { $0.alpha = 1 }
		thinFadeViews.forEach { $0.isHidden = false }
		thinFadeViews.forEach { $0.alpha = 1 }

        thumbnailWidthConstraint.constant = defaultThumbnailSize
        thumbnailHeightConstraint.constant = defaultThumbnailSize
        thumbnailImageView.layer.cornerRadius = defaultThumbnailSize / 2

        layer.cornerRadius = 12
        blurView.layer.cornerRadius = 13
    }

    func setAudioControlBarLayoutAsThin() {
        guard !isThinLayoutApplied else { return }
        isThinLayoutApplied = true

        NSLayoutConstraint.deactivate(
			defaultTitleConstraints
                + defaultButtonStackConstraints
                + previousNextButtonConstraints
        )
        NSLayoutConstraint.activate(thinTitleConstraints + thinButtonStackConstraints)

		thinButtonFadeViews.forEach { $0.isHidden = false }
		thinButtonFadeViews.forEach { $0.alpha = 0 }
		thinFadeViews.forEach { $0.isHidden = false }
		thinFadeViews.forEach { $0.alpha = 0 }

        thumbnailWidthConstraint.constant = thinThumbnailSize
        thumbnailHeightConstraint.constant = thinThumbnailSize
        thumbnailImageView.layer.cornerRadius = thinThumbnailSize / 2

        layer.cornerRadius = 37.5
        blurView.layer.cornerRadius = 38.5
    }
}
