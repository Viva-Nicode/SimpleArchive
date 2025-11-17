import Foundation

@testable import SimpleArchive

final class DownloadAudioTracksSuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = (MemoPageModel, [AudioTrack])
    typealias TestTargetInputType = (UUID, String)
    typealias ExpectedOutputType = (Int, [Int])

    let testTargetName = "test_downloadAudioTracks_successfullly()"
    private var audioComponentID: UUID!

    private var provideState: TestDataProvideState = .givenStubData

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return (audioComponentID, "testDownloadCode")

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (3, [2, 5, 6])

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
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

        testPage.appendChildComponent(component: audioComponent)
        audioComponentID = audioComponent.id

        let targetComponent = TextEditorComponent()
        testPage.appendChildComponent(component: targetComponent)

        let audioTrackStub = [
            AudioTrack(title: "c audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "f audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
            AudioTrack(title: "g audio", artist: "artist", thumbnail: Data(), fileExtension: ".mp3"),
        ]

        return (testPage, audioTrackStub)
    }
}
