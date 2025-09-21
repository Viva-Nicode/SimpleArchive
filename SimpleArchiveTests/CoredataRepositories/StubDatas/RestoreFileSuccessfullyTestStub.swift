import Foundation

@testable import SimpleArchive

final class RestoreFileSuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = MemoPageModel
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_restoreFile_successfully()"

    private var provideState: TestDataProvideState = .givenStubData
    private var testPage: MemoPageModel!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        testPage = MemoPageModel(name: "test page")

        testPage.appendChildComponent(component: TextEditorComponent())
        testPage.appendChildComponent(component: TextEditorComponent())
        testPage.appendChildComponent(component: TextEditorComponent())

        return testPage

    }
}
