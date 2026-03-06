import Foundation
import MediaPlayer

final class NowPlayingInfoCenterController: LockScreenAudioControlBarInterface {
    private var nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    weak var audioPlayerController: LockScreenNowPlayingAudioControlsInterface?

    func configurePlayback(metadata: AudioTrackMetadata) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)

        if let title = metadata.title,
            let artist = metadata.artist,
            let thumbnailData = metadata.thumbnail,
            let thumbnail = UIImage(data: thumbnailData),
            let duration = metadata.duration
        {
            var info: [String: Any] = [
                MPMediaItemPropertyTitle: title,
                MPMediaItemPropertyArtist: artist,
                MPMediaItemPropertyPlaybackDuration: duration,
                MPNowPlayingInfoPropertyElapsedPlaybackTime: 0.0,
                MPNowPlayingInfoPropertyPlaybackRate: 1.0,
            ]

            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: thumbnail.size) { _ in thumbnail }

            nowPlayingInfoCenter.nowPlayingInfo = info
            setupRemoteTransportControls()
        }
    }

    func pause() {
        setCurrentTime()
        nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
    }

    func resume() {
        setCurrentTime()
        nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
    }

    func applyUpdatedMetadata(metadata: AudioTrackMetadata) {
        setCurrentTime()
        nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyTitle] = metadata.title
        nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtist] = metadata.artist

        if let thumbnailData = metadata.thumbnail,
            let thumbnailImage = UIImage(data: thumbnailData)
        {
            nowPlayingInfoCenter.nowPlayingInfo?[MPMediaItemPropertyArtwork] =
                MPMediaItemArtwork(boundsSize: thumbnailImage.size) { _ in thumbnailImage }
        }
    }

    func setCurrentTime() {
        let time = audioPlayerController?.currentTime
        nowPlayingInfoCenter.nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
    }

    func stop() {
        try? AVAudioSession.sharedInstance().setActive(false)
        nowPlayingInfoCenter.nowPlayingInfo = nil
    }

    private func setupRemoteTransportControls() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let remoteCommandCenter = MPRemoteCommandCenter.shared()

        remoteCommandCenter.togglePlayPauseCommand.removeTarget(nil)
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            setCurrentTime()
            audioPlayerController?.togglePlaybackStateFromLockScreen()
            return .success
        }

        remoteCommandCenter.changePlaybackPositionCommand.removeTarget(nil)
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
        remoteCommandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self else { return .commandFailed }

            if let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                let newTime = positionEvent.positionTime
                audioPlayerController?.seekFromLockScreen(seek: newTime)
                return .success
            }
            return .commandFailed
        }

        remoteCommandCenter.nextTrackCommand.removeTarget(nil)
        remoteCommandCenter.nextTrackCommand.isEnabled = true
        remoteCommandCenter.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            audioPlayerController?.playNextTrackFromLockScreen()
            return .success
        }

        remoteCommandCenter.previousTrackCommand.removeTarget(nil)
        remoteCommandCenter.previousTrackCommand.isEnabled = true
        remoteCommandCenter.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            audioPlayerController?.playPreviousTrackFromLockScreen()
            return .success
        }
    }
}
