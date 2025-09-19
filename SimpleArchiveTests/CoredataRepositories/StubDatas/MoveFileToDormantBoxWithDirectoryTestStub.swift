import Foundation

@testable import SimpleArchive

final class MoveFileToDormantBoxWithDirectoryTestStub: StubDatable {
    typealias GivenStubDataType = MemoDirectoryModel
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = (Int, Int)

    let testTargetName = "test_moveFileToDormantBox_withDirectory()"

    private var provideState: TestDataProvideState = .givenStubData
    private var testDirectoryID: UUID!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return testDirectoryID!

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (0, 8)

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        let testDirectory = MemoDirectoryModel(name: "test directory")
        testDirectoryID = testDirectory.id

        let page1 = MemoPageModel(name: "page_1", parentDirectory: testDirectory)

        page1.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))
        page1.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))
        page1.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))

        let page2 = MemoPageModel(name: "page_2", parentDirectory: testDirectory)

        page2.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))
        page2.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))

        let page3 = MemoPageModel(name: "page_3", parentDirectory: testDirectory)
        page3.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))

        let page4 = MemoPageModel(name: "page_4", parentDirectory: testDirectory)
        page4.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))

        let testSubDirectory = MemoDirectoryModel(name: "test sub directory", parentDirectory: testDirectory)

        let page5 = MemoPageModel(name: "page_5", parentDirectory: testSubDirectory)
        page5.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))

        let page6 = MemoPageModel(name: "page_6", parentDirectory: testSubDirectory)
        page6.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))

        let page7 = MemoPageModel(name: "page_7", parentDirectory: testSubDirectory)
        page7.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))

        let page8 = MemoPageModel(name: "page_8", parentDirectory: testSubDirectory)
        page8.appendChildComponent(component: TextEditorComponent(isMinimumHeight: true))

        return testDirectory
    }
}
