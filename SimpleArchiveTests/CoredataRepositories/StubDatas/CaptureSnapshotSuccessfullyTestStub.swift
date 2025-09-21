import Foundation

@testable import SimpleArchive

final class CaptureSnapshotSuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = MemoDirectoryModel
    typealias TestTargetInputType = (TextEditorComponent, String)
    typealias ExpectedOutputType = (Int, String, String)

    let testTargetName = "test_captureSnapshot_successfully()"

    private var provideState: TestDataProvideState = .givenStubData

    private var testTextEditorComponent: TextEditorComponent!
    private var snapshotDescription: String!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                snapshotDescription = "fourth Desc"
                testTextEditorComponent.detail = "fourth Detail"
                return (testTextEditorComponent, snapshotDescription)

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (4, testTextEditorComponent.detail, snapshotDescription)

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        let testDirectory = MemoDirectoryModel(name: "Test Directory")
        let testPage = MemoPageModel(name: "Test Page", parentDirectory: testDirectory)
        testTextEditorComponent = TextEditorComponent()

        testTextEditorComponent.detail = "first Detail"
        testTextEditorComponent.makeSnapshot(desc: "first Desc", saveMode: .automatic)
        testTextEditorComponent.detail = "second Detail"
        testTextEditorComponent.makeSnapshot(desc: "second Desc", saveMode: .automatic)
        testTextEditorComponent.detail = "third Detail"
        testTextEditorComponent.makeSnapshot(desc: "third Desc", saveMode: .automatic)

        testPage.appendChildComponent(component: testTextEditorComponent)

        return testDirectory
    }
}
