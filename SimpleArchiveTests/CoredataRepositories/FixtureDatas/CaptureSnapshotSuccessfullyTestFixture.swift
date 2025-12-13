import Foundation

@testable import SimpleArchive

final class CaptureSnapshotSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = (TextEditorComponent, String)
    typealias ExpectedOutputType = (Int, String, String)

    let testTargetName = "test_captureSnapshot_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData

    private var testTextEditorComponent: TextEditorComponent!
    private var snapshotDescription: String!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                snapshotDescription = "fourth Desc"
                testTextEditorComponent.componentContents = "fourth contents"
                return (testTextEditorComponent, snapshotDescription)

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (4, "fourth contents", "fourth Desc")

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testDirectory = MemoDirectoryModel(name: "Test Directory")
        let testPage = MemoPageModel(name: "Test Page", parentDirectory: testDirectory)
        testTextEditorComponent = TextEditorComponent()

        testTextEditorComponent.componentContents = "first contents"
        testTextEditorComponent.makeSnapshot(desc: "first Desc", saveMode: .manual)
        testTextEditorComponent.componentContents = "second contents"
        testTextEditorComponent.makeSnapshot(desc: "second Desc", saveMode: .manual)
        testTextEditorComponent.componentContents = "third contents"
        testTextEditorComponent.makeSnapshot(desc: "third Desc", saveMode: .manual)
        

        testPage.appendChildComponent(component: testTextEditorComponent)

        return testDirectory
    }
}
