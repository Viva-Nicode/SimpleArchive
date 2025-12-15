import Combine
import XCTest

@testable import SimpleArchive

final class AudioDownloaderTests: XCTestCase, FixtureProvidingTestCase {
    var sut: AudioDownloader!
    var fixtureProvider = AudioDownloaderTestFixtureProvider()
    var subscriptions: Set<AnyCancellable>!

    override func setUpWithError() throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]

        self.sut = AudioDownloader(
            configuration: configuration,
            urlString: "http://fakeURL/simpleArchive/downloadMusic?code=")
        self.subscriptions = []
    }

    override func tearDownWithError() throws {
        subscriptions = nil
        sut = nil
    }

    func test_audioDownload_successfully() throws {
        typealias FixtureType = AudioDownloadSuccessfullyTestFixture

        let fixture = fixtureProvider.getFixture()
        let (response, data) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        let dummyZipData = try XCTUnwrap(data)
        MockURLProtocol.responseStub = .init(response: response, data: dummyZipData)

        let expectation = XCTestExpectation(description: #function)

        sut.downloadTask(with: "fakeDownloadCode")
            .sinkToResult { result in
                switch result {
                    case .success(let success):
                        let factual = try? Data(contentsOf: success)
                        XCTAssertEqual(factual, dummyZipData)

                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                }
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
    }

    func test_audioDownload_failure() throws {
        typealias FixtureType = AudioDownloadFailureTestFixture

        let fixture = fixtureProvider.getFixture()
        let response = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        MockURLProtocol.responseStub = .init(response: response, data: Data())

        let expectation = XCTestExpectation(description: #function)

        sut.downloadTask(with: "fakeDownloadCode")
            .sinkToResult { result in
                guard case .failure(let audioDownloadError) = result else {
                    XCTFail("Unexpected output")
                    return
                }
                guard case .invalidCode = audioDownloadError else {
                    XCTFail("Expected fileManagingError")
                    return
                }
                expectation.fulfill()
            }
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
    }
}
