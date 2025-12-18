import AVFAudio
import Combine
import MediaPlayer
import UIKit

final class AudioControlBarView: UIView {

    enum AudioControlBarViewState {
        case initial
        case play(metadata: AudioTrackMetadata, duration: TimeInterval?, dispatcher: AudioComponentActionDispatcher)
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
        artistLabel.textColor = .gray
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
        currentTimeLabel.textColor = .lightGray
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        return currentTimeLabel
    }()
    private let totalTimeLabel: UILabel = {
        let totalTimeLabel = UILabel()
        totalTimeLabel.font = .systemFont(ofSize: 13)
        totalTimeLabel.textColor = .lightGray
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        return totalTimeLabel
    }()
    private let audioProgressBar: AudioProgressBar = {
        let progressBar = AudioProgressBar()
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        return progressBar
    }()

    private var duration: TimeInterval?
    private var subscriptions: Set<AnyCancellable> = []
    private var nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    private var dispatcher: AudioComponentActionDispatcher?
    private var currentTime: TimeInterval = .zero {
        didSet {
            currentTimeLabel.text = currentTime.asMinuteSecond
            nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        }
    }
    var state: AudioControlBarViewState = .initial {
        didSet {
            handleState()
        }
    }

    init() {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()
        setupRemoteTransportControls()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        try? AVAudioSession.sharedInstance().setActive(false)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        print("deinit AudioControlBarView")
    }

    private func setupUI() {
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

        self.layer.cornerRadius = 12
        self.backgroundColor = .clear
        self.translatesAutoresizingMaskIntoConstraints = false

        let shadowLayer = CALayer()

        shadowLayer.frame = .init(
            x: 0, y: 0,
            width: UIConstants.audioControlBarViewWidth,
            height: UIConstants.audioControlBarViewHeight
        )
        shadowLayer.backgroundColor = UIColor(named: "StandardGray")?.cgColor
        shadowLayer.cornerRadius = 12
        shadowLayer.shadowColor =
            traitCollection.userInterfaceStyle == .dark ? UIColor.clear.cgColor : UIColor.gray.cgColor
        shadowLayer.shadowOpacity = 0.7
        shadowLayer.shadowRadius = 3
        shadowLayer.shadowOffset = .init(width: 0, height: 1)
        shadowLayer.masksToBounds = false

        self.layer.insertSublayer(shadowLayer, at: 0)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            thumbnailImageView.widthAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewThumbnailWidth),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: UIConstants.audioControlBarViewThumbnailWidth),
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            thumbnailImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            controlView.topAnchor.constraint(equalTo: topAnchor),
            controlView.bottomAnchor.constraint(equalTo: bottomAnchor),
            controlView.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            controlView.trailingAnchor.constraint(equalTo: trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: controlView.topAnchor, constant: 12),
            titleLabel.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 180),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),

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

            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            buttonStackView.widthAnchor.constraint(equalToConstant: 170),
            buttonStackView.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: controlView.bottomAnchor, constant: -10),

            previousButton.widthAnchor.constraint(equalToConstant: 45),
            previousButton.heightAnchor.constraint(equalToConstant: 35),
            previousButton.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor),
            previousButton.leadingAnchor.constraint(equalTo: buttonStackView.leadingAnchor),

            playPauseButton.widthAnchor.constraint(equalToConstant: 40),
            playPauseButton.heightAnchor.constraint(equalToConstant: 35),
            playPauseButton.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor),
            playPauseButton.centerXAnchor.constraint(equalTo: buttonStackView.centerXAnchor),

            nextButton.widthAnchor.constraint(equalToConstant: 45),
            nextButton.heightAnchor.constraint(equalToConstant: 35),
            nextButton.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: buttonStackView.trailingAnchor),
        ])
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
    }

    func seek(seek: TimeInterval) {
        currentTime = seek
        audioProgressBar.setCurrentProgress(seek)
    }

    func applyUpdatedMetadata(with data: AudioTrackMetadata) {
        if let title = data.title {
            titleLabel.text = title
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyTitle] = title
        }

        if let artist = data.artist {
            artistLabel.text = artist
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtist] = artist
        }

        if let thumbnailData = data.thumbnail,
            let thumbnailImage = UIImage(data: thumbnailData)
        {
            thumbnailImageView.image = thumbnailImage
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: thumbnailImage.size) { _ in thumbnailImage }
        }
    }

    private func handleState() {
        switch state {
            case .initial:
                break

            case let .play(metadata, duration, dispatcher):
                configureControlBarForPlayback(metadata: metadata, duration: duration, dispatcher: dispatcher)

            case .resume:
                playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
                audioProgressBar.startProgress()

            case .pause:
                playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
                audioProgressBar.pauseProgress()

            case .stop:
                updateControlBarStateToStopped()
        }
    }

    private func configureControlBarForPlayback(
        metadata: AudioTrackMetadata,
        duration: TimeInterval?,
        dispatcher: AudioComponentActionDispatcher
    ) {
        self.dispatcher = dispatcher
        self.duration = duration

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)

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

        if let title = metadata.title,
            let artist = metadata.artist,
            let thumbnailData = metadata.thumbnail,
            let thumbnail = UIImage(data: thumbnailData)
        {
            titleLabel.text = title
            artistLabel.text = artist
            thumbnailImageView.image = thumbnail

            if let duration {
                totalTimeLabel.text = duration.asMinuteSecond

                audioProgressBar.minimumValue = .zero
                audioProgressBar.maximumValue = duration
                audioProgressBar.setCurrentProgress(.zero)
                audioProgressBar.startProgress()

                var info: [String: Any] = [
                    MPMediaItemPropertyTitle: title,
                    MPMediaItemPropertyArtist: artist,
                    MPMediaItemPropertyPlaybackDuration: duration,
                    MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0,
                    MPNowPlayingInfoPropertyPlaybackRate: 1.0,
                ]

                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: thumbnail.size) { _ in
                    thumbnail
                }

                nowPlayingInfoCenter.nowPlayingInfo = info
            }
        }
    }

    private func updateControlBarStateToStopped() {
        audioProgressBar.setCurrentProgress(.zero)
        audioProgressBar.isScrubbingEnabled = false

        titleLabel.text = "Not Playing"
        artistLabel.text = "unknown"
        thumbnailImageView.image = UIImage(named: "defaultMusicThumbnail")
        playPauseButton.isEnabled = false
        previousButton.isEnabled = false
        nextButton.isEnabled = false
        currentTimeLabel.text = "0:00"
        totalTimeLabel.text = "0:00"

        nowPlayingInfoCenter.nowPlayingInfo = nil
    }

    private func setupRemoteTransportControls() {

        UIApplication.shared.beginReceivingRemoteControlEvents()
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        remoteCommandCenter.togglePlayPauseCommand.removeTarget(nil)
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            dispatcher?.togglePlayingState()
            return .success
        }

        remoteCommandCenter.changePlaybackPositionCommand.removeTarget(nil)
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
        remoteCommandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self else { return .commandFailed }

            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                let newTime = positionEvent.positionTime
                dispatcher?.seekAudioTrack(seek: newTime)
                return .success
            }
            return .commandFailed
        }

        remoteCommandCenter.nextTrackCommand.removeTarget(nil)
        remoteCommandCenter.nextTrackCommand.isEnabled = true
        remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            dispatcher?.playNextAudioTrack()
            return .success
        }

        remoteCommandCenter.previousTrackCommand.removeTarget(nil)
        remoteCommandCenter.previousTrackCommand.isEnabled = true
        remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            dispatcher?.playPreviousAudioTrack()
            return .success
        }
    }

    @objc private func sliderValuecomp(_ sender: AudioProgressBar) {
        dispatcher?.seekAudioTrack(seek: sender.currentProgress)
    }
}
