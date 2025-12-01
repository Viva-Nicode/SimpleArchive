import Foundation

@testable import SimpleArchive

final class CreateComponentSuccessfullyTestFixture: TestFixtureType {

    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = (UUID, TextEditorComponent)
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_createComponent_successfully()"
    private var provideState: TestDataProvideState = .givenFixtureData

    private var parentPage: MemoPageModel!

    func getFixtureData() -> Any {
        switch provideState {
            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return provideTestTargetInput()

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
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
