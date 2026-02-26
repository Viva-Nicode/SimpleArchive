import Combine
import Foundation

@MainActor protocol PageComponentActionDispatcherType {
    associatedtype PCVT: PageComponentViewModelType
    associatedtype UEHT: ComponentViewEventHandlerType where PCVT.ViewModelEvent == UEHT.EventType

    func bindToViewModel(viewModel: PCVT, UIEventHandler: UEHT)
}

final class AudioComponentActionDispatcher: PageComponentActionDispatcherType {
    typealias Input = AudioComponentViewModel.Action
    typealias Output = AudioComponentViewModel.Event

    private let dispatcher = PassthroughSubject<Input, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private var viewModel: AudioComponentViewModel?

    func bindToViewModel(
        viewModel: AudioComponentViewModel,
        UIEventHandler: AudioComponentViewEventHandler
    ) {
        self.viewModel = viewModel
        self.viewModel?
            .bindToView(input: dispatcher.eraseToAnyPublisher())
            .sink { UIEventHandler.UIupdateEventHandler($0) }
            .store(in: &subscriptions)
    }

    func clearSubscriptions() {
        subscriptions.removeAll()
        viewModel?.clearSubscriptions()
        viewModel = nil
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
}
