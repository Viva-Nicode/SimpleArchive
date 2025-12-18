import Combine
import XCTest

@testable import SimpleArchive

final class AudioFileManagerTests: XCTestCase, FixtureProvidingTestCase {
    var fixtureProvider = AudioFileManagerTestFixtureProvider()
    var subscriptions: Set<AnyCancellable>!
    var sut: AudioFileManager!

    override func setUpWithError() throws {
        sut = AudioFileManager()
        self.subscriptions = []
    }

    override func tearDownWithError() throws {
        fixtureProvider.removeUsedFixtureData()
        subscriptions = nil
        sut.cleanFileSystem()
        sut = nil
    }

    func test_extractAudioFileURLs_successfully() throws {
        typealias FixtureType = ExtractAudioFileURLsSuccessfullyTestFixture

        let fixture = fixtureProvider.getFixture()
        let input = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        let zipURL = try XCTUnwrap(input)
        let audioFileURLs = try sut.extractAudioFileURLs(zipURL: zipURL)

        let expectedFileCount = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        XCTAssertEqual(expectedFileCount, audioFileURLs.count)

        let isExists = audioFileURLs.map { FileManager.default.fileExists(atPath: $0.path()) }.allSatisfy { $0 }
        let isAudioFileExt = audioFileURLs.map { ["mp3", "m4a"].contains($0.pathExtension) }.allSatisfy { $0 }

        XCTAssertTrue(isExists)
        XCTAssertTrue(isAudioFileExt)
    }

    func test_readAudioPCMData_successfully() throws {
        typealias FixtureType = ReadAudioPCMDataSuccessfullyTestFixture

        let fixture = fixtureProvider.getFixture()
        let testAudioURL = try XCTUnwrap(fixture.getFixtureData() as! FixtureType.TestTargetInputType)

        let factualPCMData = sut.readAudioPCMData(audioURL: testAudioURL)

        let (expectedSampleRate, expectedDuration) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        XCTAssertNotNil(factualPCMData)
        let factualSampleRate = try XCTUnwrap(factualPCMData?.sampleRate)
        XCTAssertEqual(factualSampleRate, expectedSampleRate, accuracy: 0.1)

        let expectedCount = Int(expectedSampleRate * expectedDuration)

        XCTAssertEqual(factualPCMData?.PCMData.count, expectedCount)
    }
}
