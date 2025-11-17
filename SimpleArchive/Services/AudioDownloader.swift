import Combine
import Foundation
import UIKit

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

        var audioTracks: [AudioTrack] = []
        let audioFileManager = AudioFileManager.default

        do {
            let audioFileUrls = try audioFileManager.extractAudioFileURLs()

            for audioURL in audioFileUrls {

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
                let newFileURL = audioFileManager.createAudioFileURL(fileName: audioFileName)
                try audioFileManager.moveItem(src: audioURL, des: newFileURL)

                let track = AudioTrack(
                    id: audioFileID,
                    title: fileTitle,
                    artist: artist,
                    thumbnail: thumnnailImageData,
                    fileExtension: audioURL.pathExtension)

                audioFileManager.writeAudioMetadata(audioTrack: track)
                audioTracks.append(track)
            }

            try audioFileManager.cleanTempDirectories()

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
        do {
            try AudioFileManager.default.moveDownloadFile(location: location)
        } catch {
            promise(.failure(AudioDownloadError.unowned(error.localizedDescription)))
        }
    }
}
