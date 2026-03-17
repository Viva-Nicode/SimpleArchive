import Foundation

class ThinAudioControlBarEventHandler: ComponentViewEventHandlerType {
    private var host: AudioControlBarHostType
    private var list: ExpendedAudioControlBarTrackListView

    init(host: AudioControlBarHostType, list: ExpendedAudioControlBarTrackListView) {
        self.host = host
        self.list = list
    }

    func UIupdateEventHandler(_ event: AudioComponentViewModel.Event) {
        switch event {
            case .didChangeAudioSessionStateAsThin(let audioComponent, let index):
                list.configure(audioComponent: audioComponent)
                let indexPaht = IndexPath(row: index, section: 0)
                list.tableView.scrollToRow(at: indexPaht, at: .middle, animated: false)

            case .didPlayAudioTrack(let trackIndex, let audioMetadata, let audioWaveformData):
                let trackIndexPath = IndexPath(row: trackIndex, section: .zero)

                if let row = list.tableView.cellForRow(at: trackIndexPath),
                    let targetPlayingAudioRow = row as? AudioTableRowView,
                    let audioWaveformData
                {
                    targetPlayingAudioRow.audioVisualizer.activateAudioVisualizer(waveFormData: audioWaveformData)
                }

                host.activeAudioControlBar(audioMetadata: audioMetadata, dispatcher: nil)

            case .didInactiveAudioComponent:
                list
                    .tableView
                    .visibleCells
                    .map { $0 as! AudioTableRowView }
                    .forEach { $0.audioVisualizer.removeVisuzlization() }

            case .didToggleAudioPlayingState(let trackIndex, let playbackState):
                host.toggleAudioControlBarPlayBackState(playbackState: playbackState)

                let trackIndexPath = IndexPath(row: trackIndex, section: .zero)

                if let row = list.tableView.cellForRow(at: trackIndexPath),
                    let audioRow = row as? AudioTableRowView
                {
                    if playbackState {
                        audioRow.audioVisualizer.resumeVisuzlization()
                    } else {
                        audioRow.audioVisualizer.pauseVisuzlization()
                    }
                }

            case .didSeekAudioTrack(let trackIndex, let seek, let total):
                host.seekAudioControlBarPlayProgress(seek: seek)

                let indexPath = IndexPath(row: trackIndex, section: 0)
                if let row = list.tableView.cellForRow(at: indexPath),
                    let audioRow = row as? AudioTableRowView
                {
                    audioRow.audioVisualizer.seekVisuzlization(rate: seek / total)
                }

            case .didDismissAudioControlBar:
                host.stopAudioControlBar()

            case .didScrollToActiveAudioTrack(let activeAudioTrackIndex):
                let indexPath = IndexPath(row: activeAudioTrackIndex, section: 0)
                list.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)

            default:
                break
        }
    }
}
