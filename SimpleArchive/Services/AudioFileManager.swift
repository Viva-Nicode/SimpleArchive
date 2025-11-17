import Foundation
import SFBAudioEngine
import ZIPFoundation

protocol AudioFileManagerType {
    func removeAudio(with audio: AudioTrack)
    func copyFilesToAppDirectory(src: URL, des: String) -> URL
    func moveItem(src: URL, des: URL) throws
    func moveDownloadFile(location: URL) throws
    func extractAudioFileURLs() throws -> [URL]
    func createAudioFileURL(fileName: String) -> URL
    func cleanTempDirectories() throws
    func readAudioMetadata(audioURL: URL) -> AudioTrackMetadata
    func writeAudioMetadata(audioTrack: AudioTrack)
}

final class AudioFileManager: NSObject, AudioFileManagerType {

    private var fileManager = FileManager.default
    private let archiveDir: URL
    private let zipURL: URL
    private let unzipURL: URL
    static let `default`: AudioFileManagerType = AudioFileManager()

    private override init() {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        self.archiveDir = documentsDir.appendingPathComponent("SimpleArchiveMusics")
        self.zipURL = documentsDir.appendingPathComponent("downloaded_music_temp.zip")
        self.unzipURL = documentsDir.appendingPathComponent("downloaded_music_temp")

        if !fileManager.fileExists(atPath: archiveDir.path) {
            try? fileManager.createDirectory(at: archiveDir, withIntermediateDirectories: true)
        }
    }

    func removeAudio(with audio: AudioTrack) {
        let trackURL =
            archiveDir
            .appendingPathComponent("\(audio.id)")
            .appendingPathExtension(audio.fileExtension)
        try? fileManager.removeItem(at: trackURL)
    }

    func createAudioFileURL(fileName: String) -> URL {
        archiveDir.appendingPathComponent(fileName)
    }

    func moveItem(src: URL, des: URL) throws {
        try fileManager.moveItem(at: src, to: des)
    }

    func copyFilesToAppDirectory(src: URL, des: String) -> URL {
        guard src.startAccessingSecurityScopedResource() else { fatalError() }
        defer { src.stopAccessingSecurityScopedResource() }

        let destinationURL = archiveDir.appendingPathComponent(des)
        try? fileManager.copyItem(at: src, to: destinationURL)
        return destinationURL
    }

    func moveDownloadFile(location: URL) throws {
        if fileManager.fileExists(atPath: zipURL.path) {
            try fileManager.removeItem(at: zipURL)
        }
        try fileManager.moveItem(at: location, to: zipURL)
    }

    func extractAudioFileURLs() throws -> [URL] {
        try fileManager.unzipItem(at: zipURL, to: unzipURL)
        let files = try fileManager.contentsOfDirectory(at: unzipURL, includingPropertiesForKeys: nil)
        return files.filter { ["mp3", "m4a"].contains($0.pathExtension.lowercased()) }
    }

    func cleanTempDirectories() throws {
        if fileManager.fileExists(atPath: zipURL.path) {
            try fileManager.removeItem(at: zipURL)
        }
        if fileManager.fileExists(atPath: unzipURL.path) {
            try fileManager.removeItem(at: unzipURL)
        }
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

    func writeAudioMetadata(audioTrack: AudioTrack) {

        let fileName = "\(audioTrack.id).\(audioTrack.fileExtension)"
        let trackURL = createAudioFileURL(fileName: fileName)

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
