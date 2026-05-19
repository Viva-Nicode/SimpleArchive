import AVFAudio
import Combine
import MediaPlayer
import SwiftUI
import UIKit

final class AudioControlBarView: UIView, UITableViewDelegate {
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 3
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.lineBreakMode = .byCharWrapping
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
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
        thumbnailImageView.layer.cornerRadius = UIConstants.audioControlBarViewThumbnailWidth * 0.5
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
        blurView.layer.cornerRadius = 15
        blurView.clipsToBounds = true

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

    private var thinFadeViews: [UIView] { [currentTimeLabel, totalTimeLabel, audioProgressBar] }
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
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowRadius = 2
        layer.shadowOffset = .init(width: 0, height: 0.5)
        layer.masksToBounds = false
        layer.cornerRadius = 15

        addSubview(blurView)
        addSubview(blockerView)

        buttonStackView.addSubview(previousButton)
        buttonStackView.addSubview(playPauseButton)
        buttonStackView.addSubview(nextButton)

        addSubview(thumbnailImageView)
        addSubview(controlView)

        controlView.addSubview(titleLabel)
        controlView.addSubview(audioProgressBar)
        controlView.addSubview(currentTimeLabel)
        controlView.addSubview(totalTimeLabel)
        controlView.addSubview(buttonStackView)

        addSubview(audioTrackListView)
        audioTrackListView.alpha = 0
        audioTrackListView.audioTrackTableView.delegate = self

        sendSubviewToBack(blurView)
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupConstraints() {
        defaultThumnbnailConstraints = [
            thumbnailImageView.heightAnchor.constraint(equalToConstant: defaultThumbnailSize),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: defaultThumbnailSize),
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            thumbnailImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ]

        thinThumbnailConstraints = [
            thumbnailImageView.heightAnchor.constraint(equalToConstant: 50),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 50),
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            thumbnailImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ]

        expendedThumbnailConstraints = [
            thumbnailImageView.heightAnchor.constraint(equalToConstant: defaultThumbnailSize),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: defaultThumbnailSize),
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
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
            titleLabel.topAnchor.constraint(equalTo: controlView.topAnchor, constant: 5),
            titleLabel.widthAnchor.constraint(equalToConstant: UIView.screenWidth - 210),
            titleLabel.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 60),
        ]

        dafaultDetailConstraints = [
            currentTimeLabel.leadingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: 10),
            currentTimeLabel.bottomAnchor.constraint(equalTo: audioProgressBar.topAnchor),

            totalTimeLabel.trailingAnchor.constraint(equalTo: controlView.trailingAnchor, constant: -10),
            totalTimeLabel.bottomAnchor.constraint(equalTo: audioProgressBar.topAnchor),

            audioProgressBar.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            audioProgressBar.widthAnchor.constraint(equalToConstant: 180),
            audioProgressBar.heightAnchor.constraint(equalToConstant: 5),
            audioProgressBar.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
        ]

        defaultButtonStackConstraints = [
            buttonStackView.topAnchor.constraint(equalTo: audioProgressBar.bottomAnchor, constant: 5),
            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            buttonStackView.widthAnchor.constraint(equalToConstant: 170),
            buttonStackView.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
        ]

        thinTitleConstraints = [
            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 5),
            titleLabel.widthAnchor.constraint(equalToConstant: UIView.screenWidth - 210),
            titleLabel.heightAnchor.constraint(equalToConstant: 60),
            titleLabel.centerYAnchor.constraint(equalTo: controlView.centerYAnchor),
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
        setTitleAttrLabel(title: data.title!, artist: data.artist!)
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

    private func setTitleAttrLabel(title: String, artist: String) {
        let size = (title as NSString)
            .size(withAttributes: [.font: UIFont.systemFont(ofSize: 16, weight: .semibold)])

        let attributedString = NSMutableAttributedString()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.alignment = .center

        let line = size.width / (UIView.screenWidth - 210)
        let title =
            line >= 1.9
            ? {
                let char = line / CGFloat(title.count)
                let cut = title.count - Int(abs(1.6 - line) / char)
                return title.map { String($0) }[0..<cut].joined() + "..."
            }() : title

        attributedString.append(
            NSAttributedString(
                string: title,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                    .foregroundColor: UIColor.label,
                ]
            )
        )

        attributedString.append(
            NSAttributedString(
                string: "\n" + artist,
                attributes: [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.label,
                ]
            )
        )

        attributedString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attributedString.length)
        )

        titleLabel.attributedText = attributedString
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

        setTitleAttrLabel(title: metadata.title!, artist: metadata.artist!)

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

		titleLabel.attributedText = nil
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

        titleLabel.transform = .identity
        thumbnailImageView.layer.cornerRadius = UIConstants.audioControlBarViewThumbnailWidth * 0.5
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

        thumbnailImageView.layer.cornerRadius = 15 - 5 + 0.5
        titleLabel.transform = .init(scaleX: 0.85, y: 0.85)

        NSLayoutConstraint.activate(
            thinTitleConstraints + thinButtonStackConstraints + thinThumbnailConstraints + thinContentConstraints
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
        titleLabel.transform = .identity

        thumbnailImageView.layer.cornerRadius = defaultThumbnailSize / 2
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
