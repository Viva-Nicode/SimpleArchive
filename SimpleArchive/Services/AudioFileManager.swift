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
    func readAudioSampleData(audioURL: URL?) -> AudioSampleData?
    func writeAudioMetadata(audioTrack: AudioTrack)
}

final class AudioFileManager: NSObject, AudioFileManagerType {

    private var fileManager = FileManager.default
    private let archiveURL: URL

    override init() {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        self.archiveURL = documentsDir.appendingPathComponent("SimpleArchiveMusics")

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
            .appendingPathExtension(audio.fileExtension)
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

            if let metadataThumbnail = audioFile.metadata.attachedPictures(ofType: .frontCover).first {
                metadata.thumbnail = metadataThumbnail.imageData
            } else if let metadataOtherThumbnail = audioFile.metadata.attachedPictures(ofType: .other).first {
                metadata.thumbnail = metadataOtherThumbnail.imageData
            }
        }
        return metadata
    }

    func readAudioSampleData(audioURL: URL?) -> AudioSampleData? {
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

    func writeAudioMetadata(audioTrack: AudioTrack) {

        let fileName = "\(audioTrack.id).\(audioTrack.fileExtension)"
        let trackURL = archiveURL.appendingPathComponent(fileName)

        if let audioFile = try? AudioFile(readingPropertiesAndMetadataFrom: trackURL) {
            let picture = AttachedPicture(imageData: audioTrack.thumbnail, type: .frontCover)

            let audioMetadata = AudioMetadata(dictionaryRepresentation: [
                .attachedPictures: [picture.dictionaryRepresentation] as NSArray,
                .title: NSString(string: audioTrack.title),
                .artist: NSString(string: audioTrack.artist),
            ])

            audioFile.metadata = audioMetadata
            try? audioFile.writeMetadata()
        }
    }
}

struct AudioTrackMetadata: Equatable {
    var title: String?
    var artist: String?
    var thumbnail: Data?
}

struct AudioSampleData: Codable, Equatable {
    var sampleDataCount: Int
    var scaledSampleData: [Float]
    var sampleRate: Double
}
