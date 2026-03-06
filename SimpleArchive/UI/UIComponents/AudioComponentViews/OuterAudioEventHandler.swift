class OuterAduioEventHandler: ComponentViewEventHandlerType {
    private var host: AudioControlBarHost

    init(host: AudioControlBarHost) {
        self.host = host
    }

    func UIupdateEventHandler(_ event: AudioComponentViewModel.Event) {
        switch event {
            case .didPlayAudioTrack(_, let audioMetadata, _):
                host.activeAudioControlBar(audioMetadata: audioMetadata, dispatcher: nil)

            case .didToggleAudioPlayingState(_, let playbackState):
                host.toggleAudioControlBarPlayBackState(playbackState: playbackState)

            case .didSeekAudioTrack(_, let seek, _):
                host.seekAudioControlBarPlayProgress(seek: seek)

            default:
                break
        }
    }
}
