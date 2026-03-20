import Foundation

final class ContinuousPlaybackControlBarEventHandler: ComponentViewEventHandlerType {
    private var audioControlBarHost: AudioControlBarHostType
    private var expendedAudioList: ExpendedAudioControlBarTrackListView

    init(audioControlBarHost: AudioControlBarHostType, expendedAudioList: ExpendedAudioControlBarTrackListView) {
        self.audioControlBarHost = audioControlBarHost
        self.expendedAudioList = expendedAudioList
    }

    func UIupdateEventHandler(_ event: AudioComponentViewModel.Event) {
        switch event {
            case .didChangeAudioSessionStateAsThin(let audioComponent, let index):
                expendedAudioList.configure(audioComponent: audioComponent)
                let indexPaht = IndexPath(row: index, section: 0)
                expendedAudioList.audioTrackTableView.scrollToRow(at: indexPaht, at: .middle, animated: false)

            case .didPlayAudioTrack(let trackIndex, let audioMetadata, let audioWaveformData):
                let trackIndexPath = IndexPath(row: trackIndex, section: .zero)

                if let row = expendedAudioList.audioTrackTableView.cellForRow(at: trackIndexPath),
                    let targetPlayingAudioRow = row as? AudioTableRowView,
                    let audioWaveformData
                {
                    targetPlayingAudioRow.audioVisualizer.activateAudioVisualizer(waveFormData: audioWaveformData)
                }

                audioControlBarHost.activeAudioControlBar(audioMetadata: audioMetadata, dispatcher: nil)

            case .didInactiveAudioComponent:
                expendedAudioList
                    .audioTrackTableView
                    .visibleCells
                    .map { $0 as! AudioTableRowView }
                    .forEach { $0.audioVisualizer.removeVisuzlization() }

            case .didToggleAudioPlayingState(let trackIndex, let playbackState):
                audioControlBarHost.toggleAudioControlBarPlayBackState(playbackState: playbackState)

                let trackIndexPath = IndexPath(row: trackIndex, section: .zero)

                if let row = expendedAudioList.audioTrackTableView.cellForRow(at: trackIndexPath),
                    let audioRow = row as? AudioTableRowView
                {
                    if playbackState {
                        audioRow.audioVisualizer.resumeVisuzlization()
                    } else {
                        audioRow.audioVisualizer.pauseVisuzlization()
                    }
                }

            case .didSeekAudioTrack(let trackIndex, let seek, let total):
                audioControlBarHost.seekAudioControlBarPlayProgress(seek: seek)

                let indexPath = IndexPath(row: trackIndex, section: 0)
                if let row = expendedAudioList.audioTrackTableView.cellForRow(at: indexPath),
                    let audioRow = row as? AudioTableRowView
                {
                    audioRow.audioVisualizer.seekVisuzlization(rate: seek / total)
                }

            case .didDismissAudioControlBar:
                audioControlBarHost.stopAudioControlBar()

            case .didScrollToActiveAudioTrack(let activeAudioTrackIndex):
                let indexPath = IndexPath(row: activeAudioTrackIndex, section: 0)
                expendedAudioList.audioTrackTableView.scrollToRow(at: indexPath, at: .middle, animated: true)

            default:
                break
        }
    }
}
