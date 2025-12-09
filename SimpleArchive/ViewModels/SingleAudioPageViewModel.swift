import Combine
import SFBAudioEngine
import UIKit

@MainActor class SingleAudioPageViewModel: NSObject, ViewModelType {
    typealias Input = SingleAudioPageInput
    typealias Output = SingleAudioPageOutput

    private var output = PassthroughSubject<SingleAudioPageOutput, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private var coredataReposotory: MemoSingleComponentRepositoryType
    private var audioComponent: AudioComponent
    private var pageTitle: String
    private var audioTrackController: AudioTrackControllerType
    private var audioDownloader: AudioDownloaderType
    private var audioFileManager: AudioFileManagerType
    private var audioContentTableDataSource: AudioComponentDataSource

    init(
        coredataReposotory: MemoSingleComponentRepositoryType,
        audioComponent: AudioComponent,
        audioDownloader: AudioDownloaderType,
        audioFileManager: AudioFileManagerType,
        audioTrackController: AudioTrackControllerType,
        pageTitle: String
    ) {
        self.coredataReposotory = coredataReposotory
        self.audioComponent = audioComponent
        self.pageTitle = pageTitle
        self.audioDownloader = audioDownloader
        self.audioFileManager = audioFileManager
        self.audioTrackController = audioTrackController
        self.audioContentTableDataSource = AudioComponentDataSource(
            tracks: audioComponent.componentContents.tracks,
            sortBy: audioComponent.componentContents.sortBy
        )

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pauseAudioOnInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    deinit { print("deinit SingleAudioPageViewModel") }

    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }
            switch event {

                case .viewDidLoad:
                    output.send(.viewDidLoad(pageTitle, audioComponent, audioContentTableDataSource))

                case .willDownloadMusicWithCode(let code):
                    downloadAudio(with: code)

                case .willPlayAudioTrack(let trackIndex):
                    playAudioTrack(trackIndex: trackIndex)

                case .willApplyAudioMetadataChanges(let editedMetadata, let trackIndex):
                    applyAudioMetadataChanges(newMetadata: editedMetadata, trackIndex: trackIndex)

                case .willSortAudioTracks(let sortBy):
                    sortAudioTracks(sortBy: sortBy)

                case .willRemoveAudioTrack(let trackIndex):
                    removeAudioTrack(trackIndex: trackIndex)

                case .willMoveAudioTrackOrder(let srcIndex, let desIndex):
                    moveAudioTrackOrder(src: srcIndex, des: desIndex)

                case .willPlayNextAudioTrack:
                    playNextAudioTrack()

                case .willPlayPreviousAudioTrack:
                    playPreviousAudioTrack()

                case .willSeekAudioTrack(let seek):
                    seekAudioTrack(seek: seek)

                case .willToggleAudioPlayingState:
                    toggleAudioPlayingState()

                case .willImportAudioFilesFromFileSystem(let audioURLs):
                    importAudioFromLocalFileSystem(urls: audioURLs)
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func downloadAudio(with code: String) {
        let currentPlayingAudioTrackID = audioContentTableDataSource.nowPlayingAudioIndex
            .flatMap { audioComponent.componentContents.tracks[$0].id }

        audioDownloader.handleDownloadedProgressPercent = { [weak self] progress in
            self?.output.send(.didUpdateAudioDownloadProgress(progress))
        }

        audioDownloader.downloadTask(with: code)
            .tryMap { [weak self] url in
                guard let self else { return [URL]() }
                return try audioFileManager.extractAudioFileURLs(zipURL: url)
            }
            .tryMapEnumerated { [weak self] _, audioURL in
                guard let self else { throw AudioDownloadError.invalidCode }

                let audioMetadata = audioFileManager.readAudioMetadata(audioURL: audioURL)

                var fileTitle = audioURL.deletingPathExtension().lastPathComponent
                if fileTitle.isEmpty { fileTitle = "no title" }
                if let metadataTitle = audioMetadata.title { fileTitle = metadataTitle }

                let artist: String = audioMetadata.artist ?? "Unknown"

                let defaultAudioThumbnailImage = UIImage(named: "defaultMusicThumbnail")!
                let thumnnailImageData =
                    audioMetadata.thumbnail ?? defaultAudioThumbnailImage.jpegData(compressionQuality: 1.0)!

                let audioFileID = UUID()
                let audioFileName = "\(audioFileID).\(audioURL.pathExtension)"
                try audioFileManager.moveItem(src: audioURL, fileName: audioFileName)

                let track = AudioTrack(
                    id: audioFileID,
                    title: fileTitle,
                    artist: artist,
                    thumbnail: thumnnailImageData,
                    fileExtension: audioURL.pathExtension)

                audioFileManager.writeAudioMetadata(audioTrack: track)
                return track
            }
            .sinkToResult { [weak self] result in
                guard let self else { return }
                switch result {
                    case .success(let audioTracks):
                        let appendedIndices = audioComponent.addAudios(audiotracks: audioTracks)

                        audioContentTableDataSource.tracks = audioComponent.componentContents.tracks
                        audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.componentContents.tracks
                            .firstIndex {
                                $0.id == currentPlayingAudioTrackID
                            }

                        coredataReposotory.saveComponentsDetail(modifiedComponent: audioComponent)

                        output.send(.didAppendAudioTrackRows(appendedIndices))

                    case .failure(let failure):
                        if let error = failure as? AudioDownloadError {
                            switch error {
                                case .invalidCode:
                                    break
                                case .unowned(let error):
                                    print(error.localizedDescription)
                                case .fileManagingError(let error):
                                    print(error.localizedDescription)

                            }
                        }
                        output.send(.didPresentInvalidDownloadCode)
                }
            }
            .store(in: &subscriptions)
    }

    private func importAudioFromLocalFileSystem(urls: [URL]) {
        var audioTracks: [AudioTrack] = []

        for audioFileUrl in urls {

            let audioID = UUID()
            let audioFileName = "\(audioID).\(audioFileUrl.pathExtension)"
            let storedFileURL = audioFileManager.copyFilesToAppDirectory(src: audioFileUrl, des: audioFileName)
            let audioMetadata = audioFileManager.readAudioMetadata(audioURL: storedFileURL)

            var fileTitle = audioFileUrl.deletingPathExtension().lastPathComponent

            if fileTitle.isEmpty { fileTitle = "no title" }
            if let metadataTitle = audioMetadata.title { fileTitle = metadataTitle }

            let artist: String = audioMetadata.artist ?? "Unknown"

            let defaultAudioThumbnail = UIImage(named: "defaultMusicThumbnail")!
            let thumnnailImageData = audioMetadata.thumbnail ?? defaultAudioThumbnail.jpegData(compressionQuality: 1.0)!

            let track = AudioTrack(
                id: audioID,
                title: fileTitle,
                artist: artist,
                thumbnail: thumnnailImageData,
                fileExtension: storedFileURL.pathExtension)

            audioFileManager.writeAudioMetadata(audioTrack: track)
            audioTracks.append(track)
        }

        let currentPlayingAudioTrackID = audioContentTableDataSource.nowPlayingAudioIndex
            .flatMap { audioComponent.componentContents.tracks[$0].id }
        let appendedIndices = audioComponent.addAudios(audiotracks: audioTracks)

        audioContentTableDataSource.tracks = audioComponent.componentContents.tracks
        audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.componentContents.tracks.firstIndex {
            $0.id == currentPlayingAudioTrackID
        }

        coredataReposotory.saveComponentsDetail(modifiedComponent: audioComponent)

        output.send(.didAppendAudioTrackRows(appendedIndices))
    }

    private func playAudioTrack(trackIndex: Int) {

        let audioTrackURL = audioFileManager.createAudioFileURL(fileName: audioComponent.trackNames[trackIndex])
        let audioSampleData = audioFileManager.readAudioSampleData(audioURL: audioTrackURL)

        audioTrackController.setAudioURL(audioURL: audioTrackURL)
        audioTrackController.player?.delegate = self
        audioTrackController.play()

        audioContentTableDataSource.isPlaying = true
        audioContentTableDataSource.nowPlayingAudioIndex = trackIndex
        audioContentTableDataSource.nowPlayingURL = audioTrackController.audioTrackURL
        audioContentTableDataSource.audioSampleData = audioSampleData
        audioContentTableDataSource.getProgress = { [weak self] in
            guard let self else { return .zero }
            return audioTrackController.currentTime! / audioTrackController.totalTime!
        }

        let audioTotalDuration = audioTrackController.totalTime
        let audioMetadata = audioFileManager.readAudioMetadata(audioURL: audioTrackURL)

        output.send(
            .didPlayAudioTrack(
                trackIndex,
                audioTotalDuration,
                audioMetadata,
                audioSampleData
            )
        )
    }

    private func playNextAudioTrack() {
        if var unwrappedCurrentPlayingTrackIndex = audioContentTableDataSource.nowPlayingAudioIndex {
            unwrappedCurrentPlayingTrackIndex += 1
            if audioComponent.componentContents.tracks.count <= unwrappedCurrentPlayingTrackIndex {
                unwrappedCurrentPlayingTrackIndex = 0
            }
            playAudioTrack(trackIndex: unwrappedCurrentPlayingTrackIndex)
        }
    }

    private func playPreviousAudioTrack() {
        if var unwrappedCurrentPlayingTrackIndex = audioContentTableDataSource.nowPlayingAudioIndex {
            unwrappedCurrentPlayingTrackIndex -= 1
            if 0 > unwrappedCurrentPlayingTrackIndex {
                unwrappedCurrentPlayingTrackIndex = audioComponent.componentContents.tracks.count - 1
            }
            playAudioTrack(trackIndex: unwrappedCurrentPlayingTrackIndex)
        }
    }

    private func toggleAudioPlayingState() {
        audioTrackController.togglePlaying()

        let isPlaying = audioTrackController.isPlaying
        audioContentTableDataSource.isPlaying = isPlaying
        output.send(
            .didToggleAudioPlayingState(isPlaying, audioContentTableDataSource.nowPlayingAudioIndex)
        )
    }

    private func seekAudioTrack(seek: TimeInterval) {
        audioTrackController.seek(interval: seek)
        output.send(
            .didSeekAudioTrack(
                seek,
                audioTrackController.totalTime,
                audioContentTableDataSource.nowPlayingAudioIndex
            )
        )
    }

    private func applyAudioMetadataChanges(newMetadata: AudioTrackMetadata, trackIndex: Int) {
        let targetAudioTrackID = audioComponent.componentContents.tracks[trackIndex].id
        let isEditCurrentlyPlayingAudio = audioContentTableDataSource.nowPlayingAudioIndex == trackIndex
        let currentPlayingAudioTrackID = audioContentTableDataSource.nowPlayingAudioIndex
            .flatMap { audioComponent.componentContents.tracks[$0].id }
        var trackIndexAfterEdit: Int?

        if let newTitle = newMetadata.title {
            audioComponent.componentContents.tracks[trackIndex].title = newTitle
        }
        if let newArtist = newMetadata.artist {
            audioComponent.componentContents.tracks[trackIndex].artist = newArtist
        }
        if let newThumbnail = newMetadata.thumbnail {
            audioComponent.componentContents.tracks[trackIndex].thumbnail = newThumbnail
        }

        coredataReposotory.saveComponentsDetail(modifiedComponent: audioComponent)
        audioFileManager.writeAudioMetadata(audioTrack: audioComponent.componentContents.tracks[trackIndex])

        if audioComponent.componentContents.sortBy == .name {
            audioComponent.componentContents.tracks.sort(by: { $0.title < $1.title })
            trackIndexAfterEdit = audioComponent.componentContents.tracks.firstIndex(where: {
                $0.id == targetAudioTrackID
            })
            if let currentPlayingAudioTrackID {
                audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.componentContents.tracks.firstIndex {
                    $0.id == currentPlayingAudioTrackID
                }
            }
        }

        audioContentTableDataSource.tracks = audioComponent.componentContents.tracks

        output.send(
            .didApplyAudioMetadataChanges(
                trackIndex,
                newMetadata,
                isEditCurrentlyPlayingAudio,
                trackIndexAfterEdit)
        )
    }

    private func moveAudioTrackOrder(src: Int, des: Int) {
        let currentPlayingAudioTrackID = audioContentTableDataSource.nowPlayingAudioIndex
            .flatMap { audioComponent.componentContents.tracks[$0].id }

        audioComponent.componentContents.tracks.moveElement(src: src, des: des)
        audioComponent.componentContents.sortBy = .manual

        audioContentTableDataSource.tracks = audioComponent.componentContents.tracks
        audioContentTableDataSource.sortBy = .manual

        coredataReposotory.saveComponentsDetail(modifiedComponent: audioComponent)

        audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.componentContents.tracks.firstIndex {
            $0.id == currentPlayingAudioTrackID
        }
    }

    private func sortAudioTracks(sortBy: AudioTrackSortBy) {
        audioComponent.componentContents.sortBy = sortBy

        let currentPlayingAudioTrackID = audioContentTableDataSource.nowPlayingAudioIndex
            .flatMap { audioComponent.componentContents.tracks[$0].id }
        let before = audioComponent.trackNames

        switch sortBy {
            case .name:
                audioComponent.componentContents.tracks.sort(by: { $0.title < $1.title })

            case .createDate:
                audioComponent.componentContents.tracks.sort(by: { $0.createData > $1.createData })

            case .manual:
                break
        }

        coredataReposotory.saveComponentsDetail(modifiedComponent: audioComponent)

        audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.componentContents.tracks.firstIndex {
            $0.id == currentPlayingAudioTrackID
        }

        let after = audioComponent.trackNames

        audioContentTableDataSource.tracks = audioComponent.componentContents.tracks
        audioContentTableDataSource.sortBy = sortBy

        output.send(.didSortAudioTracks(before, after))
    }

    private func removeAudioTrack(trackIndex: Int) {
        let currentPlayingAudioTrackID = audioContentTableDataSource.nowPlayingAudioIndex
            .flatMap { audioComponent.componentContents.tracks[$0].id }
        let removedAudioTrack = audioComponent.componentContents.tracks.remove(at: trackIndex)

        audioFileManager.removeAudio(with: removedAudioTrack)
        audioContentTableDataSource.tracks = audioComponent.componentContents.tracks
        coredataReposotory.saveComponentsDetail(modifiedComponent: audioComponent)

        if audioContentTableDataSource.nowPlayingAudioIndex != nil {
            if audioComponent.componentContents.tracks.isEmpty {
                audioTrackController.reset()
                cleanDatasource()
                output.send(.didRemoveAudioTrackAndStopPlaying(trackIndex))
                return
            }

            if audioContentTableDataSource.nowPlayingAudioIndex == trackIndex {
                if audioTrackController.isPlaying == true {
                    let nextPlayingAudioTrackIndex = min(trackIndex, audioComponent.componentContents.tracks.count - 1)
                    let audioTrackURL = audioFileManager.createAudioFileURL(
                        fileName: audioComponent.trackNames[nextPlayingAudioTrackIndex])
                    let audioSampleData = audioFileManager.readAudioSampleData(audioURL: audioTrackURL)

                    audioTrackController.setAudioURL(audioURL: audioTrackURL)
                    audioTrackController.player?.delegate = self
                    audioTrackController.play()

                    audioContentTableDataSource.nowPlayingAudioIndex = nextPlayingAudioTrackIndex
                    audioContentTableDataSource.nowPlayingURL = audioTrackController.audioTrackURL
                    audioContentTableDataSource.audioSampleData = audioSampleData
                    audioContentTableDataSource.getProgress = { [weak self] in
                        guard let self else { return .zero }
                        return audioTrackController.currentTime! / audioTrackController.totalTime!
                    }

                    let audioTotalDuration = audioTrackController.totalTime
                    let audioMetadata = audioFileManager.readAudioMetadata(audioURL: audioTrackURL)

                    output.send(
                        .didRemoveAudioTrackAndPlayNextAudio(
                            trackIndex,
                            nextPlayingAudioTrackIndex,
                            audioTotalDuration,
                            audioMetadata,
                            audioSampleData
                        )
                    )
                } else {
                    audioTrackController.reset()
                    cleanDatasource()
                    output.send(.didRemoveAudioTrackAndStopPlaying(trackIndex))
                }
            } else {
                audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.componentContents.tracks.firstIndex {
                    $0.id == currentPlayingAudioTrackID
                }
                output.send(.didRemoveAudioTrack(trackIndex))
            }
        } else {
            output.send(.didRemoveAudioTrack(trackIndex))
        }
    }

    private func cleanDatasource() {
        audioContentTableDataSource.nowPlayingAudioIndex = nil
        audioContentTableDataSource.nowPlayingURL = nil
        audioContentTableDataSource.isPlaying = nil
        audioContentTableDataSource.audioSampleData = nil
        audioContentTableDataSource.getProgress = nil
    }

    @objc private func pauseAudioOnInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
            case .began:
                if audioTrackController.isPlaying {
                    audioTrackController.togglePlaying()
                    audioContentTableDataSource.isPlaying = false
                    output.send(
                        .didToggleAudioPlayingState(false, audioContentTableDataSource.nowPlayingAudioIndex)
                    )
                }

            default:
                break
        }
    }
}

extension SingleAudioPageViewModel: @preconcurrency AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNextAudioTrack()
    }
}
