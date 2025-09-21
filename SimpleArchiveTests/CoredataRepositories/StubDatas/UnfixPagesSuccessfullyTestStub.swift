import Foundation

@testable import SimpleArchive

final class UnfixPagesSuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = (MemoDirectoryModel, MemoPageModel)
    typealias TestTargetInputType = (UUID, UUID)
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_unfixPages_successfully()"

    private var provideState: TestDataProvideState = .givenStubData
    private var testPageId: UUID!
    private var testDirectoryID: UUID!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return (testDirectoryID!, testPageId!)

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        let testPage = MemoPageModel(name: "test Page")
        testPageId = testPage.id

        testPage.appendChildComponent(component: TextEditorComponent(title: "test compoenet_1"))
        testPage.appendChildComponent(component: TextEditorComponent(title: "test compoenet_2"))
        testPage.appendChildComponent(component: TextEditorComponent(title: "test compoenet_3"))

        let testDirectory = MemoDirectoryModel(name: "test directory")
        testDirectoryID = testDirectory.id

        return (testDirectory, testPage)
    }
}
