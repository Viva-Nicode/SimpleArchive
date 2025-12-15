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
        audioComponentDataSource.audioSampleData = AudioSampleData(
            sampleDataCount: 8,
            scaledSampleData: [-0.11, -0.21, 0.73, -0.24, -0.23, 0.332, -0.587, 0.57],
            sampleRate: 44100.0
        )
        audioComponentDataSource.getProgress = { .zero }

        testPage.appendChildComponent(component: audioComponent)
        self.audioComponent = audioComponent

        return (testPage, audioComponent.id, audioComponentDataSource)
    }
}
