import Foundation

@testable import SimpleArchive

final class PlayAudioTrackSuccessfulllyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (MemoPageModel, UUID, URL, Double, AudioPCMData, AudioComponentDataSource)
    typealias TestTargetInputType = (UUID, Int)
    typealias ExpectedOutputType = (Int?, Int, Int, TimeInterval?, AudioTrackMetadata, URL, Int)

    let testTargetName = "test_playAudioTrack_successfullly()"
    private var audioComponent: SimpleArchive.AudioComponent!
    private let archiveDirectoryAudioPath = URL(fileURLWithPath: "Documents/SimpleArchiveMusics/e audio.mp3")
    private let audioPCMData = AudioPCMData(
        sampleRate: 44100.0,
        PCMData: (0..<5 * 44_100).map { _ in Float.random(in: -1.0...1.0) }
    )

    private let audioMetadata = AudioTrackMetadata(title: "e audio", artist: "artist", lyrics: "", thumbnail: Data())
    private var provideState: TestDataProvideState = .givenFixtureData

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
                return ExpectedOutputType(
                    nil, 3, 3, 5,
                    audioMetadata,
                    archiveDirectoryAudioPath, 210
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
        let audioComponent = AudioComponent()

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
        self.audioComponent = audioComponent

        let targetComponent = TextEditorComponent()
        testPage.appendChildComponent(component: targetComponent)

        return (
            testPage, audioComponent.id, archiveDirectoryAudioPath, 5.0, audioPCMData,
            audioComponentDataSource
        )
    }
}
