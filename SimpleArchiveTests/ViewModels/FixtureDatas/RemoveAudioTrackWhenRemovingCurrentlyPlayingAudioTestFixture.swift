import Foundation

@testable import SimpleArchive

final class RemoveAudioTrackWhenRemovingCurrentlyPlayingAudioTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (
        MemoPageModel, UUID, AudioComponentDataSource, URL, AudioPCMData, TimeInterval, Bool
    )
    typealias TestTargetInputType = (UUID, Int)
    typealias ExpectedOutputType = (Int, Int, Int, TimeInterval, AudioTrackMetadata, URL,Int)

    let testTargetName = "test_removeAudioTrack_whenRemovingCurrentlyPlayingAudio()"
    private var provideState: TestDataProvideState = .givenFixtureData
    private var audioComponent: AudioComponent!

    private var audioFileURL = URL(fileURLWithPath: "Documents/SimpleArchiveMusics/f audio.mp3")
    private let audioDuration: TimeInterval = 5.0
    private let audioPCMData = AudioPCMData(
        sampleRate: 44100.0,
        PCMData: (0..<5 * 44_100).map { _ in Float.random(in: -1.0...1.0) }
    )
    
    private var audioMetadata = AudioTrackMetadata(
        title: "f audio", artist: "artist", lyrics: "", thumbnail: Data()
    )

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
                return ExpectedOutputType(3, 3, 3, audioDuration, audioMetadata, audioFileURL, 210)

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
            AudioTrack(title: "a audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "b audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "d audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "e audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "f audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "g audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "k audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
            AudioTrack(title: "m audio", artist: "artist", thumbnail: Data(), lyrics: "", fileExtension: .mp3),
        ])

        let audioComponentDataSource = AudioComponentDataSource(
            tracks: audioComponent.componentContents.tracks,
            sortBy: audioComponent.componentContents.sortBy
        )

        audioComponentDataSource.nowPlayingAudioIndex = 3
        audioComponentDataSource.isPlaying = true
        audioComponentDataSource.nowPlayingURL = URL(fileURLWithPath: "Documents/SimpleArchiveMusics/e audio.mp3")
        audioComponentDataSource.audioVisualizerData = AudioWaveformData(
            sampleDataCount: 5 * 44_100,
            sampleRate: 44100.0,
            waveformData: (0..<5 * 6).map { _ in (0..<7).map { _ in Float.random(in: 0...1.0) } }
        )
        audioComponentDataSource.getProgress = { .zero }

        testPage.appendChildComponent(component: audioComponent)
        self.audioComponent = audioComponent

        return (
            testPage, audioComponent.id, audioComponentDataSource, audioFileURL, audioPCMData,
            audioDuration, true
        )
    }
}
