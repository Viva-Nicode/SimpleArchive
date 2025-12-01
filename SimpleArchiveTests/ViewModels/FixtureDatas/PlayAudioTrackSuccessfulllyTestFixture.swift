import Foundation

@testable import SimpleArchive

final class PlayAudioTrackSuccessfulllyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (MemoPageModel, URL, AudioSampleData, AudioTrackMetadata)
    typealias TestTargetInputType = (UUID, Int)
    typealias ExpectedOutputType = (
        Int?, Int, Int, TimeInterval?, AudioTrackMetadata, AudioSampleData?, URL
    )

    let testTargetName = "test_playAudioTrack_successfullly()"
    private var audioComponent: AudioComponent!
    private let archiveDirectoryAudioPath = URL(fileURLWithPath: "Documents/SimpleArchiveMusics/e audio.mp3")
    private let audioSampleData = AudioSampleData(
        sampleDataCount: 8,
        scaledSampleData: [-0.11, -0.21, 0.73, -0.24, -0.23, 0.332, -0.587, 0.57],
        sampleRate: 44100.0
    )
    private let audioMetadata = AudioTrackMetadata(title: "e audio", artist: "artist", thumbnail: Data())

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
                    nil, 3, 3, 134.34,
                    audioMetadata,
                    audioSampleData,
                    archiveDirectoryAudioPath
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

        audioComponent.detail.sortBy = .name
        _ = audioComponent.addAudios(audiotracks: [
            AudioTrack(title: "a audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "b audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "d audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "e audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "h audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
        ])

        let audioComponentDataSource = AudioComponentDataSource(
            tracks: audioComponent.detail.tracks,
            sortBy: audioComponent.detail.sortBy
        )
        audioComponent.datasource = audioComponentDataSource

        testPage.appendChildComponent(component: audioComponent)
        self.audioComponent = audioComponent

        let targetComponent = TextEditorComponent()
        testPage.appendChildComponent(component: targetComponent)

        return (testPage, archiveDirectoryAudioPath, audioSampleData, audioMetadata)
    }
}
