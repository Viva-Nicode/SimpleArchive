import Foundation

@testable import SimpleArchive

final class PlayAudioTrackSuccessfulllyWhenTrackIsAlreadyPlayingTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (
        MemoPageModel, UUID, Double, AudioComponentDataSource, UUID, AudioComponentDataSource, URL, AudioPCMData
    )
    typealias TestTargetInputType = (UUID, Int)
    typealias ExpectedOutputType = (
        Int?, Int, Int, TimeInterval?, AudioTrackMetadata, URL, UUID, Int
    )

    private let archiveDirectoryAudioPath = URL(fileURLWithPath: "Documents/SimpleArchiveMusics/e audio.mp3")
    private let audioPCMData = AudioPCMData(
        sampleRate: 44100.0,
        PCMData: (0..<5 * 44_100).map { _ in Float.random(in: -1.0...1.0) })
    private let audioMetadata = AudioTrackMetadata(title: "e audio", artist: "artist", lyrics: "", thumbnail: Data())

    let testTargetName = "test_playAudioTrack_successfullly_whenTrackIsAlreadyPlaying()"
    private var provideState: TestDataProvideState = .givenFixtureData
    private var nextComponentID: UUID!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return TestTargetInputType(nextComponentID, 3)

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return ExpectedOutputType(
                    4, 3, 3, 5.0,
                    audioMetadata,
                    archiveDirectoryAudioPath,
                    nextComponentID,
                    210
                )

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testPage = MemoPageModel(name: "test page")
        testPage.appendChildComponent(component: TextEditorComponent())
        testPage.appendChildComponent(component: TextEditorComponent())
        testPage.appendChildComponent(component: TextEditorComponent())

        let audioComponent = AudioComponent(title: "audio_1")
        nextComponentID = audioComponent.id

        audioComponent.componentContents.sortBy = .name
        _ = audioComponent.addAudios(audiotracks: [
            AudioTrack(title: "a audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "b audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "d audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "e audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "h audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
        ])

        let audioComponentDataSource = AudioComponentDataSource(
            tracks: audioComponent.componentContents.tracks,
            sortBy: audioComponent.componentContents.sortBy
        )

        testPage.appendChildComponent(component: audioComponent)

        let previousPlayingAudioComponent = AudioComponent(title: "audio_2")

        previousPlayingAudioComponent.componentContents.sortBy = .name
        _ = previousPlayingAudioComponent.addAudios(audiotracks: [
            AudioTrack(title: "autumn audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "j audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "o audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "spring audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "summer audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "winter audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "x audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "y audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "z audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
        ])

        let previousPlayingAudioComponentDataSource = AudioComponentDataSource(
            tracks: previousPlayingAudioComponent.componentContents.tracks,
            sortBy: previousPlayingAudioComponent.componentContents.sortBy
        )

        previousPlayingAudioComponentDataSource.isPlaying = true
        previousPlayingAudioComponentDataSource.nowPlayingAudioIndex = 3
        previousPlayingAudioComponentDataSource.nowPlayingURL =
            URL(fileURLWithPath: "Documents/SimpleArchiveMusics/spring audio.mp3")
        previousPlayingAudioComponentDataSource.getProgress = { .zero }
        previousPlayingAudioComponentDataSource.audioVisualizerData =
            AudioWaveformData(
                sampleDataCount: 92 * 44_100,
                sampleRate: 44100.0,
                waveformData: (0..<92 * 6).map { _ in (0..<7).map { _ in Float.random(in: 0...1.0) } }
            )

        testPage.appendChildComponent(component: previousPlayingAudioComponent)

        let targetComponent = TextEditorComponent()
        testPage.appendChildComponent(component: targetComponent)

        return (
            testPage,
            previousPlayingAudioComponent.id,
            5.0,
            previousPlayingAudioComponentDataSource,
            audioComponent.id,
            audioComponentDataSource,
            archiveDirectoryAudioPath,
            audioPCMData,
        )
    }
}
