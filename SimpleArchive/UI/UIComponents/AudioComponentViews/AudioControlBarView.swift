import AVFAudio
import Combine
import MediaPlayer
import UIKit

final class AudioControlBarView: UIView {

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
    private let playButton: UIButton = {
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
    private let slider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = .systemOrange
        slider.maximumTrackTintColor = .lightGray

        let size = CGSize(width: 20, height: 20)
        let renderer = UIGraphicsImageRenderer(size: size)
        let circleImage = renderer.image { context in
            UIColor.clear.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }

        slider.setThumbImage(circleImage, for: .normal)
        return slider
    }()

    private var nowPlayingInfo: NowPlayingInfo?
    private var audioPlayTimer: DispatchSourceTimer?
    private var dispatcher: AudioComponentActionDispatcher?
    private var currentTime: Float = .zero {
        didSet { currentTimeLabel.text = currentTime.asMinuteSecond }
    }
    private var duration: TimeInterval?
    private var isPlaying: Bool = true
    private var subscriptions: Set<AnyCancellable> = []

    init() {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        setupActions()

        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        try? AVAudioSession.sharedInstance().setActive(false)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        print("deinit AudioControlBarView")
    }

    private func setupUI() {
        buttonStackView.addSubview(previousButton)
        buttonStackView.addSubview(playButton)
        buttonStackView.addSubview(nextButton)

        addSubview(thumbnailImageView)
        addSubview(controlView)

        controlView.addSubview(titleLabel)
        controlView.addSubview(artistLabel)
        controlView.addSubview(slider)
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
            height: UIConstants.audioControlBarViewHeight)
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
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            thumbnailImageView.centerYAnchor.constraint(equalTo: centerYAnchor),

            controlView.topAnchor.constraint(equalTo: topAnchor),
            controlView.bottomAnchor.constraint(equalTo: bottomAnchor),
            controlView.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 10),
            controlView.trailingAnchor.constraint(equalTo: trailingAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            titleLabel.widthAnchor.constraint(equalToConstant: 180),
            titleLabel.heightAnchor.constraint(equalToConstant: 30),
            titleLabel.bottomAnchor.constraint(equalTo: artistLabel.topAnchor),

            artistLabel.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            artistLabel.widthAnchor.constraint(equalToConstant: 180),
            artistLabel.heightAnchor.constraint(equalToConstant: 20),
            artistLabel.bottomAnchor.constraint(equalTo: slider.topAnchor, constant: -10),

            currentTimeLabel.leadingAnchor.constraint(equalTo: controlView.leadingAnchor, constant: 10),
            currentTimeLabel.bottomAnchor.constraint(equalTo: slider.topAnchor, constant: 7),

            totalTimeLabel.trailingAnchor.constraint(equalTo: controlView.trailingAnchor, constant: -10),
            totalTimeLabel.bottomAnchor.constraint(equalTo: slider.topAnchor, constant: 7),

            slider.widthAnchor.constraint(equalToConstant: 180),
            slider.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            slider.bottomAnchor.constraint(equalTo: buttonStackView.topAnchor, constant: 0),

            buttonStackView.heightAnchor.constraint(equalToConstant: 40),
            buttonStackView.widthAnchor.constraint(equalToConstant: 170),
            buttonStackView.centerXAnchor.constraint(equalTo: controlView.centerXAnchor),
            buttonStackView.bottomAnchor.constraint(equalTo: controlView.bottomAnchor, constant: -10),

            previousButton.widthAnchor.constraint(equalToConstant: 45),
            previousButton.heightAnchor.constraint(equalToConstant: 35),
            previousButton.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor),
            previousButton.leadingAnchor.constraint(equalTo: buttonStackView.leadingAnchor),

            playButton.widthAnchor.constraint(equalToConstant: 40),
            playButton.heightAnchor.constraint(equalToConstant: 35),
            playButton.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor),
            playButton.centerXAnchor.constraint(equalTo: buttonStackView.centerXAnchor),

            nextButton.widthAnchor.constraint(equalToConstant: 45),
            nextButton.heightAnchor.constraint(equalToConstant: 35),
            nextButton.centerYAnchor.constraint(equalTo: buttonStackView.centerYAnchor),
            nextButton.trailingAnchor.constraint(equalTo: buttonStackView.trailingAnchor),
        ])
    }

    private func playNextAudioTrack() {
        removeTimer()
        dispatcher?.playNextAudioTrack()
    }

    private func playPreviousAudioTrack() {
        removeTimer()
        dispatcher?.playPreviousAudioTrack()
    }

    private func setupActions() {
        playButton.addAction(UIAction { [weak self] _ in self?.togglePlayState() }, for: .touchUpInside)

        nextButton.throttleTapPublisher(interval: 1.0)
            .sink { [weak self] _ in self?.playNextAudioTrack() }
            .store(in: &subscriptions)

        previousButton.throttleTapPublisher(interval: 1.0)
            .sink { [weak self] _ in self?.playPreviousAudioTrack() }
            .store(in: &subscriptions)
    }

    @objc private func sliderValueChanged(_ sender: UISlider) {
        removeTimer()
        currentTimeLabel.text = sender.value.asMinuteSecond
    }

    @objc private func sliderValuecomp(_ sender: UISlider) {
        dispatcher?.seekAudioTrack(seek: TimeInterval(sender.value))
        startTimer()
    }

    private func startTimer() {
        audioPlayTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
        audioPlayTimer?.schedule(deadline: .now(), repeating: 1)
        audioPlayTimer?
            .setEventHandler { [weak self] in
                guard let self else { return }
                UIView.animate(
                    withDuration: 1,
                    animations: {
                        self.slider.setValue(self.currentTime, animated: true)
                        self.nowPlayingInfo?.currentTime = TimeInterval(self.currentTime)
                    })
                currentTime = min(Float(duration!), currentTime + 1)
            }
        audioPlayTimer?.resume()
    }

    private func removeTimer() {
        audioPlayTimer?.cancel()
        audioPlayTimer = nil
    }

    private func updateNowPlayingInfo(with nowPlayInfo: NowPlayingInfo) {
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: nowPlayInfo.title,
            MPMediaItemPropertyArtist: nowPlayInfo.artist,
            MPMediaItemPropertyPlaybackDuration: nowPlayInfo.totalTime,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: nowPlayInfo.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: nowPlayInfo.playbackRate,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: nowPlayInfo.playbackRate,
        ]

        info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: nowPlayInfo.thumbname.size) { _ in
            nowPlayInfo.thumbname
        }
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = info
    }

    private func togglePlayState() {
        dispatcher?.togglePlayingState()
        isPlaying.toggle()
    }

    private func setupRemoteTransportControls() {

        UIApplication.shared.beginReceivingRemoteControlEvents()
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        remoteCommandCenter.togglePlayPauseCommand.removeTarget(nil)
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            togglePlayState()
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
            playNextAudioTrack()
            return .success
        }

        remoteCommandCenter.previousTrackCommand.removeTarget(nil)
        remoteCommandCenter.previousTrackCommand.isEnabled = true
        remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            playPreviousAudioTrack()
            return .success
        }
    }

    func configure(metadata: AudioTrackMetadata, duration: TimeInterval?, dispatcher: AudioComponentActionDispatcher) {
        self.dispatcher = dispatcher
        self.duration = duration
        isPlaying = true
        removeTimer()
        currentTime = .zero
        startTimer()

        playButton.isEnabled = true
        previousButton.isEnabled = true
        nextButton.isEnabled = true

        playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)

        slider.isUserInteractionEnabled = true
        slider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        slider.addTarget(
            self, action: #selector(sliderValuecomp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        if let title = metadata.title,
            let artist = metadata.artist,
            let thumbnailData = metadata.thumbnail,
            let thumbnail = UIImage(data: thumbnailData)
        {
            titleLabel.text = title
            artistLabel.text = artist
            thumbnailImageView.image = thumbnail
            currentTime = .zero

            if let duration {
                totalTimeLabel.text = duration.asMinuteSecond

                slider.minimumValue = .zero
                slider.maximumValue = Float(duration)

                nowPlayingInfo = NowPlayingInfo(
                    title: title,
                    artist: artist,
                    thumbname: thumbnail,
                    totalTime: duration,
                    currentTime: .zero,
                    playbackRate: 1.0)

                updateNowPlayingInfo(with: nowPlayingInfo!)
                setupRemoteTransportControls()
            }
        }
    }

    func setControlBarState(isPlaying: Bool, currentTime: TimeInterval?) {
        self.isPlaying = isPlaying
        if isPlaying {
            playButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            nowPlayingInfo?.playbackRate = 1.0
            updateNowPlayingInfo(with: nowPlayingInfo!)
            self.currentTime = Float(currentTime!)
            startTimer()
        } else {
            playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            nowPlayingInfo?.playbackRate = 0.0
            updateNowPlayingInfo(with: nowPlayingInfo!)
            removeTimer()
        }
    }

    func seek(seek: TimeInterval) {
        nowPlayingInfo?.currentTime = seek
        updateNowPlayingInfo(with: nowPlayingInfo!)
        slider.setValue(Float(seek), animated: true)
        currentTime = Float(seek)
        if isPlaying { startTimer() }
    }

    func updateControlBarStateToNotPlaying() {
        UIView.animate(withDuration: 1) { self.slider.setValue(.zero, animated: true) }
        titleLabel.text = "Not Playing"
        artistLabel.text = "UnKnown"
        thumbnailImageView.image = UIImage(named: "defaultMusicThumbnail")
        playButton.isEnabled = false
        previousButton.isEnabled = false
        nextButton.isEnabled = false
        removeTimer()
        currentTimeLabel.text = "0:00"
        totalTimeLabel.text = "0:00"
        slider.setValue(.zero, animated: true)
        slider.isUserInteractionEnabled = false
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func update(with data: AudioTrackMetadata) {
        titleLabel.text = data.title
        artistLabel.text = data.artist
        if let thumbnailData = data.thumbnail {
            thumbnailImageView.image = UIImage(data: thumbnailData)
        }

    }
}

final class NowPlayingInfo {
    var title: String
    var artist: String
    var thumbname: UIImage
    var totalTime: TimeInterval
    var currentTime: TimeInterval
    var playbackRate: NSNumber

    init(
        title: String,
        artist: String,
        thumbname: UIImage,
        totalTime: TimeInterval,
        currentTime: TimeInterval,
        playbackRate: NSNumber
    ) {
        self.title = title
        self.artist = artist
        self.thumbname = thumbname
        self.totalTime = totalTime
        self.currentTime = currentTime
        self.playbackRate = playbackRate
    }
}
