import Foundation
import SFBAudioEngine
import ZIPFoundation

protocol AudioFileManagerType {
    func createAudioFileURL(fileName: String) -> URL
    func removeAudio(with audio: AudioTrack)

    func copyFilesToAppDirectory(src: URL, des: String) -> URL
    func extractAudioFileURLs(zipURL: URL) throws -> [URL]
    func moveItem(src: URL, fileName: String) throws

    func readAudioMetadata(audioURL: URL) -> AudioTrackMetadata
    func readAudioPCMData(audioURL: URL?) -> AudioPCMData?
    func writeAudioMetadata(audioTrack: AudioTrack)
}

final class AudioFileManager: NSObject, AudioFileManagerType {

    private var fileManager = FileManager.default
    private let archiveURL: URL

    override init() {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        archiveURL = documentsDir.appendingPathComponent("SimpleArchiveMusics")

        if !fileManager.fileExists(atPath: archiveURL.path) {
            try? fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)
        }
    }

    deinit { print("deinit AudioFileManager") }

    func createAudioFileURL(fileName: String) -> URL {
        archiveURL.appendingPathComponent(fileName)
    }

    func removeAudio(with audio: AudioTrack) {
        let trackURL =
            archiveURL
            .appendingPathComponent("\(audio.id)")
            .appendingPathExtension(audio.fileExtension.rawValue)
        try? fileManager.removeItem(at: trackURL)
    }

    func copyFilesToAppDirectory(src: URL, des: String) -> URL {
        guard src.startAccessingSecurityScopedResource() else { fatalError() }
        defer { src.stopAccessingSecurityScopedResource() }

        let destinationURL = archiveURL.appendingPathComponent(des)
        try? fileManager.copyItem(at: src, to: destinationURL)
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

    func moveItem(src: URL, fileName: String) throws {
        let des = archiveURL.appendingPathComponent(fileName)
        try fileManager.moveItem(at: src, to: des)
    }

    func readAudioMetadata(audioURL: URL) -> AudioTrackMetadata {
        var metadata = AudioTrackMetadata()

        if let audioFile = try? AudioFile(readingPropertiesAndMetadataFrom: audioURL) {

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

        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
        else { return nil }

        do {
            try file.read(into: buffer)
        } catch {
            print("\(#function) : \(error)")
            return nil
        }

        let PCMData = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))
        let sampleRate = audioFormat.sampleRate
        return AudioPCMData(sampleRate: sampleRate, PCMData: Array(PCMData))
    }

    func writeAudioMetadata(audioTrack: AudioTrack) {

        let fileName = "\(audioTrack.id).\(audioTrack.fileExtension)"
        let trackURL = archiveURL.appendingPathComponent(fileName)

        if let audioFile = try? AudioFile(readingPropertiesAndMetadataFrom: trackURL) {
            let picture = AttachedPicture(imageData: audioTrack.thumbnail, type: .frontCover)

            let audioMetadata = AudioMetadata(dictionaryRepresentation: [
                .attachedPictures: [picture.dictionaryRepresentation] as NSArray,
                .title: NSString(string: audioTrack.title),
                .artist: NSString(string: audioTrack.artist),
                .lyrics: NSString(string: audioTrack.lyrics),
            ])

            audioFile.metadata = audioMetadata
            try? audioFile.writeMetadata()
        }
    }
}

struct AudioTrackMetadata: Codable, Equatable {
    var title: String?
    var artist: String?
    var lyrics: String?
    var thumbnail: Data?
}

struct AudioPCMData: Codable, Equatable {
    let sampleRate: Double
    let PCMData: [Float]
}

#if DEBUG
    extension AudioFileManager {
        func cleanFileSystem() {
            guard fileManager.fileExists(atPath: archiveURL.path) else { return }

            do {
                let contents = try fileManager.contentsOfDirectory(
                    at: archiveURL,
                    includingPropertiesForKeys: nil,
                    options: []
                )

                for url in contents {
                    try fileManager.removeItem(at: url)
                }
            } catch {
                assertionFailure("Failed to clean audio file system: \(error)")
            }
        }
    }
#endif
