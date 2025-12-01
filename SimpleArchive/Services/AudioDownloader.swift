import Combine
import Foundation
import UIKit

protocol AudioDownloaderType {
    typealias progressClosure = ((Float) -> Void)
    var handleDownloadedProgressPercent: progressClosure? { get set }
    func downloadTask(with code: String) -> AnyPublisher<URL, AudioDownloadError>
}

enum AudioDownloadError: Error {
    case invalidCode
    case fileManagingError(Error)
    case unowned(Error)
}

final class AudioDownloader: NSObject, AudioDownloaderType {
    var handleDownloadedProgressPercent: progressClosure?
    private var zipURL: URL!
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

    private var promise: ((Result<URL, AudioDownloadError>) -> Void)!

    func downloadTask(with code: String) -> AnyPublisher<URL, AudioDownloadError> {
        Future<URL, AudioDownloadError> { promise in
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

        promise(.success(zipURL))
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
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        zipURL = documentsDir.appendingPathComponent("downloaded_music_temp.zip")
//        file:///Users/nicode./Library/Developer/CoreSimulator/Devices/C4906AB1-BB48-4D3E-A7A8-397C29A281D3/data/Containers/Data/Application/B7AA7C02-DC03-4B6B-A9F5-814AAB804962/Documents/downloaded_music_temp.zip
        do {
            if fileManager.fileExists(atPath: zipURL.path) {
                try fileManager.removeItem(at: zipURL)
            }
            try fileManager.moveItem(at: location, to: zipURL)
        } catch {
            promise(.failure(AudioDownloadError.fileManagingError(error)))
        }
    }
}
