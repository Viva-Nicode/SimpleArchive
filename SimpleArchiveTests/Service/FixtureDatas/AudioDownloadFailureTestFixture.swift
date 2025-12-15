import Foundation

@testable import SimpleArchive

final class AudioDownloadFailureTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = HTTPURLResponse
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_audioDownload_failure()"
    private var provideState: TestDataProvideState = .givenFixtureData
    private let response: HTTPURLResponse = HTTPURLResponse(
        url: URL(fileURLWithPath: ""),
        statusCode: 500,
        httpVersion: nil,
        headerFields: nil)!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .allDataConsumed
                return response

            default:
                return ()
        }
    }
}
