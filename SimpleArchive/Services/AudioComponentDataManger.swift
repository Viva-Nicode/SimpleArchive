import Combine
import Foundation

typealias MetaDataEditingResult = AudioComponentDataManger.EditingMetaDataResult

final class AudioComponentDataManger {
    typealias P = (Float) -> Void
    typealias AR = AnyPublisher<[Int], Error>

    struct EditingMetaDataResult {
        var trackIndex: Int
        var isEditingActiveTrack: Bool
        var trackIndexAfterEditing: Int?
    }

    let pageComponent: AudioComponent

    private var audioDownloader: AudioDownloaderType
    private var audioFileManager: AudioFileManagerType
    private var memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType

    init(
        audioComponent: AudioComponent,
        memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType,
        audioDownloader: AudioDownloaderType,
    ) {
        self.pageComponent = audioComponent
        self.audioDownloader = audioDownloader
        self.memoComponentCoredataReposotory = memoComponentCoredataReposotory
        self.audioFileManager = AudioFileManager.getShared(Self.self)!

        audioFileManager
            .writeCachedAudioMetaDataOnFile(audioTracks: pageComponent.componentContents.tracks)
    }

    func removeAudioTrack(trackIndex: Int) -> (AudioTrack, UUID?) {
        let willPlayNextAudioID: UUID? =
            pageComponent.componentContents.tracks.count <= 1
            ? nil
            : {
                let natidx = trackIndex + 1 >= pageComponent.componentContents.tracks.count ? 0 : trackIndex + 1
                let nati = pageComponent.componentContents.tracks[natidx].id
                return nati
            }()

        let removedAudioTrack = pageComponent.componentContents.tracks.remove(at: trackIndex)

        audioFileManager.removeAudio(with: removedAudioTrack)
        pageComponent.actions.append(.removeAudio(removedAudioID: removedAudioTrack.id))
        memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: pageComponent)

        return (removedAudioTrack, willPlayNextAudioID)
    }

    func moveAudioTrackOrder(src: Int, des: Int) {
        pageComponent.componentContents.tracks.moveElement(src: src, des: des)
        pageComponent.componentContents.sortBy = .manual

        pageComponent.actions.append(.moveAudioOrder(src: src, des: des))
        memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: pageComponent)
    }

    func sortAudioTracks(sortBy: AudioTrackSortBy) -> [Int] {
        pageComponent.componentContents.sortBy = sortBy

        let before = pageComponent.componentContents.tracks.map { $0.id }

        switch sortBy {
            case .name:
                pageComponent.componentContents.tracks.sort(by: { $0.title < $1.title })

            case .createDate:
                pageComponent.componentContents.tracks.sort(by: { $0.createData > $1.createData })

            case .manual:
                break
        }

        let after = pageComponent.componentContents.tracks.map { $0.id }

        pageComponent.actions.append(.sortAudioTracks(sortBy: sortBy))
        memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: pageComponent)

        return after.compactMap { before.firstIndex(of: $0) }.map { Int($0) }
    }

    func downloadAudioTracksUsingCode(using code: String, _ drwaProgress: @escaping P) -> AR {
        audioDownloader.handleDownloadedProgressPercent = { drwaProgress($0) }

        return audioDownloader.downloadTask(with: code)
            .tryMap { try self.audioFileManager.extractAudioFileURLs(zipURL: $0) }
            .tryMapEnumerated { self.makeAudioTrackFromFileURL(audioFileUrl: $1) }
            .map { self.appendAudioTracks(audioTracks: $0) }
            .eraseToAnyPublisher()
    }

    func importAudiosFromLocal(urls: [URL]) -> AR {
        Just(urls)
            .setFailureType(to: Error.self)
            .mapEnumerated { self.makeAudioTrackFromFileURL(audioFileUrl: $1) }
            .map { self.appendAudioTracks(audioTracks: $0) }
            .eraseToAnyPublisher()
    }

    func applyAudioMetaDataChange(metadata: AudioTrackMetadata, activeTrackID: UUID?) -> EditingMetaDataResult? {
        let willChangeTrackID = metadata.audioTrackID
        let isEditCurrentlyPlayingAudio = activeTrackID == willChangeTrackID
        var trackIndexAfterApply: Int?

        if let willChangeTrackID = metadata.audioTrackID, let trackIndex = self[willChangeTrackID] {
            if let newTitle = metadata.title {
                pageComponent.componentContents.tracks[trackIndex].title = newTitle
            }
            if let newArtist = metadata.artist {
                pageComponent.componentContents.tracks[trackIndex].artist = newArtist
            }
            if let newLyrics = metadata.lyrics {
                pageComponent.componentContents.tracks[trackIndex].lyrics = newLyrics
            }
            if let newThumbnail = metadata.thumbnail {
                pageComponent.componentContents.tracks[trackIndex].thumbnail = newThumbnail
            }

            pageComponent.actions.append(.applyAudioMetadata(audioID: willChangeTrackID, metadata: metadata))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: pageComponent)

            audioFileManager.saveAudioMetaDataEditingTask(
                audioTrack: pageComponent.componentContents.tracks[trackIndex])

            if pageComponent.componentContents.sortBy == .name {
                pageComponent.componentContents.tracks.sort(by: { $0.title < $1.title })

                trackIndexAfterApply = pageComponent.componentContents.tracks.firstIndex {
                    $0.id == willChangeTrackID
                }
            }
            return EditingMetaDataResult(
                trackIndex: trackIndex,
                isEditingActiveTrack: isEditCurrentlyPlayingAudio,
                trackIndexAfterEditing: trackIndexAfterApply)
        } else {
            return nil
        }
    }

    func getActiveAudioTrackVisualizerData(at trackIndex: Int) -> ActiveAudioTrackVisualizerData {
        let audioTrack = pageComponent.componentContents.tracks[trackIndex]
        let audioTrackURL = audioFileManager.makeAudioTrackAppSandBoxURL(audioTrack: audioTrack)
        let audioPCMData = audioFileManager.readAudioPCMData(audioURL: audioTrackURL)
        let waveformData = scalingPCMDataToWaveformData(pcmData: audioPCMData)
        let duration = audioFileManager.readAudioMetadata(audioURL: audioTrackURL).duration
        let activeAudioTrackData = ActiveAudioTrackVisualizerData()

        activeAudioTrackData.setupNewVisualizerData(
            nowPlayingAudioComponentID: pageComponent.id,
            nowPlayingAudioTrackID: audioTrack.id,
            totalTime: duration,
            waveformData: waveformData)

        return activeAudioTrackData
    }

    func getAudioTrackMetaData(at trackIndex: Int) -> AudioTrackMetadata {
        let audioTrack = pageComponent.componentContents.tracks[trackIndex]
        let audioTrackURL = audioFileManager.makeAudioTrackAppSandBoxURL(audioTrack: audioTrack)
        var audioMetaData = audioFileManager.readAudioMetadata(audioURL: audioTrackURL)

        audioMetaData.audioTrackID = audioTrack.id
        audioMetaData.thumbnail = audioTrack.thumbnail
        audioMetaData.title = audioTrack.title
        audioMetaData.artist = audioTrack.artist
        return audioMetaData
    }

    func getNextAudioTrackIndex(trackID: UUID) -> Int? {
        if let idx = pageComponent.componentContents.tracks.firstIndex(where: { $0.id == trackID }) {
            return idx + 1 >= pageComponent.componentContents.tracks.count ? 0 : idx + 1
        } else {
            return nil
        }
    }

    func getPreviousAudioTrackIndex(trackID: UUID) -> Int? {
        if let idx = pageComponent.componentContents.tracks.firstIndex(where: { $0.id == trackID }) {
            return idx - 1 < 0 ? pageComponent.componentContents.tracks.count - 1 : idx - 1
        } else {
            return nil
        }
    }
}

extension AudioComponentDataManger {
    private func makeAudioTrackFromFileURL(audioFileUrl: URL) -> AudioTrack {
        let audioID = UUID()
        let audioFileName = "\(audioID).\(audioFileUrl.pathExtension)"
        let storedFileURL = audioFileManager.copyFilesToAppDirectory(src: audioFileUrl, des: audioFileName)
        let audioMetadata = audioFileManager.readAudioMetadata(audioURL: storedFileURL)

        var fileTitle = audioFileUrl.deletingPathExtension().lastPathComponent
        if fileTitle.isEmpty { fileTitle = .emptyAudioTitle }
        if let metadataTitle = audioMetadata.title, !metadataTitle.isEmpty { fileTitle = metadataTitle }

        let artist = audioMetadata.artist ?? .emptyAudioArtist
        let lyrics = audioMetadata.lyrics ?? ""
        let thumnnailImageData = audioMetadata.thumbnail ?? Data.defaultAudioThumbnailData

        let track = AudioTrack(
            id: audioID, title: fileTitle, artist: artist, thumbnail: thumnnailImageData,
            lyrics: lyrics, fileExtension: .init(rawValue: storedFileURL.pathExtension)!)

        audioFileManager.writeAudioMetadataWhenAppendNewAudio(audioTrack: track)
        return track
    }

    private func appendAudioTracks(audioTracks: [AudioTrack]) -> [Int] {
        pageComponent.componentContents.tracks.append(contentsOf: audioTracks)

        switch pageComponent.componentContents.sortBy {
            case .name:
                pageComponent.componentContents.tracks.sort(by: { $0.title < $1.title })

            case .createDate:
                pageComponent.componentContents.tracks.sort(by: { $0.createData > $1.createData })

            case .manual:
                break
        }

        var appendedIndices: [Int] = []

        for track in audioTracks {
            if let idx = pageComponent.componentContents.tracks.firstIndex(where: { $0.id == track.id }) {
                appendedIndices.append(idx)
            }
        }

        pageComponent.actions.append(.appendAudio(appendedIndices: appendedIndices, tracks: audioTracks))
        memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: pageComponent)

        return appendedIndices
    }

    private func scalingPCMDataToWaveformData(pcmData: AudioPCMData?) -> AudioWaveformData? {
        guard let pcmData else { return nil }
        let visualizerBarCount = 7
        let timerIntervalDivisor = 6.0
        let samplesPerBar = Int(pcmData.sampleRate / timerIntervalDivisor)
        var averagedPCMData: [Float] = []

        for i in 0..<(pcmData.PCMData.count / samplesPerBar) {
            let PCMDataSegment = pcmData.PCMData[i * samplesPerBar..<(i + 1) * samplesPerBar]
            let avg = PCMDataSegment.map { abs($0) }.reduce(0, +) / Float(PCMDataSegment.count)
            averagedPCMData.append(avg)
        }

        let maximumData = averagedPCMData.max()!
        let scaledPCMData =
            averagedPCMData
            .map { ($0 / maximumData) }
            .map { baseBarHeight in
                (0..<visualizerBarCount)
                    .map { _ in
                        max(0.1, min(1.0, baseBarHeight + Float.random(in: -0.25...0.25)))
                    }
            }

        return AudioWaveformData(
            sampleDataCount: pcmData.PCMData.count,
            sampleRate: pcmData.sampleRate,
            waveformData: scaledPCMData)
    }
	
	subscript(_ trackID: UUID) -> Int? {
		get { pageComponent.componentContents.tracks.firstIndex { $0.id == trackID } }
	}
}
