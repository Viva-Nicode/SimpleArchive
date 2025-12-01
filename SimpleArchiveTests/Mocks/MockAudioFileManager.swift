import Foundation
import XCTest

@testable import SimpleArchive

final class MockAudioFileManager: Mock, AudioFileManagerType {

    enum Action: Equatable {
        case removeAudio
        case copyFilesToAppDirectory
        case moveItem
        case extractAudioFileURLs
        case createAudioFileURL
        case readAudioMetadata
        case readAudioSampleData
        case writeAudioMetadata
    }

    var actions = MockActions<Action>(expected: [])

    var copyFilesToAppDirectoryResult: [URL]!
    var createAudioFileURLResult: [URL]!
    var extractAudioFileURLsResult: [URL]!
    var readAudioMetadataResult: [AudioTrackMetadata]!
    var readAudioSampleDataResult: AudioSampleData!

    func createAudioFileURL(fileName: String) -> URL {
        register(.createAudioFileURL)
        return createAudioFileURLResult.removeFirst()
    }

    func removeAudio(with audio: AudioTrack) {
        register(.removeAudio)
    }

    func copyFilesToAppDirectory(src: URL, des: String) -> URL {
        register(.copyFilesToAppDirectory)
        return copyFilesToAppDirectoryResult.removeFirst()
    }

    func extractAudioFileURLs(zipURL: URL) throws -> [URL] {
        register(.extractAudioFileURLs)
        return extractAudioFileURLsResult
    }

    func moveItem(src: URL, fileName: String) throws {
        register(.moveItem)
    }

    func readAudioMetadata(audioURL: URL) -> AudioTrackMetadata {
        register(.readAudioMetadata)
        return readAudioMetadataResult.removeFirst()
    }

    func readAudioSampleData(audioURL: URL?) -> AudioSampleData? {
        register(.readAudioSampleData)
        return readAudioSampleDataResult
    }

    func writeAudioMetadata(audioTrack: AudioTrack) {
        register(.writeAudioMetadata)
    }
}
