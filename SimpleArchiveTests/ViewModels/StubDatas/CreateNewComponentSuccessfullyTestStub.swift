import Foundation

@testable import SimpleArchive

final class CreateNewComponentSuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = (MemoPageModel, TextEditorComponent)
    typealias TestTargetInputType = ComponentType
    typealias ExpectedOutputType = Int

    let testTargetName = "test_createNewComponent_successfully()"

    private var provideState: TestDataProvideState = .givenStubData

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return ComponentType.text

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return 2

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        let testPage = MemoPageModel(name: "test page")
        testPage.appendChildComponent(component: TextEditorComponent(title: "test component"))
        testPage.appendChildComponent(component: TextEditorComponent(title: "test component_2"))
        return (testPage, TextEditorComponent(title: "test component_3"))
    }
}
