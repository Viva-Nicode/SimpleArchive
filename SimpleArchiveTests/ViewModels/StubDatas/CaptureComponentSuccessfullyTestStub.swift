import Foundation

@testable import SimpleArchive

final class CaptureComponentSuccessfullyTestStub: StubDatable {

    typealias GivenStubDataType = MemoPageModel
    typealias TestTargetInputType = (UUID, String)
    typealias ExpectedOutputType = Int

    let testTargetName = "test_captureComponent_successfully()"
    private var componentID: UUID!

    private var provideState: TestDataProvideState = .givenStubData

    func getStubData() -> Any {
        switch provideState {
            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return (componentID, "test snapshot description")

            case .testVerifyOutput:
                return 1

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        let testPage = MemoPageModel(name: "test page")
        testPage.appendChildComponent(component: TextEditorComponent(title: "test component"))
        let textComponent = TextEditorComponent(title: "test component_2")
        componentID = textComponent.id
        testPage.appendChildComponent(component: textComponent)

        return testPage
    }
}
