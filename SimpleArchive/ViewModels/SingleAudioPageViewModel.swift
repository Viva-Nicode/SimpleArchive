import CSFBAudioEngine
import Combine
import SFBAudioEngine
import UIKit
import ZIPFoundation

@MainActor class SingleAudioPageViewModel: NSObject, ViewModelType {
    typealias Input = SingleAudioPageInput
    typealias Output = SingleAudioPageOutput

    private var output = PassthroughSubject<SingleAudioPageOutput, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private var coredataReposotory: MemoSingleComponentRepositoryType
    private var audioComponent: AudioComponent
    private var pageTitle: String
    private var audioTrackController: AudioTrackControllerType?
    private var audioDownloader: AudioDownloaderType = AudioDownloader()
    private var audioContentTableDataSource: AudioComponentDataSource
    
    private var configuredCells:[AudioTableRowView] = []

    init(
        coredataReposotory: MemoSingleComponentRepositoryType,
        audioComponent: AudioComponent,
        pageTitle: String
    ) {
        self.coredataReposotory = coredataReposotory
        self.audioComponent = audioComponent
        self.pageTitle = pageTitle
        self.audioContentTableDataSource = AudioComponentDataSource(
            tracks: audioComponent.detail.tracks,
            sortBy: audioComponent.detail.sortBy
        )

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveComponentsChanges),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)

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

                case .viewWillDisappear:
                    saveComponentsChanges()

                case .willDownloadMusicWithCode(let code):
                    downloadAudio(with: code)

                case .willPlayAudioTrack(let trackIndex):
                    playAudioTrack(trackIndex: trackIndex)

                case .willPresentGallery(let imageView):
                    output.send(.didPresentGallery(imageView))

                case .willEditAudioTrackMetadata(let editedMetadata, let trackIndex):
                    editAudioMetadata(newMetadata: editedMetadata, trackIndex: trackIndex)

                case .willSortAudioTracks(let sortBy):
                    sortAudioTracks(sortBy: sortBy)

                case .willRemoveAudioTrack(let trackIndex):
                    removeAudioTrack(trackIndex: trackIndex)

                case .willDropAudioTrack(let srcIndex, let desIndex):
                    dropAudioTrack(src: srcIndex, des: desIndex)

                case .willPlayNextAudioTrack:
                    playNextAudioTrack()

                case .willPlayPreviousAudioTrack:
                    playPreviousAudioTrack()

                case .willSeekAudioTrack(let seek):
                    seekAudioTrack(seek: seek)

                case .willTapPlayPauseButton:
                    tapPlayPauseButton()

                case .willPresentFilePicker:
                    output.send(.didPresentFilePicker)
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func downloadAudio(with code: String) {
        let currentPlayingAudioTrackID = audioComponent.detail[audioContentTableDataSource.nowPlayingAudioIndex]?.id

        audioDownloader.handleDownloadedProgressPercent = { [weak self] progress in
            self?.output.send(.updateAudioDownloadProgress(progress))
        }

        audioDownloader.downloadTask(with: code)
            .sinkToResult { [weak self] result in
                guard let self else { return }
                switch result {
                    case .success(let audioTracks):
                        let appendedIndices = audioComponent.addAudios(audiotracks: audioTracks)
                        audioContentTableDataSource.tracks = audioComponent.detail.tracks
                        audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.detail.tracks.firstIndex {
                            $0.id == currentPlayingAudioTrackID
                        }
                        output.send(.didDownloadMusicWithCode(appendedIndices))

                    case .failure(let failure):
                        switch failure {
                            case .invalidCode:
                                break
                            case .unowned(let msg):
                                print(msg)
                        }
                        output.send(.presentInvalidDownloadCode)
                }
            }
            .store(in: &subscriptions)
    }

    private func playAudioTrack(trackIndex: Int) {
        audioContentTableDataSource.nowPlayingAudioIndex = trackIndex
        audioContentTableDataSource.isPlaying = true

        audioTrackController = AudioTrackController(audioTrackName: audioComponent.trackNames[trackIndex])
        audioContentTableDataSource.nowPlayingURL = audioTrackController?.audioTrackURL

        audioTrackController?.player?.delegate = self
        audioTrackController?.play()

        let audioSampleData = getAudioSampleData(nowPlayingURL: audioTrackController?.audioTrackURL)
        audioContentTableDataSource.audioSampleData = audioSampleData
        audioContentTableDataSource.getProgress = { [weak self] in
            guard let self else { return .zero }
            return audioTrackController!.getCurrentTime()! / audioTrackController!.getTotalTime()!
        }

        output.send(
            .didPlayAudioTrack(
                audioTrackController!.audioTrackURL,
                trackIndex,
                audioTrackController?.getTotalTime(),
                audioComponent.detail.tracks[trackIndex].metadata,
                audioSampleData
            )
        )
    }

    private func playNextAudioTrack() {
        audioTrackController?.stop()

        if var unwrappedCurrentPlayingTrackIndex = audioContentTableDataSource.nowPlayingAudioIndex {
            unwrappedCurrentPlayingTrackIndex += 1
            if audioComponent.detail.tracks.count <= unwrappedCurrentPlayingTrackIndex {
                unwrappedCurrentPlayingTrackIndex = 0
            }
            playAudioTrack(trackIndex: unwrappedCurrentPlayingTrackIndex)
        }
    }

    private func playPreviousAudioTrack() {
        audioTrackController?.stop()

        if var unwrappedCurrentPlayingTrackIndex = audioContentTableDataSource.nowPlayingAudioIndex {
            unwrappedCurrentPlayingTrackIndex -= 1
            if 0 > unwrappedCurrentPlayingTrackIndex {
                unwrappedCurrentPlayingTrackIndex = audioComponent.detail.tracks.count - 1
            }
            playAudioTrack(trackIndex: unwrappedCurrentPlayingTrackIndex)
        }
    }

    private func tapPlayPauseButton() {
        audioTrackController?.togglePlaying()
        guard let isPlaying = audioTrackController?.isPlaying else { return }
        audioContentTableDataSource.isPlaying = isPlaying
        output.send(
            .didTapPlayPauseButton(
                isPlaying,
                audioContentTableDataSource.nowPlayingAudioIndex,
                audioTrackController?.getCurrentTime()
            )
        )
    }

    private func seekAudioTrack(seek: TimeInterval) {
        audioTrackController?.seek(interval: seek)
        output.send(
            .didSeekAudioTrack(
                seek,
                audioTrackController?.getTotalTime(),
                audioContentTableDataSource.nowPlayingAudioIndex
            )
        )
    }

    private func editAudioMetadata(newMetadata: AudioTrackMetadata, trackIndex: Int) {
        let targetAudioTrackID = audioComponent.detail[trackIndex]?.id
        let currentPlayingAudioTrackID = audioComponent.detail[audioContentTableDataSource.nowPlayingAudioIndex]?.id
        var trackIndexAfterEdit: Int?

        if let newTitle = newMetadata.title {
            audioComponent.detail.tracks[trackIndex].title = newTitle
        }
        if let newArtist = newMetadata.artist {
            audioComponent.detail.tracks[trackIndex].artist = newArtist
        }

        if let newThumbnail = newMetadata.thumbnail {
            audioComponent.detail.tracks[trackIndex].thumbnail = newThumbnail
        }

        audioComponent.persistenceState = .unsaved(isMustToStoreSnapshot: false)

        if audioComponent.detail.sortBy == .name {
            audioComponent.detail.tracks.sort(by: { $0.title < $1.title })
            trackIndexAfterEdit = audioComponent.detail.tracks.firstIndex(where: { $0.id == targetAudioTrackID })
            if let currentPlayingAudioTrackID {
                audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.detail.tracks.firstIndex {
                    $0.id == currentPlayingAudioTrackID
                }
            }
        }

        audioContentTableDataSource.tracks = audioComponent.detail.tracks

        output.send(
            .didEditAudioTrackMetadata(
                trackIndex,
                newMetadata,
                audioContentTableDataSource.nowPlayingAudioIndex == trackIndex,
                trackIndexAfterEdit)
        )
    }

    private func dropAudioTrack(src: Int, des: Int) {
        let currentPlayingAudioTrackID = audioComponent.detail[audioContentTableDataSource.nowPlayingAudioIndex]?.id

        audioComponent.detail.tracks.moveElement(src: src, des: des)
        audioComponent.detail.sortBy = .manual

        audioContentTableDataSource.tracks = audioComponent.detail.tracks
        audioContentTableDataSource.sortBy = .manual

        audioComponent.persistenceState = .unsaved(isMustToStoreSnapshot: false)
        audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.detail.tracks.firstIndex {
            $0.id == currentPlayingAudioTrackID
        }
    }

    private func sortAudioTracks(sortBy: AudioTrackSortBy) {
        audioComponent.detail.sortBy = sortBy
        audioComponent.persistenceState = .unsaved(isMustToStoreSnapshot: false)

        let currentPlayingAudioTrackID = audioComponent.detail[audioContentTableDataSource.nowPlayingAudioIndex]?.id
        let before = audioComponent.trackNames

        switch sortBy {
            case .name:
                audioComponent.detail.tracks.sort(by: { $0.title < $1.title })

            case .createDate:
                audioComponent.detail.tracks.sort(by: { $0.createData > $1.createData })

            case .manual:
                break
        }

        audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.detail.tracks.firstIndex {
            $0.id == currentPlayingAudioTrackID
        }

        let after = audioComponent.trackNames

        audioContentTableDataSource.tracks = audioComponent.detail.tracks
        audioContentTableDataSource.sortBy = sortBy

        output.send(.didSortAudioTracks(before, after))
    }

    private func removeAudioTrack(trackIndex: Int) {
        audioComponent.persistenceState = .unsaved(isMustToStoreSnapshot: false)

        let currentPlayingAudioTrackID = audioComponent.detail[audioContentTableDataSource.nowPlayingAudioIndex]?.id
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let targetTrack = audioComponent.detail.tracks.remove(at: trackIndex)
        let trackURL = documentsDir.appendingPathComponent(
            "SimpleArchiveMusics/\(targetTrack.id).\(targetTrack.fileExtension)")

        try? fileManager.removeItem(at: trackURL)

        audioContentTableDataSource.tracks = audioComponent.detail.tracks

        if audioContentTableDataSource.nowPlayingAudioIndex != nil {
            if audioComponent.detail.tracks.isEmpty {
                audioTrackController = nil
                cleanDatasource()
                output.send(.didRemoveAudioTrack(trackIndex))
                output.send(.outOfSongs)
                return
            }

            if audioContentTableDataSource.nowPlayingAudioIndex == trackIndex {
                let nextPlayingAudioTrackIndex = min(trackIndex, audioComponent.detail.tracks.count - 1)
                output.send(.didRemoveAudioTrack(trackIndex))
                playAudioTrack(trackIndex: nextPlayingAudioTrackIndex)
            } else {
                audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.detail.tracks.firstIndex {
                    $0.id == currentPlayingAudioTrackID
                }
                output.send(.didRemoveAudioTrack(trackIndex))
            }
        } else {
            output.send(.didRemoveAudioTrack(trackIndex))
        }
    }

    private func getAudioSampleData(nowPlayingURL: URL?) -> AudioSampleData? {
        guard let nowPlayingURL, let file = try? AVAudioFile(forReading: nowPlayingURL) else {
            return nil
        }

        let audioFormat = file.processingFormat
        let audioFrameCount = UInt32(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
        else { return nil }
        do {
            try file.read(into: buffer)
        } catch {
            print(error)
        }

        let floatArray = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))

        let sampleRate = file.fileFormat.sampleRate

        let samplesPerBar = Int(sampleRate / Double(7))
        var result: [Float] = []

        for i in 0..<(floatArray.count / samplesPerBar) {
            let segment = floatArray[i * samplesPerBar..<(i + 1) * samplesPerBar]
            let avg = segment.map { abs($0) }.reduce(0, +) / Float(segment.count)
            result.append(avg)
        }

        guard let maxValue = result.max(), maxValue > 0 else {
            return AudioSampleData(
                sampleDataCount: floatArray.count,
                scaledSampleData: result,
                sampleRate: sampleRate)
        }
        let scaled = result.map { ($0 / maxValue) }

        return AudioSampleData(
            sampleDataCount: floatArray.count,
            scaledSampleData: scaled,
            sampleRate: sampleRate)
    }

    private func cleanDatasource() {
        audioContentTableDataSource.nowPlayingAudioIndex = nil
        audioContentTableDataSource.nowPlayingURL = nil
        audioContentTableDataSource.isPlaying = nil
        audioContentTableDataSource.audioSampleData = nil
        audioContentTableDataSource.getProgress = nil
    }

    @objc private func saveComponentsChanges() {
        if let changedTextEditorComponent = audioComponent.currentIfUnsaved() {
            coredataReposotory.saveComponentsDetail(changedComponents: [changedTextEditorComponent])
        }
    }

    @objc private func pauseAudioOnInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
            case .began:
                if let isPlaying = audioTrackController?.isPlaying, isPlaying == true {
                    audioTrackController?.togglePlaying()
                    audioContentTableDataSource.isPlaying = false
                    output.send(
                        .didTapPlayPauseButton(
                            false,
                            audioContentTableDataSource.nowPlayingAudioIndex,
                            audioTrackController?.getCurrentTime()
                        )
                    )
                }

            default:
                break
        }
    }
}

extension SingleAudioPageViewModel: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveDir = documentsDir.appendingPathComponent("SimpleArchiveMusics")
        var audioTracks: [AudioTrack] = []

        do {
            if !fileManager.fileExists(atPath: archiveDir.path) {
                try fileManager.createDirectory(at: archiveDir, withIntermediateDirectories: true)
            }

            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }

                let newID = UUID()
                let newFileName = "\(newID).\(url.pathExtension)"
                let destinationURL = archiveDir.appendingPathComponent(newFileName)

                try fileManager.copyItem(at: url, to: destinationURL)

                var fileTitle = url.deletingPathExtension().lastPathComponent
                var artist: String = "Unknown"
                let defaultAudioThumbnail = UIImage(named: "defaultMusicThumbnail")!
                let defaultThumnnailData = defaultAudioThumbnail.jpegData(compressionQuality: 1.0)!
                var defaultThumbnail = AttachedPicture(imageData: defaultThumnnailData, type: .frontCover)

                if fileTitle.isEmpty { fileTitle = "no title" }

                if let audioFile = try? AudioFile(readingPropertiesAndMetadataFrom: destinationURL) {

                    if let metadataTitle = audioFile.metadata.title, !metadataTitle.isEmpty {
                        print(metadataTitle)
                        fileTitle = metadataTitle
                    }

                    if let metadataArtist = audioFile.metadata.artist, !metadataArtist.isEmpty {
                        artist = metadataArtist
                    }

                    if let metadataThumbnail = audioFile.metadata.attachedPictures(ofType: .frontCover).first {
                        defaultThumbnail = metadataThumbnail
                    } else if let metadataOtherThumbnail = audioFile.metadata.attachedPictures(ofType: .other).first {
                        defaultThumbnail = AttachedPicture(
                            imageData: metadataOtherThumbnail.imageData,
                            type: .frontCover)
                    }

                    let newMetadata = AudioMetadata(dictionaryRepresentation: [
                        .attachedPictures: [defaultThumbnail.dictionaryRepresentation] as NSArray,
                        .title: NSString(string: fileTitle),
                        .artist: NSString(string: artist),
                    ])

                    audioFile.metadata = newMetadata
                    try? audioFile.writeMetadata()
                }

                let track = AudioTrack(
                    id: newID,
                    title: fileTitle,
                    artist: artist,
                    thumbnail: defaultThumbnail.imageData,
                    fileExtension: destinationURL.pathExtension)

                audioTracks.append(track)
            }

            let currentPlayingAudioTrackID = audioComponent.detail[audioContentTableDataSource.nowPlayingAudioIndex]?.id
            let appendedIndices = audioComponent.addAudios(audiotracks: audioTracks)
            audioContentTableDataSource.tracks = audioComponent.detail.tracks
            audioContentTableDataSource.nowPlayingAudioIndex = audioComponent.detail.tracks.firstIndex {
                $0.id == currentPlayingAudioTrackID
            }

            output.send(.didDownloadMusicWithCode(appendedIndices))
        } catch {
            print(error.localizedDescription)
        }
    }
}

extension SingleAudioPageViewModel: @preconcurrency AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNextAudioTrack()
    }
}

struct AudioSampleData: Codable {
    var sampleDataCount: Int
    var scaledSampleData: [Float]
    var sampleRate: Double
}
