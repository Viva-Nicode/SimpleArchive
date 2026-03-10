import Combine
import Foundation

// 사운드 플레이어를 제어하기 위해 뷰모델이 사용하는 인터페이스
@MainActor protocol AudioComponentSoundPlayerType {
    var activeTrackID: UUID? { get }
    var isPlaying: Bool { get }
    var activeTrackVisualizerData: PlayBackVisualizer { get }
    var nowActiveAudioVMIdentifier: ObjectIdentifier? { get }

    func play(
        viewModelUseInterface: AudioComponentVMUseInterface,
        activeAudioData: ActiveAudioTrackVisualizerData,
        audioMetaData: AudioTrackMetadata,
        audioFileURL: URL
    )
    func togglePlaybackState() -> Bool?
    func seek(time: TimeInterval) -> TimeInterval?
    func applyMetadataChange(metadata: AudioTrackMetadata)
    func stopPlaying()
}

// 뷰모델을 제어하기 위해 사운드 플레이어가 사용하는 인터페이스
protocol AudioComponentVMUseInterface: AnyObject {
    func toggle()
    func playNextAudio()
    func previous()
    func seek(seek: TimeInterval)
    func inactive()
}

// 락스크린을 제어하기 위해 사운드 플레이어가 사용하는 인터페이스
protocol LockScreenAudioControlBarInterface {
    var audioPlayerController: LockScreenNowPlayingAudioControlsInterface? { get set }

    func configurePlayback(metadata: AudioTrackMetadata)
    func applyUpdatedMetadata(metadata: AudioTrackMetadata)
    func pause()
    func resume()
    func stop()
    func setCurrentTime()
}

// 사운드 플레이어를 제어하기 위해 락스크린이 사용하는 인터페이스
protocol LockScreenNowPlayingAudioControlsInterface: NSObject {
    var currentTime: TimeInterval? { get }

    func togglePlaybackStateFromLockScreen()
    func seekFromLockScreen(seek: TimeInterval)
    func playNextTrackFromLockScreen()
    func playPreviousTrackFromLockScreen()
}

// DI에서 잠금화면 오디오 컨트롤러 주입할떄 쓰는 타입
protocol LockScreenAudioControllable {
    func setLockScreenAudioContoller(with lockScreenAudioController: LockScreenAudioControlBarInterface)
}
