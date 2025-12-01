import Foundation

@testable import SimpleArchive

final class CaptureComponentSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoPageModel
    typealias TestTargetInputType = (UUID, String)
    typealias ExpectedOutputType = Int

    let testTargetName = "test_captureComponent_successfully()"
    private var componentID: UUID!

    private var provideState: TestDataProvideState = .givenFixtureData

    func getFixtureData() -> Any {
        switch provideState {
            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return (componentID, "test snapshot description")

            case .testVerifyOutput:
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
        componentID = targetComponent.id
        testPage.appendChildComponent(component: targetComponent)

        return testPage
    }
}
