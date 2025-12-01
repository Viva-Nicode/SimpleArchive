import Combine
import Foundation

@testable import SimpleArchive

final class MockAudioDownloader: Mock, AudioDownloaderType {

    enum Action: Equatable {
        case downloadAudioTask
    }

    var actions = MockActions<Action>(expected: [])
    var handleDownloadedProgressPercent: progressClosure?
    var downloadTaskResult: Result<URL, AudioDownloadError>!

    func downloadTask(with code: String) -> AnyPublisher<URL, AudioDownloadError> {
        register(.downloadAudioTask)
        return downloadTaskResult.publish()
    }
}
