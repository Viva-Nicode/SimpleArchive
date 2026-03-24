import Combine
import Foundation
import UIKit

class AudioComponentViewModel: PageComponentViewModelType {
    var subscriptions = Set<AnyCancellable>()

    private var eventOutput = PassthroughSubject<Event, Never>()
    private var audioDataManager: AudioComponentDataManger
    private var soundPlayer: AudioComponentSoundPlayerType
    private var vmIdentifier: ObjectIdentifier { .init(self) }

    init(
        audioDataManager: AudioComponentDataManger,
        soundPlayer: AudioComponentSoundPlayerType
    ) {
        self.audioDataManager = audioDataManager
        self.soundPlayer = soundPlayer
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    func bindToView(input: AnyPublisher<Action, Never>) -> AnyPublisher<Event, Never> {
        input.sink { [weak self] action in
            guard let self else { return }
            switch action {
                case .willDownloadMusicWithCode(let code):
                    downloadAudioTracksUsingCode(using: code)

                case .willImportAudioFileFromFileSystem(let selectedAudioURLs):
                    importAudiosFromLocal(selectedAudioURLs: selectedAudioURLs)

                case .willPlayAudioTrack(let trackIndex):
                    playAudioTrack(trackIndex: trackIndex)

                case .willToggleAudioPlayingState:
                    toggleAudioPlayingState()

                case .willPlayNextAudioTrack:
                    playNextAudioTrack()

                case .willPlayPreviousAudioTrack:
                    playPreviousAudioTrack()

                case .willSeekAudioTrack(let seek):
                    seekAudioTrack(seek: seek)

                case .willPresentEditAudioMetaDataPopupView(let trackIndex):
                    let audioMetaData = audioDataManager.getAudioTrackMetaData(at: trackIndex)
                    eventOutput.send(.didPresentEditAudioMetaDataPopupView(audioMetaData))

                case .willApplyAudioMetadataChanges(let audioMetaData):
                    applyAudioMetadataChanges(newMetadata: audioMetaData)

                case .willSortAudioTracks(let sortBy):
                    let sortResult = audioDataManager.sortAudioTracks(sortBy: sortBy)
                    eventOutput.send(.didSortAudioTracks(sortResult: sortResult))

                case .willMoveAudioTrackOrder(let src, let des):
                    audioDataManager.moveAudioTrackOrder(src: src, des: des)

                case .willRemoveAudioTrack(let trackIndex):
                    removeAudioTrack(trackIndex: trackIndex)

                case .willScrollToActiveAudioTrack:
                    if let activeTrackID = soundPlayer.activeTrackID,
                        let activeAudioTrackIndex = audioDataManager[activeTrackID]
                    {
                        eventOutput.send(.didScrollToActiveAudioTrack(activeAudioTrackIndex))
                    }

                case .willDismissAudioControlBar:
                    soundPlayer.stopPlaying()
                    eventOutput.send(.didDismissAudioControlBar)

                case .willChangeAudioSessionStateAsThin:
                    if let activeTrackID = soundPlayer.activeTrackID,
                        let activeAudioTrackIndex = audioDataManager[activeTrackID]
                    {
                        eventOutput.send(
                            .didChangeAudioSessionStateAsThin(audioDataManager.pageComponent, activeAudioTrackIndex))
                    }
            }
        }
        .store(in: &subscriptions)

        return eventOutput.eraseToAnyPublisher()
    }

    var isActiveAudioViewModel: Bool {
        soundPlayer.nowActiveAudioVMIdentifier == vmIdentifier
    }

    var audioComponentID: UUID {
        audioDataManager.pageComponent.id
    }

    var currentTrackIndex: Int? {
        if let id = soundPlayer.activeTrackID {
            return audioDataManager[id]
        } else {
            return nil
        }
    }

    private func downloadAudioTracksUsingCode(using code: String) {
        audioDataManager.downloadAudioTracksUsingCode(using: code) { [weak self] ratio in
            self?.eventOutput.send(.didUpdateAudioDownloadProgress(progressRatio: ratio))
        }
        .sinkToResult { [weak self] result in
            switch result {
                case .success(let appendedTracksIndices):
                    self?.eventOutput.send(.didAppendAudioTrackRows(appendedTracksIndices))

                case .failure:
                    self?.eventOutput.send(.didPresentInvalidDownloadCode)
            }
        }
        .store(in: &subscriptions)
    }

    private func importAudiosFromLocal(selectedAudioURLs: [URL]) {
        audioDataManager
            .importAudiosFromLocal(urls: selectedAudioURLs)
            .sinkToResult { [weak self] result in
                switch result {
                    case .success(let appendedTracksIndices):
                        self?.eventOutput.send(.didAppendAudioTrackRows(appendedTracksIndices))

                    case .failure(let error):
                        myLog("\(error.localizedDescription)", c: .red)
                }
            }
            .store(in: &subscriptions)
    }

    private func playAudioTrack(trackIndex: Int) {
        let activeAudioVisualizerData = audioDataManager.getActiveAudioTrackVisualizerData(at: trackIndex)
        let audioMetaData = audioDataManager.getAudioTrackMetaData(at: trackIndex)

        if let audioURL = audioMetaData.audioURL,
            let wavefromData = activeAudioVisualizerData.waveformData
        {
            soundPlayer.play(
                viewModelUseInterface: self,
                activeAudioData: activeAudioVisualizerData,
                audioMetaData: audioMetaData,
                audioFileURL: audioURL)

            eventOutput.send(.didPlayAudioTrack(trackIndex: trackIndex, audioMetaData, wavefromData))
        }
    }

    private func toggleAudioPlayingState() {
        if let playbackState = soundPlayer.togglePlaybackState(),
            let activeTrackID = soundPlayer.activeTrackID,
            let activeTrackIndex = audioDataManager[activeTrackID]
        {
            eventOutput.send(
                .didToggleAudioPlayingState(
                    activeTrackIndex: activeTrackIndex,
                    playbackState: playbackState
                )
            )
        }
    }

    private func playNextAudioTrack() {
        if let activeTrackID = soundPlayer.activeTrackID,
            let nextTrackIndex = audioDataManager.getNextAudioTrackIndex(trackID: activeTrackID)
        {
            playAudioTrack(trackIndex: nextTrackIndex)
        }
    }

    private func playPreviousAudioTrack() {
        if let activeTrackID = soundPlayer.activeTrackID,
            let previousTrackIndex = audioDataManager.getPreviousAudioTrackIndex(trackID: activeTrackID)
        {
            playAudioTrack(trackIndex: previousTrackIndex)
        }
    }

    private func seekAudioTrack(seek: TimeInterval) {
        if let total = soundPlayer.seek(time: seek),
            let activeTrackID = soundPlayer.activeTrackID,
            let activeTrackIndex = audioDataManager[activeTrackID]
        {
            eventOutput.send(.didSeekAudioTrack(trackIndex: activeTrackIndex, seek: seek, total: total))
        }
    }

    private func applyAudioMetadataChanges(newMetadata: AudioTrackMetadata) {
        let nowActiveTrackID = soundPlayer.activeTrackID
        if let editResult = audioDataManager.applyAudioMetaDataChange(
            metadata: newMetadata, activeTrackID: nowActiveTrackID)
        {
            soundPlayer.applyMetadataChange(metadata: newMetadata)
            eventOutput.send(
                .didApplyAudioMetadataChanges(editingResult: editResult, metadata: newMetadata)
            )
        }
    }

    private func removeAudioTrack(trackIndex: Int) {
        let activeTrackID = soundPlayer.activeTrackID
        let nowActiveAudioVMIdentifier = soundPlayer.nowActiveAudioVMIdentifier
        let isPlaying = soundPlayer.isPlaying
        let (removedAudio, willPlayNextAudioID) = audioDataManager.removeAudioTrack(trackIndex: trackIndex)

        if nowActiveAudioVMIdentifier == vmIdentifier {
            if let willPlayNextAudioID {
                if activeTrackID == removedAudio.id {
                    if isPlaying {
                        eventOutput.send(.didRemoveAudioTrack(trackIndex))
                        let willPlayNextAudioIndex = audioDataManager[willPlayNextAudioID]!
                        playAudioTrack(trackIndex: willPlayNextAudioIndex)
                    } else {
                        soundPlayer.stopPlaying()
                        eventOutput.send(.didRemoveAudioTrackAndStopPlaying(trackIndex))
                    }
                } else {
                    eventOutput.send(.didRemoveAudioTrack(trackIndex))
                }
            } else {
                soundPlayer.stopPlaying()
                eventOutput.send(.didRemoveAudioTrackAndStopPlaying(trackIndex))
                return
            }
        } else {
            eventOutput.send(.didRemoveAudioTrack(trackIndex))
        }
    }

    func clearSubscriptions() {
        subscriptions.removeAll()
    }
}

extension AudioComponentViewModel: AudioComponentVMUseInterface {
    func toggle() { toggleAudioPlayingState() }
    func previous() { playPreviousAudioTrack() }
    func seek(seek: TimeInterval) { seekAudioTrack(seek: seek) }
    func playNextAudio() { playNextAudioTrack() }
    func inactive() { eventOutput.send(.didInactiveAudioComponent) }
}

extension AudioComponentViewModel {
    enum Action {
        case willDownloadMusicWithCode(String)
        case willImportAudioFileFromFileSystem(selectedAudioURLs: [URL])
        case willPlayAudioTrack(trackIndex: Int)
        case willToggleAudioPlayingState
        case willPlayNextAudioTrack
        case willPlayPreviousAudioTrack
        case willSeekAudioTrack(seek: TimeInterval)
        case willRemoveAudioTrack(Int)
        case willApplyAudioMetadataChanges(AudioTrackMetadata)
        case willSortAudioTracks(AudioTrackSortBy)
        case willMoveAudioTrackOrder(Int, Int)
        case willPresentEditAudioMetaDataPopupView(trackIndex: Int)
        case willScrollToActiveAudioTrack
        case willDismissAudioControlBar
        case willChangeAudioSessionStateAsThin
    }

    enum Event {
        case didAppendAudioTrackRows([Int])
        case didPlayAudioTrack(trackIndex: Int, AudioTrackMetadata, AudioWaveformData?)
        case didToggleAudioPlayingState(activeTrackIndex: Int, playbackState: Bool)
        case didUpdateAudioDownloadProgress(progressRatio: Float)
        case didSeekAudioTrack(trackIndex: Int, seek: TimeInterval, total: TimeInterval)
        case didRemoveAudioTrack(Int)
        case didRemoveAudioTrackAndStopPlaying(Int)
        case didSortAudioTracks(sortResult: [Int])
        case didPresentInvalidDownloadCode
        case didApplyAudioMetadataChanges(editingResult: MetaDataEditingResult, metadata: AudioTrackMetadata)
        case didInactiveAudioComponent
        case didPresentEditAudioMetaDataPopupView(AudioTrackMetadata)
        case didScrollToActiveAudioTrack(Int)
        case didDismissAudioControlBar
        case didChangeAudioSessionStateAsThin(AudioComponent, Int)
    }
}
