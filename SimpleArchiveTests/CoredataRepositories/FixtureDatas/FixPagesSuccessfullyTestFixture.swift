import Foundation

@testable import SimpleArchive

final class FixPagesSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_fixPages_successfully()"

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
        let testSubDirectory = MemoDirectoryModel(name: "test sub directory", parentDirectory: testDirectory)

        _ = MemoPageModel(name: "test page_1", parentDirectory: testSubDirectory)
        _ = MemoPageModel(name: "test page_2", parentDirectory: testSubDirectory)
        testPageId = MemoPageModel(name: "test page_3", parentDirectory: testSubDirectory).id

        return testDirectory
    }
}
