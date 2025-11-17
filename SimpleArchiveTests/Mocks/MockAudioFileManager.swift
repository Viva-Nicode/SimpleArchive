import Foundation

@testable import SimpleArchive

final class MockAudioFileManager: NSObject, AudioFileManagerType {
    
    func removeAudio(with audio: SimpleArchive.AudioTrack) {
        <#code#>
    }

    func copyFilesToAppDirectory(src: URL, des: String) -> URL {
        <#code#>
    }

    func moveItem(src: URL, des: URL) throws {
        <#code#>
    }

    func moveDownloadFile(location: URL) throws {
        <#code#>
    }

    func extractAudioFileURLs() throws -> [URL] {
        <#code#>
    }

    func createAudioFileURL(fileName: String) -> URL {
        <#code#>
    }

    func cleanTempDirectories() throws {
        <#code#>
    }

    func readAudioMetadata(audioURL: URL) -> SimpleArchive.AudioTrackMetadata {
        <#code#>
    }

    func writeAudioMetadata(audioTrack: SimpleArchive.AudioTrack) {
        <#code#>
    }
}
