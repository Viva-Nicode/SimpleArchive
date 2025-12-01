import Foundation

@testable import SimpleArchive

final class MoveFileToDormantBoxWithPageTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_moveFileToDormantBox_withPage()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var testPageId: UUID!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return testPageId!

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
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
