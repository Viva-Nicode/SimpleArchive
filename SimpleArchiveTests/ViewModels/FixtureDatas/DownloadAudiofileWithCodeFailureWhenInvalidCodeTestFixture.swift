import Foundation

@testable import SimpleArchive

final class DownloadAudiofileWithCodeFailureWhenInvalidCodeTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoPageModel
    typealias TestTargetInputType = (UUID, String)
    typealias ExpectedOutputType = Int

    let testTargetName = "test_downloadAudiofileWithCode_failure_WhenInvalidCode()"
    private var audioComponentID: UUID!

    private var provideState: TestDataProvideState = .givenFixtureData

    func getFixtureData() -> Any {
        switch provideState {
            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return (audioComponentID, "invalidDownloadCode")

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return 3

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
        audioComponentID = audioComponent.id

        testPage.appendChildComponent(component: audioComponent)

        let targetComponent = TextEditorComponent()
        testPage.appendChildComponent(component: targetComponent)

        return testPage
    }
}
