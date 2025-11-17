import Combine
import Foundation
import UIKit

protocol AudioDownloaderType {
    typealias progressClosure = ((Float) -> Void)

    var handleDownloadedProgressPercent: progressClosure? { get set }

    func downloadTask(with code: String) -> AnyPublisher<[URL], AudioDownloadError>
}

enum AudioDownloadError: Error {
    case invalidCode
    case fileManagingError(Error)
    case unowned(Error)
}

final class AudioDownloader: NSObject, AudioDownloaderType {
    var handleDownloadedProgressPercent: progressClosure?
    private var audioFileManager: AudioFileManagerType

    init(audioFileManager: AudioFileManagerType) {
        self.audioFileManager = audioFileManager
    }

    deinit { print("deinit AudioDownloader") }

    private var totalDownloaded: Float = 0 {
        didSet {
            self.handleDownloadedProgressPercent?(totalDownloaded)
        }
    }

    private lazy var session: URLSession = {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        return session
    }()

    private var promise: ((Result<[URL], AudioDownloadError>) -> Void)!

    func downloadTask(with code: String) -> AnyPublisher<[URL], AudioDownloadError> {
        Future<[URL], AudioDownloadError> { promise in
            self.promise = promise
            let url = URL(string: "http://1.246.134.84/simpleArchive/downloadMusic?code=\(code)")!
            self.session
                .downloadTask(with: url)
                .resume()
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
            promise(.failure(AudioDownloadError.unowned(error)))
            return
        }

        guard let httpResponse = task.response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            promise(.failure(AudioDownloadError.invalidCode))
            return
        }

        do {
            let audioFileUrls = try audioFileManager.extractAudioFileURLs()
            promise(.success(audioFileUrls))
        } catch {
            promise(.failure(AudioDownloadError.fileManagingError(error)))
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
            try audioFileManager.moveDownloadFile(location: location)
        } catch {
            promise(.failure(AudioDownloadError.fileManagingError(error)))
        }
    }
}
