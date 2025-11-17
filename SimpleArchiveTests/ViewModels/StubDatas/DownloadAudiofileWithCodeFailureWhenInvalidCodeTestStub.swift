import Foundation

@testable import SimpleArchive

final class DownloadAudiofileWithCodeFailureWhenInvalidCodeTestStub: StubDatable {
    typealias GivenStubDataType = MemoPageModel
    typealias TestTargetInputType = (UUID, String)
    typealias ExpectedOutputType = Int

    let testTargetName = "test_downloadAudiofileWithCode_failure_WhenInvalidCode()"
    private var audioComponentID: UUID!

    private var provideState: TestDataProvideState = .givenStubData

    func getStubData() -> Any {
        switch provideState {
            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

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

    private func provideGivenStub() -> GivenStubDataType {
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
