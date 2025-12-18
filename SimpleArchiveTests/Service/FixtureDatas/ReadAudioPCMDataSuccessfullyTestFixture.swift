import AVFAudio
import Foundation

@testable import SimpleArchive

final class ReadAudioPCMDataSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = NoUsed
    typealias TestTargetInputType = URL?
    typealias ExpectedOutputType = (Double, Double)

    let testTargetName = "test_readAudioPCMData_successfully()"
    private var provideState: TestDataProvideState = .testTargetInput
    private var url: URL?

    func getFixtureData() -> Any {
        switch provideState {
            case .testTargetInput:
                provideState = .testVerifyOutput
                url = try? createFakePCMData()
                return url as Any

            case .testVerifyOutput:
                provideState = .allDataConsumed
                try? FileManager.default.removeItem(at: url!)
                return (44100.0, 1.0)

            default:
                return ()
        }
    }

    private func createFakePCMData() throws -> URL? {
        let testFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_pcm_wave.wav")
        let duration: TimeInterval = 1.0
        let sampleRate: Double = 44100.0

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]

        let file = try AVAudioFile(
            forWriting: testFileURL,
            settings: settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false)

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount)
        else { return nil }

        buffer.frameLength = frameCount
        let channels = buffer.floatChannelData!

        for i in 0..<Int(frameCount) {
            channels[0][i] = Float.random(in: -1.0...1.0)
        }

        try file.write(from: buffer)

        return testFileURL
    }
}
