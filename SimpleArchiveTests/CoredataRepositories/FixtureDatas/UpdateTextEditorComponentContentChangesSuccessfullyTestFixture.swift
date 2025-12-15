import Foundation

@testable import SimpleArchive

final class UpdateTextEditorComponentContentChangesSuccessfullyTestFixture: TestFixtureType {

    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = TextEditorComponent
    typealias ExpectedOutputType = String

    let testTargetName = "test_updateTextEditorComponentContentChanges_successfully()"
    private var provideState: TestDataProvideState = .givenFixtureData

    private var testDirectory: MemoDirectoryModel!
    private var textEditorComponent: TextEditorComponent!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                textEditorComponent.componentContents = "textEditorComponent contents has Changes"
                textEditorComponent.setCaptureState(to: .needsCapture)
                return textEditorComponent!

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return "textEditorComponent contents has Changes"

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        testDirectory = MemoDirectoryModel(name: "Test Directory")
        let testPage = MemoPageModel(name: "Test Page", parentDirectory: testDirectory)

        textEditorComponent = TextEditorComponent()
        textEditorComponent.componentContents = "textEditorComponent Contents"
        testPage.appendChildComponent(component: textEditorComponent)

        return testDirectory
    }
}
