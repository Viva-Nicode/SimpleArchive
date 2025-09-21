import Foundation

@testable import SimpleArchive

final class SaveComponentDetailSuccessfullyTestStub: StubDatable {

    typealias GivenStubDataType = MemoDirectoryModel
    typealias TestTargetInputType = [TextEditorComponent]
    typealias ExpectedOutputType = [(PersistentState, Int, String)]

    let testTargetName = "test_saveComponentDetail_successfully()"
    private var provideState: TestDataProvideState = .givenStubData

    private var testDirectory: MemoDirectoryModel!
    private var testTextEditorComponent_1: TextEditorComponent!
    private var testTextEditorComponent_2: TextEditorComponent!
    private var testTextEditorComponent_3: TextEditorComponent!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                [testTextEditorComponent_1, testTextEditorComponent_2, testTextEditorComponent_3]
                    .forEach {
                        $0.detail = "\($0.id) updated Detail"
                    }

                return [testTextEditorComponent_1, testTextEditorComponent_2, testTextEditorComponent_3]

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return [
                    (PersistentState.synced, 4, "\(testTextEditorComponent_1.id) updated Detail"),
                    (PersistentState.synced, 4, "\(testTextEditorComponent_2.id) updated Detail"),
                    (PersistentState.synced, 4, "\(testTextEditorComponent_3.id) updated Detail"),
                ]

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        testDirectory = MemoDirectoryModel(name: "Test Directory")
        let testPage = MemoPageModel(name: "Test Page", parentDirectory: testDirectory)

        testTextEditorComponent_1 = TextEditorComponent()

        testTextEditorComponent_1.detail = "t1 first Detail"
        testTextEditorComponent_1.makeSnapshot(desc: "t1 first Desc", saveMode: .automatic)
        testTextEditorComponent_1.detail = "t1 second Detail"
        testTextEditorComponent_1.makeSnapshot(desc: "t1 second Desc", saveMode: .automatic)
        testTextEditorComponent_1.detail = "t1 third Detail"
        testTextEditorComponent_1.makeSnapshot(desc: "t1 third Desc", saveMode: .automatic)

        testTextEditorComponent_2 = TextEditorComponent()

        testTextEditorComponent_2.detail = "t2 first Detail"
        testTextEditorComponent_2.makeSnapshot(desc: "t2 first Desc", saveMode: .automatic)
        testTextEditorComponent_2.detail = "t2 second Detail"
        testTextEditorComponent_2.makeSnapshot(desc: "t2 second Desc", saveMode: .automatic)
        testTextEditorComponent_2.detail = "t2 third Detail"
        testTextEditorComponent_2.makeSnapshot(desc: "t2 third Desc", saveMode: .automatic)

        testTextEditorComponent_3 = TextEditorComponent()

        testTextEditorComponent_3.detail = "t3 first Detail"
        testTextEditorComponent_3.makeSnapshot(desc: "t3 first Desc", saveMode: .automatic)
        testTextEditorComponent_3.detail = "t3 second Detail"
        testTextEditorComponent_3.makeSnapshot(desc: "t3 second Desc", saveMode: .automatic)
        testTextEditorComponent_3.detail = "t3 third Detail"
        testTextEditorComponent_3.makeSnapshot(desc: "t3 third Desc", saveMode: .automatic)

        testPage.appendChildComponent(component: testTextEditorComponent_1)
        testPage.appendChildComponent(component: testTextEditorComponent_2)
        testPage.appendChildComponent(component: testTextEditorComponent_3)

        return testDirectory
    }
}
