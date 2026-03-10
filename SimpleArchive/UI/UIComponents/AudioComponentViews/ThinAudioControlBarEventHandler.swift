
class ThinAudioControlBarEventHandler: ComponentViewEventHandlerType {
    private var host: AudioControlBarHostType

    init(host: AudioControlBarHostType) {
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
				
			case .didDismissAudioControlBar:
				host.stopAudioControlBar()

            default:
                break
        }
    }
}
