import Foundation

@testable import SimpleArchive

final class AudioDownloadSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (HTTPURLResponse, Data?)
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_audioDownload_successfully()"
    private var provideState: TestDataProvideState = .givenFixtureData
    private let response = HTTPURLResponse(
        url: URL(fileURLWithPath: ""),
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil)!
    private let dummydata = ZipArchiveBuilder.makeAudioZip(fileCount: 3)

    func getFixtureData() -> Any {
        switch provideState {
            case .givenFixtureData:
                provideState = .allDataConsumed
                return (response, dummydata)

            default:
                return ()
        }
    }
}
