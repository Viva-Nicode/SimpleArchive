import AVFAudio
import Combine
import Foundation
import MediaPlayer

final class AudioComponentSoundPlayer: NSObject, AudioComponentSoundPlayerType, LockScreenAudioControllable {

    static let shared: AudioComponentSoundPlayerType = AudioComponentSoundPlayer()

    private var audioPlayer: AVAudioPlayer?
    private var activeAudioTrackData = ActiveAudioTrackVisualizerData()
    private var lockScreenAudioControlBar: LockScreenAudioControlBarInterface?
    private var viewModelUseInterface: AudioComponentVMUseInterface?

    var activeTrackID: UUID? { activeAudioTrackData.nowPlayingAudioTrackID }
    var activeTrackVisualizerData: PlayBackVisualizer { activeAudioTrackData }
    var isPlaying: Bool { audioPlayer?.isPlaying ?? false }
    var currentTime: TimeInterval? { audioPlayer?.currentTime }
    var nowActiveAudioVMIdentifier: ObjectIdentifier? {
        if let viewModelUseInterface {
            return ObjectIdentifier(viewModelUseInterface)
        } else {
            return nil
        }
    }

    private override init() {
        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pauseAudioOnInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    func setLockScreenAudioContoller(with lockScreenAudioController: LockScreenAudioControlBarInterface) {
        self.lockScreenAudioControlBar = lockScreenAudioController
        self.lockScreenAudioControlBar?.audioPlayerController = self
    }

    func play(
        viewModelUseInterface: AudioComponentVMUseInterface,
        activeAudioData: ActiveAudioTrackVisualizerData,
        audioMetaData: AudioTrackMetadata,
        audioFileURL: URL
    ) {
        activeAudioTrackData.replaceVisualizerData(other: activeAudioData)

        self.viewModelUseInterface?.inactive()
        self.viewModelUseInterface = viewModelUseInterface

        lockScreenAudioControlBar?.configurePlayback(metadata: audioMetaData)

        audioPlayer = try? AVAudioPlayer(contentsOf: audioFileURL)
        audioPlayer?.prepareToPlay()
        audioPlayer?.delegate = self
        audioPlayer?.play()
    }

    func togglePlaybackState() -> Bool? {
        guard let player = audioPlayer else { return nil }

        if player.isPlaying {
            player.pause()
            lockScreenAudioControlBar?.pause()
        } else {
            player.play()
            lockScreenAudioControlBar?.resume()
        }

        let playbackState = player.isPlaying

        activeAudioTrackData.isPlaying = playbackState
        activeAudioTrackData.hasChangePlayingState()

        return playbackState
    }

    func seek(time: TimeInterval) -> TimeInterval? {
        guard let player = audioPlayer else { return nil }
        let newTime = max(0, min(time, player.duration))
        player.currentTime = newTime

        activeAudioTrackData.seek(seek: time)
        lockScreenAudioControlBar?.setCurrentTime()
        return player.duration
    }

    func applyMetadataChange(metadata: AudioTrackMetadata) {
        lockScreenAudioControlBar?.applyUpdatedMetadata(metadata: metadata)
    }

    func stopPlaying() {
        audioPlayer = nil
        viewModelUseInterface = nil
        activeAudioTrackData.clean()
        lockScreenAudioControlBar?.stop()
    }

    @objc private func pauseAudioOnInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue),
            let audioPlayer
        else { return }

        switch type {
            case .began:
                if audioPlayer.isPlaying { viewModelUseInterface?.toggle() }

            case .ended:
                if !audioPlayer.isPlaying { viewModelUseInterface?.toggle() }

            @unknown default:
                print("unknown interrupt")
        }
    }
}

extension AudioComponentSoundPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        viewModelUseInterface?.playNextAudio()
    }
}

extension AudioComponentSoundPlayer: LockScreenNowPlayingAudioControlsInterface {
    func togglePlaybackStateFromLockScreen() { viewModelUseInterface?.toggle() }
    func playNextTrackFromLockScreen() { viewModelUseInterface?.playNextAudio() }
    func playPreviousTrackFromLockScreen() { viewModelUseInterface?.previous() }
    func seekFromLockScreen(seek: TimeInterval) { viewModelUseInterface?.seek(seek: seek) }
}
