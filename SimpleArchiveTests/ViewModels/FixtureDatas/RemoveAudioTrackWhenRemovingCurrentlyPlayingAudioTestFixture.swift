import Foundation

@testable import SimpleArchive

final class RemoveAudioTrackWhenRemovingCurrentlyPlayingAudioTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (MemoPageModel, UUID, URL, AudioSampleData, AudioTrackMetadata, TimeInterval, Bool)
    typealias TestTargetInputType = (UUID, Int)
    typealias ExpectedOutputType = (Int, Int, Int, TimeInterval, AudioTrackMetadata, AudioSampleData, URL)

    let testTargetName = "test_removeAudioTrack_whenRemovingCurrentlyPlayingAudio()"
    private var provideState: TestDataProvideState = .givenFixtureData
    private var audioComponent: AudioComponent!

    private var audioFileURL = URL(fileURLWithPath: "Documents/SimpleArchiveMusics/f audio.mp3")
    private let audioDuration: TimeInterval = 134.4
    private var audioSampleData = AudioSampleData(
        sampleDataCount: 8,
        scaledSampleData: [-0.1341, -0.221, 0.473, -0.324, -0.4323, 0.2332, -0.587, 0.537],
        sampleRate: 44100.0
    )
    private var audioMetadata = AudioTrackMetadata(title: "f audio", artist: "artist", thumbnail: Data())

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return (audioComponent.id, 3)

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return ExpectedOutputType(3, 3, 3, audioDuration, audioMetadata, audioSampleData, audioFileURL)

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

        return (testPage, audioComponent.id, audioFileURL, audioSampleData, audioMetadata, audioDuration, true)
    }
}
