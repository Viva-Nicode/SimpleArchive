import Foundation

@testable import SimpleArchive

final class CaptureSnapshotWithManualSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = (TextEditorComponent, String)
    typealias ExpectedOutputType = (UUID, Int, String, String)

    let testTargetName = "test_captureSnapshot_withManual_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var testTextEditorComponent: TextEditorComponent!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return (testTextEditorComponent, "fourth Desc")

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (testTextEditorComponent.id, 4, "textEditorComponentContents has Changes", "fourth Desc")

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testDirectory = MemoDirectoryModel(name: "Test Directory")
        let testPage = MemoPageModel(name: "Test Page", parentDirectory: testDirectory)

        testTextEditorComponent = TextEditorComponent(
            contents: "textEditorComponentContents has Changes",
            captureState: .needsCapture,
            componentSnapshots: [
                .init(contents: "first contents", description: "first Desc", saveMode: .manual),
                .init(contents: "second contents", description: "second Desc", saveMode: .manual),
                .init(contents: "third contents", description: "third Desc", saveMode: .manual),
            ]
        )

        testPage.appendChildComponent(component: testTextEditorComponent)

        return testDirectory
    }
}
