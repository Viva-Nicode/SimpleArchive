import AVFoundation
import Foundation
import SFBAudioEngine
import ZIPFoundation

protocol AudioFileRemover {
    func removeAudio(with audio: AudioTrack)
}

protocol AudioFileManagerType: AudioFileRemover {
    func makeAudioTrackAppSandBoxURL(audioTrack: AudioTrack) -> URL

    func copyFilesToAppDirectory(src: URL, des: String) -> URL
    func extractAudioFileURLs(zipURL: URL) throws -> [URL]

    func readAudioMetadata(audioURL: URL) -> AudioTrackMetadata
    func readAudioPCMData(audioURL: URL?) -> AudioPCMData?

    func writeAudioMetadataWhenAppendNewAudio(audioTrack: AudioTrack)
    func writeCachedAudioMetaDataOnFile(audioTracks: [AudioTrack])

    func saveAudioMetaDataEditingTask(audioTrack: AudioTrack)
}

final class AudioFileManager: NSObject, AudioFileManagerType {
    private var fileManager = FileManager.default
    private var audioMetaDataWriter: AudioMetadataWriterType = AudioMetadataWriter()
    private let musicArchiveDirectoryURL: URL

    private static let shared = AudioFileManager()

    private override init() {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        musicArchiveDirectoryURL = documentsDir.appendingPathComponent("SimpleArchiveMusics")

        if !fileManager.fileExists(atPath: musicArchiveDirectoryURL.path) {
            try? fileManager.createDirectory(at: musicArchiveDirectoryURL, withIntermediateDirectories: true)
        }
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    static func getShared<UIT>(_ callerType: Any.Type) -> UIT? {
        let AudioComponentInteractorDependency =
            callerType == AudioComponentDataManger.self && UIT.self == AudioFileManagerType.self
        let DormantBoxViewModelDependency =
            callerType == DormantBoxViewModel.self && UIT.self == AudioFileRemover.self

        if AudioComponentInteractorDependency || DormantBoxViewModelDependency {
            return self.shared as? UIT
        } else {
            return nil
        }
    }

    func makeAudioTrackAppSandBoxURL(audioTrack: AudioTrack) -> URL {
        let fileName = "\(audioTrack.id).\(audioTrack.fileExtension)"
        return musicArchiveDirectoryURL.appendingPathComponent(fileName)
    }

    func copyFilesToAppDirectory(src: URL, des: String) -> URL {
        let destinationURL = musicArchiveDirectoryURL.appendingPathComponent(des)

        let isNeed = isNeedPermision(src)

        if isNeed {
            guard src.startAccessingSecurityScopedResource() else { return destinationURL }
        }

        try? fileManager.copyItem(at: src, to: destinationURL)
        if isNeed { src.stopAccessingSecurityScopedResource() }
        return destinationURL
    }

    func extractAudioFileURLs(zipURL: URL) throws -> [URL] {
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let unzipURL = documentsDir.appendingPathComponent("downloaded_music_temp")

        if fileManager.fileExists(atPath: unzipURL.path) {
            try fileManager.removeItem(at: unzipURL)
        }

        try fileManager.unzipItem(at: zipURL, to: unzipURL)
        let files = try fileManager.contentsOfDirectory(at: unzipURL, includingPropertiesForKeys: nil)
        return files.filter { ["mp3", "m4a"].contains($0.pathExtension.lowercased()) }
    }

    func readAudioMetadata(audioURL: URL) -> AudioTrackMetadata {
        var metadata = AudioTrackMetadata()
        metadata.audioURL = audioURL

        if let audioFile = try? AudioFile(readingPropertiesAndMetadataFrom: audioURL) {
            metadata.duration = audioFile.properties.duration

            if let metadataTitle = audioFile.metadata.title, !metadataTitle.isEmpty {
                metadata.title = metadataTitle
            }
            if let metadataArtist = audioFile.metadata.artist, !metadataArtist.isEmpty {
                metadata.artist = metadataArtist
            }
            if let metadataLyrics = audioFile.metadata.lyrics, !metadataLyrics.isEmpty {
                metadata.lyrics = metadataLyrics
            }
            if let metadataThumbnail = audioFile.metadata.attachedPictures(ofType: .frontCover).first {
                metadata.thumbnail = metadataThumbnail.imageData
            } else if let metadataOtherThumbnail = audioFile.metadata.attachedPictures(ofType: .other).first {
                metadata.thumbnail = metadataOtherThumbnail.imageData
            }
        }
        return metadata
    }

    func readAudioPCMData(audioURL: URL?) -> AudioPCMData? {
        guard let audioURL, let file = try? AVAudioFile(forReading: audioURL) else {
            return nil
        }

        let audioFormat = file.processingFormat
        let audioFrameCount = UInt32(file.length)
        let sampleRate = audioFormat.sampleRate

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
        else { return nil }

        do {
            try file.read(into: buffer)
        } catch {
            return nil
        }

        let PCMData = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))

        return AudioPCMData(sampleRate: sampleRate, PCMData: Array(PCMData))
    }

    func writeAudioMetadataWhenAppendNewAudio(audioTrack: AudioTrack) {
        let trackURL = makeAudioTrackAppSandBoxURL(audioTrack: audioTrack)
        DispatchQueue.global(qos: .background)
            .async {
                self.audioMetaDataWriter.writeMetaDataOnAudioFile(audioTrack: audioTrack, url: trackURL)
            }
    }

    func saveAudioMetaDataEditingTask(audioTrack: AudioTrack) {
        let trackURL = makeAudioTrackAppSandBoxURL(audioTrack: audioTrack)
        DispatchQueue.global(qos: .background)
            .async {
                self.audioMetaDataWriter.saveMetaDataWritingTask(trackID: audioTrack.id, audioURL: trackURL)
            }
    }

    func writeCachedAudioMetaDataOnFile(audioTracks: [AudioTrack]) {
        DispatchQueue.global()
            .async {
                self.audioMetaDataWriter.writeSavedMetaDataOnAudioFile(audioTracks: audioTracks)
            }
    }

    func removeAudio(with audio: AudioTrack) {
        let trackURL =
            musicArchiveDirectoryURL
            .appendingPathComponent("\(audio.id)")
            .appendingPathExtension(audio.fileExtension.rawValue)
        audioMetaDataWriter.removeMetaDataWritingTask(trackID: audio.id)
        try? fileManager.removeItem(at: trackURL)
    }

    private func isNeedPermision(_ url: URL) -> Bool {
        let sandboxRoots: [URL] = [
            fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!,
            fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first!,
            fileManager.temporaryDirectory,
        ]
        let isInsideSandbox = sandboxRoots.contains {
            url.standardizedFileURL.path.hasPrefix($0.standardizedFileURL.path)
        }
        return !isInsideSandbox
    }
}

struct AudioTrackMetadata: Codable, Equatable {
    var audioTrackID: UUID?
    var audioURL: URL?
    var title: String?
    var artist: String?
    var lyrics: String?
    var thumbnail: Data?
    var duration: TimeInterval?
}

struct AudioPCMData: Codable, Equatable {
    let sampleRate: Double
    let PCMData: [Float]
}
