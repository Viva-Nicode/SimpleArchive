import Foundation

@testable import SimpleArchive

final class RemoveComponentSuccessfullyTestStub: StubDatable {

    typealias GivenStubDataType = MemoPageModel
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = Int

    let testTargetName = "test_removeComponent_successfullly()"
    private var targetComponentID: UUID!

    private var provideState: TestDataProvideState = .givenStubData

    func getStubData() -> Any {
        switch provideState {
            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return targetComponentID!

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

        let targetComponent = TextEditorComponent()
        targetComponentID = targetComponent.id
        testPage.appendChildComponent(component: targetComponent)

        return testPage
    }
}
