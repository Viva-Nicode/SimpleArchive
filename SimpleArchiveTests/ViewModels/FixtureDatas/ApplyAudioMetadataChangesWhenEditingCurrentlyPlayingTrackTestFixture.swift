import Foundation

@testable import SimpleArchive

final class ApplyAudioMetadataChangesWhenEditingCurrentlyPlayingTrackTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoPageModel
    typealias TestTargetInputType = (UUID, AudioTrackMetadata, Int)
    typealias ExpectedOutputType = (Int, Int, AudioTrackMetadata, Bool, Int?)

    let testTargetName = "test_ApplyAudioMetadataChanges_whenEditingCurrentlyPlayingTrack()"
    private var provideState: TestDataProvideState = .givenFixtureData
    private var audioComponent: AudioComponent!

    func getFixtureData() -> Any {
        switch provideState {
            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return TestTargetInputType(
                    audioComponent.id,
                    AudioTrackMetadata(
                        title: "l audio",
                        artist: "artist",
                        thumbnail: Data()
                    ), 3)

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return ExpectedOutputType(
                    3, 3,
                    AudioTrackMetadata(
                        title: "l audio",
                        artist: "artist",
                        thumbnail: Data()
                    ), true, 6)

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

        audioComponent.detail.sortBy = .name
        _ = audioComponent.addAudios(audiotracks: [
            AudioTrack(title: "a audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "b audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "d audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "e audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "f audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "g audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "k audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "m audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
        ])

        let audioComponentDataSource = AudioComponentDataSource(
            tracks: audioComponent.detail.tracks,
            sortBy: audioComponent.detail.sortBy
        )

        audioComponentDataSource.nowPlayingAudioIndex = 3
        audioComponentDataSource.isPlaying = true
        audioComponentDataSource.nowPlayingURL = URL(fileURLWithPath: "Documents/SimpleArchiveMusics/e audio.mp3")
        audioComponentDataSource.audioSampleData = AudioSampleData(
            sampleDataCount: 8,
            scaledSampleData: [-0.11, -0.21, 0.73, -0.24, -0.23, 0.332, -0.587, 0.57],
            sampleRate: 44100.0
        )
        audioComponentDataSource.getProgress = { .zero }

        audioComponent.datasource = audioComponentDataSource

        testPage.appendChildComponent(component: audioComponent)
        self.audioComponent = audioComponent

        return testPage
    }
}
