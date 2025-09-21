import Foundation

@testable import SimpleArchive

final class CreateComponentSuccessfullyTestStub: StubDatable {

    typealias GivenStubDataType = MemoDirectoryModel
    typealias TestTargetInputType = (UUID, TextEditorComponent)
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_createComponent_successfully()"
    private var provideState: TestDataProvideState = .givenStubData

    private var parentPage: MemoPageModel!

    func getStubData() -> Any {
        switch provideState {
            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return provideTestTargetInput()

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        let testDirectory = MemoDirectoryModel(name: "Test Directory")
        parentPage = MemoPageModel(name: "Test Page", parentDirectory: testDirectory)
        return testDirectory
    }

    private func provideTestTargetInput() -> TestTargetInputType {
        let emptyTextEditorComponent = TextEditorComponent()
        parentPage.appendChildComponent(component: emptyTextEditorComponent)
        return (parentPage.id, emptyTextEditorComponent)
    }
}
