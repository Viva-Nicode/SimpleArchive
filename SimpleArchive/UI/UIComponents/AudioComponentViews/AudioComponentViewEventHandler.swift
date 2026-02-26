import Combine
import UIKit

@MainActor protocol ComponentViewEventHandlerType {
    associatedtype EventType
    func UIupdateEventHandler(_ event: EventType)
}

final class AudioComponentViewEventHandler: ComponentViewEventHandlerType {
    private var componentView: AudioComponentView
    private var audioMetaDataEditPopupViewSubscription: AnyCancellable?

    init(componentView: AudioComponentView) {
        self.componentView = componentView
    }

    func UIupdateEventHandler(_ event: AudioComponentViewModel.Event) {
        switch event {
            case .didPlayAudioTrack(let trackIndex, let audioMetadata, let audioWaveformData):
                let trackIndexPath = IndexPath(row: trackIndex, section: .zero)

                if let row = componentView.componentContentView.audioTrackTableView.cellForRow(at: trackIndexPath),
                    let targetPlayingAudioRow = row as? AudioTableRowView,
                    let audioWaveformData
                {
                    targetPlayingAudioRow.audioVisualizer.activateAudioVisualizer(waveFormData: audioWaveformData)
                }

                componentView.componentContentView.activeAudioControlBar(audioMetadata: audioMetadata)

            case .didToggleAudioPlayingState(let trackIndex, let playbackState):
                let memoPageViewController = componentView.parentViewController as? MemoPageViewController
                let audioControlBar = memoPageViewController?.audioControlBar

                audioControlBar?.state = playbackState ? .resume : .pause

                let trackIndexPath = IndexPath(row: trackIndex, section: .zero)

                if let row = componentView.componentContentView.audioTrackTableView.cellForRow(at: trackIndexPath),
                    let audioRow = row as? AudioTableRowView
                {
                    if playbackState {
                        audioRow.audioVisualizer.resumeVisuzlization()
                    } else {
                        audioRow.audioVisualizer.pauseVisuzlization()
                    }
                }

            case .didSeekAudioTrack(let trackIndex, let seek, let total):
                let memoPageViewController = componentView.parentViewController as? MemoPageViewController
                let audioControlBar = memoPageViewController?.audioControlBar

                let indexPath = IndexPath(row: trackIndex, section: 0)
                if let row = componentView.componentContentView.audioTrackTableView.cellForRow(at: indexPath),
                    let audioRow = row as? AudioTableRowView
                {
                    audioRow.audioVisualizer.seekVisuzlization(rate: seek / total)
                    audioControlBar?.seek(seek: seek)
                }

            case .didPresentEditAudioMetaDataPopupView(let metaData):
                let audioTrackEditPopupView = AudioTrackEditPopupView(metadata: metaData)

                audioMetaDataEditPopupViewSubscription = audioTrackEditPopupView.confirmButtonPublisher
                    .sink { [weak self] editedMetadata in
                        guard let self else { return }
                        audioTrackEditPopupView.dismiss()
                        componentView.componentContentView.applyMetaDataChange(editedMetadata: editedMetadata)
                        audioMetaDataEditPopupViewSubscription = nil
                    }
                audioTrackEditPopupView.show()

            case .didApplyAudioMetadataChanges(let editResult, let metadata):
                let trackIndexPath = IndexPath(row: editResult.trackIndex, section: 0)
                if let row = componentView.componentContentView.audioTrackTableView.cellForRow(at: trackIndexPath),
                    let audioTableRowView = row as? AudioTableRowView
                {
                    audioTableRowView.updateAudioMetadata(metadata)
                }

                if editResult.isEditingActiveTrack {
                    let memoPageViewController = componentView.parentViewController as? MemoPageViewController
                    let audioControlBar = memoPageViewController?.audioControlBar
                    audioControlBar?.applyUpdatedMetadata(with: metadata)
                }

                if let trackIndexAfterChanges = editResult.trackIndexAfterEditing {
                    componentView.componentContentView.audioTrackTableView.performBatchUpdates {
                        let src = IndexPath(row: editResult.trackIndex, section: .zero)
                        let des = IndexPath(row: trackIndexAfterChanges, section: .zero)
                        componentView.componentContentView.audioTrackTableView.moveRow(at: src, to: des)
                    }
                }

            case .didInactiveAudioComponent:
                componentView
                    .componentContentView
                    .audioTrackTableView
                    .visibleCells
                    .map { $0 as! AudioTableRowView }
                    .forEach { $0.audioVisualizer.removeVisuzlization() }

            case .didPresentInvalidDownloadCode:
                componentView
                    .componentContentView
                    .audioDownloadStatePopupView?
                    .setStateToFail()

            case .didUpdateAudioDownloadProgress(let progressRatio):
                componentView
                    .componentContentView
                    .audioDownloadStatePopupView?
                    .progress
                    .setProgress(progressRatio, animated: true)

            case .didAppendAudioTrackRows(let appendedIndices):
                componentView
                    .componentContentView
                    .audioDownloadStatePopupView?
                    .dismiss()
                componentView
                    .componentContentView
                    .insertRow(trackIndices: appendedIndices)

            case .didSortAudioTracks(let sortResult):
                let audioTracks = componentView.componentContentView.audioTrackTableView
                audioTracks.performBatchUpdates {
                    for (i, v) in sortResult.enumerated() {
                        let beforeIndexPath = IndexPath(row: i, section: 0)
                        let afterIndexPath = IndexPath(row: v, section: 0)
                        audioTracks.moveRow(at: afterIndexPath, to: beforeIndexPath)
                    }
                }

            case .didRemoveAudioTrack(let trackIndex):
                componentView.componentContentView.removeRow(trackIndex: trackIndex)

            case .didRemoveAudioTrackAndStopPlaying(let trackIndex):
                let memoPageViewController = componentView.parentViewController as? MemoPageViewController
                let audioControlBar = memoPageViewController?.audioControlBar

                audioControlBar?.isHidden = true
                audioControlBar?.state = .stop

                let removeTrackIndexPath = IndexPath(row: trackIndex, section: .zero)
                if let row = componentView.componentContentView.audioTrackTableView.cellForRow(
                    at: removeTrackIndexPath),
                    let targetPlayingAudioRow = row as? AudioTableRowView
                {
                    targetPlayingAudioRow.audioVisualizer.removeVisuzlization()
                }

                componentView.componentContentView.removeRow(trackIndex: trackIndex)
        }
    }
}
