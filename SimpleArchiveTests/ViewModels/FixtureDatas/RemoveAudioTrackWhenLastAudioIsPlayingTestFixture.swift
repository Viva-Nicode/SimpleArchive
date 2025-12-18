import Foundation

@testable import SimpleArchive

final class RemoveAudioTrackWhenLastAudioIsPlayingTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (MemoPageModel, UUID, AudioComponentDataSource)
    typealias TestTargetInputType = (UUID, Int)
    typealias ExpectedOutputType = (Int, Int)

    let testTargetName = "test_removeAudioTrack_whenLastAudioIsPlaying()"
    private var provideState: TestDataProvideState = .givenFixtureData

    private var audioComponent: AudioComponent!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return (audioComponent.id, 0)

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (3, 0)

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testPage = MemoPageModel(name: "test page")
        testPage.appendChildComponent(component: TextEditorComponent())
        testPage.appendChildComponent(component: TextEditorComponent())
        testPage.appendChildComponent(component: TextEditorComponent())
        let audioComponent = AudioComponent()

        audioComponent.componentContents.sortBy = .name
        _ = audioComponent.addAudios(audiotracks: [
            AudioTrack(title: "a audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3)
        ])

        let audioComponentDataSource = AudioComponentDataSource(
            tracks: audioComponent.componentContents.tracks,
            sortBy: audioComponent.componentContents.sortBy
        )

        audioComponentDataSource.nowPlayingAudioIndex = 0
        audioComponentDataSource.isPlaying = true
        audioComponentDataSource.nowPlayingURL = URL(fileURLWithPath: "Documents/SimpleArchiveMusics/a audio.mp3")

        // 1:32
        audioComponentDataSource.audioVisualizerData = AudioWaveformData(
            sampleDataCount: 92 * 44_100,
            sampleRate: 44100.0,
            waveformData: (0..<92 * 6).map { _ in (0..<7).map { _ in Float.random(in: 0...1.0) } }
        )
        audioComponentDataSource.getProgress = { .zero }

        testPage.appendChildComponent(component: audioComponent)
        self.audioComponent = audioComponent

        return (testPage, audioComponent.id, audioComponentDataSource)
    }
}
