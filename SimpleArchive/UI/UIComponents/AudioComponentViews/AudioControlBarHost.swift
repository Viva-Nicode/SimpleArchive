import Foundation

@MainActor protocol AudioControlBarHost: AnyObject {
    var audioControlBar: AudioControlBarView { get }
    var strategy: AudioControlBarActionStrategy? { get set }

    func activeAudioControlBar(audioMetadata: AudioTrackMetadata, dispatcher: AudioComponentActionDispatcher?)
    func toggleAudioControlBarPlayBackState(playbackState: Bool)
    func applyMetadataChangeToAudioControlBar(audioMetadata: AudioTrackMetadata)
    func seekAudioControlBarPlayProgress(seek: TimeInterval)
    func stopAudioControlBar()
    func setStrategy(st: AudioControlBarActionStrategy)
    func transformOuter()
}

extension AudioControlBarHost {
    func activeAudioControlBar(audioMetadata: AudioTrackMetadata, dispatcher: AudioComponentActionDispatcher?) {
        strategy?.active(audioControlBar: audioControlBar, audioMetadata: audioMetadata, dispatcher: dispatcher)
    }

    func seekAudioControlBarPlayProgress(seek: TimeInterval) {
        strategy?.seek(audioControlBar: audioControlBar, seek: seek)
    }

    func applyMetadataChangeToAudioControlBar(audioMetadata: AudioTrackMetadata) {
        strategy?.applyMetadataChange(audioControlBar: audioControlBar, audioMetadata: audioMetadata)
    }

    func toggleAudioControlBarPlayBackState(playbackState: Bool) {
        strategy?.toggle(audioControlBar: audioControlBar, playbackState: playbackState)
    }

    func stopAudioControlBar() {
        strategy?.stop(audioControlBar: audioControlBar)
    }

    func setStrategy(st: AudioControlBarActionStrategy) {
        strategy = nil
        self.strategy = st
    }
}

protocol AudioControlBarActionStrategy {
    func active(
        audioControlBar: AudioControlBarView,
        audioMetadata: AudioTrackMetadata,
        dispatcher: AudioComponentActionDispatcher?)
    func seek(audioControlBar: AudioControlBarView, seek: TimeInterval)
    func toggle(audioControlBar: AudioControlBarView, playbackState: Bool)
    func applyMetadataChange(audioControlBar: AudioControlBarView, audioMetadata: AudioTrackMetadata)
    func stop(audioControlBar: AudioControlBarView)
}

extension AudioControlBarActionStrategy {
    func active(
        audioControlBar: AudioControlBarView,
        audioMetadata: AudioTrackMetadata,
        dispatcher: AudioComponentActionDispatcher?
    ) {
        audioControlBar.isHidden = false
        audioControlBar.state = .play(metadata: audioMetadata, dispatcher: dispatcher)
    }

    func seek(audioControlBar: AudioControlBarView, seek: TimeInterval) {
        audioControlBar.seek(seek: seek)
    }

    func toggle(
        audioControlBar: AudioControlBarView,
        playbackState: Bool
    ) { audioControlBar.state = playbackState ? .resume : .pause }

    func applyMetadataChange(
        audioControlBar: AudioControlBarView,
        audioMetadata: AudioTrackMetadata
    ) { audioControlBar.applyUpdatedMetadata(with: audioMetadata) }

    func stop(audioControlBar: AudioControlBarView) {
        audioControlBar.state = .stop
        audioControlBar.isHidden = true
    }
}
