import Foundation

@testable import SimpleArchive

final class RemoveComponentSuccessfullyTestFixture: TestFixtureType {

    typealias GivenFixtureDataType = MemoPageModel
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = Int

    let testTargetName = "test_removeComponent_successfullly()"
    private var targetComponentID: UUID!

    private var provideState: TestDataProvideState = .givenFixtureData

    func getFixtureData() -> Any {
        switch provideState {
            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

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

    private func provideGivenFixture() -> GivenFixtureDataType {
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
