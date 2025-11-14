import Combine
import Foundation
import UIKit
import ZIPFoundation
import SFBAudioEngine

protocol AudioDownloaderType {
    typealias progressClosure = ((Float) -> Void)
    func downloadTask(with code: String) -> AnyPublisher<[AudioTrack], AudioDownloadError>
    var handleDownloadedProgressPercent: progressClosure? { get set }
}

enum AudioDownloadError: Error {
    case invalidCode
    case unowned(String)
}

final class AudioDownloader: NSObject, AudioDownloaderType {
    var handleDownloadedProgressPercent: progressClosure?
    private var totalDownloaded: Float = 0 {
        didSet {
            self.handleDownloadedProgressPercent?(totalDownloaded)
        }
    }

    private lazy var session: URLSession = {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        return session
    }()

    private var promise: ((Result<[AudioTrack], AudioDownloadError>) -> Void)!
    private var tempLocalURL: URL!

    func downloadTask(with code: String) -> AnyPublisher<[AudioTrack], AudioDownloadError> {
        Future<[AudioTrack], AudioDownloadError> { promise in
            self.promise = promise
            let url = URL(string: "http://1.246.134.84/simpleArchive/downloadMusic?code=\(code)")!
            self.session.downloadTask(with: url).resume()
        }
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}

extension AudioDownloader: URLSessionTaskDelegate {

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error {
            promise(.failure(AudioDownloadError.unowned(error.localizedDescription)))
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            promise(.failure(AudioDownloadError.invalidCode))
            return
        }

        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveDir = documentsDir.appendingPathComponent("SimpleArchiveMusics")
        let unzipTempDir = documentsDir.appendingPathComponent("downloaded_music_temp")
        var audioTracks: [AudioTrack] = []

        do {
            if !fileManager.fileExists(atPath: archiveDir.path) {
                try fileManager.createDirectory(at: archiveDir, withIntermediateDirectories: true)
            }

            try fileManager.unzipItem(at: tempLocalURL, to: unzipTempDir)

            let files = try fileManager.contentsOfDirectory(at: unzipTempDir, includingPropertiesForKeys: nil)

            for fileURL in files where ["mp3", "m4a"].contains(fileURL.pathExtension.lowercased()) {
                let newID = UUID()
                let newFileName = "\(newID).\(fileURL.pathExtension)"
                let newFileURL = archiveDir.appendingPathComponent(newFileName)
                var fileTitle = fileURL.deletingPathExtension().lastPathComponent
                var artist: String = "Unknown"
                let defaultAudioThumbnail = UIImage(named: "defaultMusicThumbnail")!
                let defaultThumnnailData = defaultAudioThumbnail.jpegData(compressionQuality: 1.0)!
                var defaultThumbnail = AttachedPicture(imageData: defaultThumnnailData, type: .frontCover)

                if fileTitle.isEmpty { fileTitle = "no title" }

                if let audioFile = try? AudioFile(readingPropertiesAndMetadataFrom: fileURL) {

                    if let metadataTitle = audioFile.metadata.title, !metadataTitle.isEmpty {
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

                try fileManager.moveItem(at: fileURL, to: newFileURL)

                let track = AudioTrack(
                    id: newID,
                    title: fileTitle,
                    artist: artist,
                    thumbnail: defaultThumbnail.imageData,
                    fileExtension: fileURL.pathExtension)

                audioTracks.append(track)
            }

            try? fileManager.removeItem(at: unzipTempDir)
            try? fileManager.removeItem(at: tempLocalURL)

            promise(.success(audioTracks))
        } catch {
            promise(.failure(AudioDownloadError.unowned(error.localizedDescription)))
        }
    }
}

extension AudioDownloader: URLSessionDownloadDelegate {
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) { self.totalDownloaded = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let tempCopyURL = documentsDir.appendingPathComponent("downloaded_music_temp.zip")

        do {
            try? fileManager.removeItem(at: tempCopyURL)
            try fileManager.moveItem(at: location, to: tempCopyURL)
            self.tempLocalURL = tempCopyURL
        } catch {
            promise(.failure(AudioDownloadError.unowned(error.localizedDescription)))
        }
    }
}
