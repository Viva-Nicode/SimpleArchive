import Foundation
import ZIPFoundation

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

    func getFixtureData() -> Any {
        switch provideState {
            case .givenFixtureData:
                provideState = .allDataConsumed
                let dummydata = makeAudioZip(fileCount: 3)
                return (response, dummydata)

            default:
                return ()
        }
    }

    private func makeAudioZip(fileCount: Int, fileSize: Int = 8_192) -> Data? {

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let zipURL = tempDir.appendingPathComponent(UUID().uuidString + ".zip")

        do {
            if fileManager.fileExists(atPath: zipURL.path) {
                try fileManager.removeItem(at: zipURL)
            }

            let archive = try Archive(url: zipURL, accessMode: .create)

            for index in 0..<fileCount {
                let fileName = "track_\(index + 1).mp3"
                let dummyData = makeDummyMP3Data(size: fileSize)

                try archive.addEntry(
                    with: fileName,
                    type: .file,
                    uncompressedSize: Int64(dummyData.count),
                    compressionMethod: .deflate,
                    bufferSize: 32_768,
                    provider: { position, size in
                        let start = Int(position)
                        let end = min(start + Int(size), dummyData.count)
                        return dummyData.subdata(in: start..<end)
                    }
                )
            }

            return try Data(contentsOf: zipURL)
        } catch {
            return nil
        }
    }

    private func makeDummyMP3Data(size: Int) -> Data {
        var data = Data()
        data.append(contentsOf: [0x49, 0x44, 0x33])  // ID3
        let remaining = max(0, size - data.count)
        data.append(
            Data((0..<remaining).map { _ in UInt8.random(in: 0...255) })
        )
        return data
    }
}
