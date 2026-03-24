import Combine
import UIKit

@MainActor protocol ComponentViewEventHandlerType {
    associatedtype EventType
    func UIupdateEventHandler(_ event: EventType)
}

class AudioComponentViewEventHandler: ComponentViewEventHandlerType {
    private var componentView: AudioComponentContentView
    private var audioControlBarHost: AudioControlBarHostType
    private var audioMetaDataEditPopupViewSubscription: AnyCancellable?

    init(componentView: AudioComponentContentView, audioControlBarHost: AudioControlBarHostType) {
        self.componentView = componentView
        self.audioControlBarHost = audioControlBarHost
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    func UIupdateEventHandler(_ event: AudioComponentViewModel.Event) {
        switch event {
            case .didPlayAudioTrack(let trackIndex, let audioMetadata, let audioWaveformData):
                let trackIndexPath = IndexPath(row: trackIndex, section: .zero)

                if let row = componentView.audioTrackTableView.cellForRow(at: trackIndexPath),
                    let targetPlayingAudioRow = row as? AudioTableRowView,
                    let audioWaveformData
                {
                    targetPlayingAudioRow.audioVisualizer.activateAudioVisualizer(waveFormData: audioWaveformData)
                }

                audioControlBarHost.activeAudioControlBar(
                    audioMetadata: audioMetadata,
                    dispatcher: componentView.dispatcher)

                if let vc = componentView.parentViewController as? SingleAudioPageViewController,
                    let thumbnailData = audioMetadata.thumbnail,
                    let thumbnail = UIImage(data: thumbnailData)
                {
                    vc.updateBackgroundImage(with: thumbnail)
                }

            case .didToggleAudioPlayingState(let trackIndex, let playbackState):
                audioControlBarHost.toggleAudioControlBarPlayBackState(playbackState: playbackState)

                let trackIndexPath = IndexPath(row: trackIndex, section: .zero)

                if let row = componentView.audioTrackTableView.cellForRow(at: trackIndexPath),
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
                if let row = componentView.audioTrackTableView.cellForRow(at: indexPath),
                    let audioRow = row as? AudioTableRowView
                {
                    audioRow.audioVisualizer.seekVisuzlization(rate: seek / total)
                }

            case .didPresentEditAudioMetaDataPopupView(let metaData):
                let audioTrackEditPopupView = AudioTrackEditPopupView(metadata: metaData)

                audioMetaDataEditPopupViewSubscription = audioTrackEditPopupView.confirmButtonPublisher
                    .sink { [weak self] editedMetadata in
                        guard let self else { return }
                        audioTrackEditPopupView.dismiss()
                        componentView.dispatcher?.changeAudioTrackMetadata(editMetadata: editedMetadata)
                        audioMetaDataEditPopupViewSubscription = nil
                    }
                audioTrackEditPopupView.show()

            case .didApplyAudioMetadataChanges(let editResult, let metadata):
                let trackIndexPath = IndexPath(row: editResult.trackIndex, section: 0)
                if let row = componentView.audioTrackTableView.cellForRow(at: trackIndexPath),
                    let audioTableRowView = row as? AudioTableRowView
                {
                    audioTableRowView.updateAudioMetadata(metadata)
                }

                if editResult.isEditingActiveTrack {
                    audioControlBarHost.applyMetadataChangeToAudioControlBar(audioMetadata: metadata)

                    if let vc = componentView.parentViewController as? SingleAudioPageViewController,
                        let thumbnailData = metadata.thumbnail,
                        let thumbnail = UIImage(data: thumbnailData)
                    {
                        vc.updateBackgroundImage(with: thumbnail)
                    }
                }

                if let trackIndexAfterChanges = editResult.trackIndexAfterEditing {
                    componentView.audioTrackTableView.performBatchUpdates {
                        let src = IndexPath(row: editResult.trackIndex, section: .zero)
                        let des = IndexPath(row: trackIndexAfterChanges, section: .zero)
                        componentView.audioTrackTableView.moveRow(at: src, to: des)
                    }
                }

            case .didInactiveAudioComponent:
                componentView
                    .audioTrackTableView
                    .visibleCells
                    .map { $0 as! AudioTableRowView }
                    .forEach { $0.audioVisualizer.removeVisuzlization() }

            case .didPresentInvalidDownloadCode:
                componentView
                    .audioDownloadStatePopupView?
                    .setStateToFail()

            case .didUpdateAudioDownloadProgress(let progressRatio):
                componentView
                    .audioDownloadStatePopupView?
                    .progress
                    .setProgress(progressRatio, animated: true)

            case .didAppendAudioTrackRows(let appendedIndices):
                componentView
                    .audioDownloadStatePopupView?
                    .dismiss()
                componentView
                    .insertRow(trackIndices: appendedIndices)

            case .didSortAudioTracks(let sortResult):
                let audioTracks = componentView.audioTrackTableView
                audioTracks.performBatchUpdates {
                    for (i, v) in sortResult.enumerated() {
                        let beforeIndexPath = IndexPath(row: i, section: 0)
                        let afterIndexPath = IndexPath(row: v, section: 0)
                        audioTracks.moveRow(at: afterIndexPath, to: beforeIndexPath)
                    }
                }

            case .didRemoveAudioTrack(let trackIndex):
                componentView.removeRow(trackIndex: trackIndex)

            case .didRemoveAudioTrackAndStopPlaying(let trackIndex):
                audioControlBarHost.stopAudioControlBar()

                let removeTrackIndexPath = IndexPath(row: trackIndex, section: .zero)
                if let row = componentView.audioTrackTableView.cellForRow(
                    at: removeTrackIndexPath),
                    let targetPlayingAudioRow = row as? AudioTableRowView
                {
                    targetPlayingAudioRow.audioVisualizer.removeVisuzlization()
                }

                componentView.removeRow(trackIndex: trackIndex)

            case .didScrollToActiveAudioTrack(let activeAudioTrackIndex):
                if let c: AudioComponentView = componentView.findSuperViewMatched(),
                    let collectionView = c.collectionView,
                    let ii = AudioComponentView.audioComponentOrder[c.componentID]
                {
                    collectionView.scrollToItem(at: ii, at: .centeredVertically, animated: true)
                }
                let indexPath = IndexPath(row: activeAudioTrackIndex, section: 0)
                componentView.audioTrackTableView.scrollToRow(at: indexPath, at: .middle, animated: true)

            case .didDismissAudioControlBar:
                audioControlBarHost.stopAudioControlBar()

                componentView
                    .audioTrackTableView
                    .visibleCells
                    .map { $0 as! AudioTableRowView }
                    .forEach { $0.audioVisualizer.removeVisuzlization() }

            default:
                break
        }
    }
}
