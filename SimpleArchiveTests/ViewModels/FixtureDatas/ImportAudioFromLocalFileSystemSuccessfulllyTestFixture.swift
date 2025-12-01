import Foundation

@testable import SimpleArchive

final class ImportAudioFromLocalFileSystemSuccessfulllyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoPageModel
    typealias TestTargetInputType = (UUID, [URL])
    typealias ExpectedOutputType = (Int, [Int])

    let testTargetName = "test_importAudioFromLocalFileSystem_successfullly()"
    private var audioComponentID: UUID!

    private var provideState: TestDataProvideState = .givenFixtureData

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return (
                    audioComponentID,
                    [
                        URL(fileURLWithPath: "Downloads/c audio.mp3"),
                        URL(fileURLWithPath: "Downloads/f audio.mp3"),
                        URL(fileURLWithPath: "Downloads/g audio.mp3"),
                    ]
                )

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (3, [2, 5, 6])

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

        testPage.appendChildComponent(component: audioComponent)
        audioComponentID = audioComponent.id

        let targetComponent = TextEditorComponent()
        testPage.appendChildComponent(component: targetComponent)

        return testPage
    }
}
