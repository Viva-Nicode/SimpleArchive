import Combine
import Foundation

@MainActor protocol PageComponentActionDispatcherType {
    associatedtype VMT: PageComponentViewModelType
    associatedtype EHT: ComponentViewEventHandlerType

    func bindToViewModel(viewModel: VMT, UIEventHandler: EHT)
    func clearSubscriptions()
}

protocol AudioComponentActionDispatcherType: PageComponentActionDispatcherType
where EHT == AudioComponentViewEventHandler, VMT == AudioComponentViewModel {}

class AudioComponentActionDispatcher: AudioComponentActionDispatcherType {
    typealias Action = AudioComponentViewModel.Action
    typealias Event = AudioComponentViewModel.Event

    private let dispatcher = PassthroughSubject<Action, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private(set) var viewModel: AudioComponentViewModel?

    func bindToViewModel(
        viewModel: AudioComponentViewModel,
        UIEventHandler: AudioComponentViewEventHandler
    ) {
        self.viewModel = viewModel

        subscriptions.removeAll()
        viewModel.clearSubscriptions()

        self.viewModel?
            .bindToView(input: dispatcher.eraseToAnyPublisher())
            .sink { UIEventHandler.UIupdateEventHandler($0) }
            .store(in: &subscriptions)
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    func setEventHandler(controlBarEventHandler: AudioControlBarEventHandler) {
        if let viewModel {
            if viewModel.isActiveAudioViewModel {
                subscriptions.removeAll()
                viewModel.clearSubscriptions()

                viewModel
                    .bindToView(input: dispatcher.eraseToAnyPublisher())
                    .sink { controlBarEventHandler.UIupdateEventHandler($0) }
                    .store(in: &subscriptions)
            }
        }
    }

    func setEventHandler(thinAudioControlBarEventHandler: ThinAudioControlBarEventHandler) {
        subscriptions.removeAll()
        viewModel?.clearSubscriptions()

        viewModel?
            .bindToView(input: dispatcher.eraseToAnyPublisher())
            .sink { thinAudioControlBarEventHandler.UIupdateEventHandler($0) }
            .store(in: &subscriptions)
    }

    func dissmissAudioControlBar() {
        dispatcher.send(.willDismissAudioControlBar)
    }

    func downloadMusics(with code: String) {
        dispatcher.send(.willDownloadMusicWithCode(code))
    }

    func importAudioFilesFromFileSystem(urls: [URL]) {
        dispatcher.send(.willImportAudioFileFromFileSystem(selectedAudioURLs: urls))
    }

    func playAudioTrack(with trackIndex: Int) {
        dispatcher.send(.willPlayAudioTrack(trackIndex: trackIndex))
    }

    func presentAudioMetaDataEditingPopupView(trackIndex: Int) {
        dispatcher.send(.willPresentEditAudioMetaDataPopupView(trackIndex: trackIndex))
    }

    func togglePlayingState() {
        dispatcher.send(.willToggleAudioPlayingState)
    }

    func playNextAudioTrack() {
        dispatcher.send(.willPlayNextAudioTrack)
    }

    func playPreviousAudioTrack() {
        dispatcher.send(.willPlayPreviousAudioTrack)
    }

    func seekAudioTrack(seek: TimeInterval) {
        dispatcher.send(.willSeekAudioTrack(seek: seek))
    }

    func changeAudioTrackMetadata(editMetadata: AudioTrackMetadata) {
        dispatcher.send(.willApplyAudioMetadataChanges(editMetadata))
    }

    func changeSortByAudioTracks(sortBy: AudioTrackSortBy) {
        dispatcher.send(.willSortAudioTracks(sortBy))
    }

    func moveAudioTrackOrder(src: Int, des: Int) {
        dispatcher.send(.willMoveAudioTrackOrder(src, des))
    }

    func removeAudioTrack(trackIndex: Int) {
        dispatcher.send(.willRemoveAudioTrack(trackIndex))
    }

    func scrollToActiveAudioTrack() {
        dispatcher.send(.willScrollToActiveAudioTrack)
    }

    func clearSubscriptions() {
        subscriptions.removeAll()
        viewModel?.clearSubscriptions()
        viewModel = nil
    }
}
