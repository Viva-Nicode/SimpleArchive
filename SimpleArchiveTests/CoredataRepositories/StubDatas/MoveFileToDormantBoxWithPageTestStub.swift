import Foundation

@testable import SimpleArchive

final class MoveFileToDormantBoxWithPageTestStub: StubDatable {
    typealias GivenStubDataType = MemoDirectoryModel
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_moveFileToDormantBox_withPage()"

    private var provideState: TestDataProvideState = .givenStubData
    private var testPageId: UUID!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return testPageId!

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        let testDirectory = MemoDirectoryModel(name: "test directory")

        _ = MemoPageModel(name: "page_1", parentDirectory: testDirectory)
        _ = MemoPageModel(name: "page_2", parentDirectory: testDirectory)

        let page = MemoPageModel(name: "page_3", parentDirectory: testDirectory)

        page.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))
        page.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))
        page.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))

        testPageId = page.id

        return testDirectory
    }
}
