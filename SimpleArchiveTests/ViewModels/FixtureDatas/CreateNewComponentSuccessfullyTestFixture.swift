import Foundation

@testable import SimpleArchive

final class CreateNewComponentSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (MemoPageModel, TextEditorComponent)
    typealias TestTargetInputType = ComponentType
    typealias ExpectedOutputType = Int

    let testTargetName = "test_createNewComponent_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

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

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testPage = MemoPageModel(name: "test page")
        testPage.appendChildComponent(component: TextEditorComponent(title: "test component"))
        testPage.appendChildComponent(component: TextEditorComponent(title: "test component_2"))
        return (testPage, TextEditorComponent(title: "test component_3"))
    }
}
