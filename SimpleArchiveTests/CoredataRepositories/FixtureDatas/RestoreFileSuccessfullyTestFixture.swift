import Foundation

@testable import SimpleArchive

final class RestoreFileSuccessfullyTestFixture: TestFixtureType {
    
    typealias GivenFixtureDataType = MemoPageModel
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_restoreFile_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var testPage: MemoPageModel!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        testPage = MemoPageModel(name: "test page")

        testPage.appendChildComponent(component: TextEditorComponent())
        testPage.appendChildComponent(component: TextEditorComponent())
        testPage.appendChildComponent(component: TextEditorComponent())

        return testPage
    }
}
