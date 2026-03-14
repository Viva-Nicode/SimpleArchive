import Foundation

class ThinAudioControlBarEventHandler: ComponentViewEventHandlerType {
    private var host: AudioControlBarHostType
	private var list:ExpendedAudioControlBarTrackListView?

    init(host: AudioControlBarHostType) {
        self.host = host
    }

    func UIupdateEventHandler(_ event: AudioComponentViewModel.Event) {
        switch event {
			case .didPlayAudioTrack(let trackIndex, let audioMetadata, let audioWaveformData):
				let trackIndexPath = IndexPath(row: trackIndex, section: .zero)

				
				if let row = list?.tableView.cellForRow(at: trackIndexPath),
					let targetPlayingAudioRow = row as? AudioTableRowView,
					let audioWaveformData
				{
					targetPlayingAudioRow.audioVisualizer.activateAudioVisualizer(waveFormData: audioWaveformData)
				}
				
                host.activeAudioControlBar(audioMetadata: audioMetadata, dispatcher: nil)

			case .didInactiveAudioComponent:
				list?
					.tableView
					.visibleCells
					.map { $0 as! AudioTableRowView }
					.forEach { $0.audioVisualizer.removeVisuzlization() }
				
            case .didToggleAudioPlayingState(let trackIndex, let playbackState):
                host.toggleAudioControlBarPlayBackState(playbackState: playbackState)
				
				let trackIndexPath = IndexPath(row: trackIndex, section: .zero)

				if let row = list?.tableView.cellForRow(at: trackIndexPath),
					let audioRow = row as? AudioTableRowView
				{
					if playbackState {
						audioRow.audioVisualizer.resumeVisuzlization()
					} else {
						audioRow.audioVisualizer.pauseVisuzlization()
					}
				}

            case .didSeekAudioTrack(_, let seek, _):
                host.seekAudioControlBarPlayProgress(seek: seek)
				
			case .didDismissAudioControlBar:
				host.stopAudioControlBar()
				
			case .didChangeAudioSessionStateAsThin(let audioComponent):
				list = host.setListiViewData(data: audioComponent)
				
            default:
                break
        }
    }
}
