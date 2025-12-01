import Foundation

@testable import SimpleArchive

final class CreatedNewPageSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = ([MemoDirectoryModel], MemoPageModel)
    typealias TestTargetInputType = String
    typealias ExpectedOutputType = (Int, [Int])

    let testTargetName = "test_createdNewPage_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var createdNewPageName = "test_page_4"

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return createdNewPageName

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (2, [5])

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testDirectory = MemoDirectoryModel(name: "test_directory")
        let testDirectory_2 = MemoDirectoryModel(name: "test_directory_2", parentDirectory: testDirectory)
        let testDirectory_3 = MemoDirectoryModel(name: "test_directory_3", parentDirectory: testDirectory_2)

        _ = MemoPageModel(name: "test_page_2", parentDirectory: testDirectory_3)
        _ = MemoPageModel(name: "test_page_3", parentDirectory: testDirectory_3)
        _ = MemoPageModel(name: "test_page_5", parentDirectory: testDirectory_3)
        _ = MemoDirectoryModel(name: "test_directory_5", parentDirectory: testDirectory_3)
        _ = MemoDirectoryModel(name: "test_directory_6", parentDirectory: testDirectory_3)
        _ = MemoDirectoryModel(name: "test_directory_7", parentDirectory: testDirectory_3)

        return (
            [testDirectory, testDirectory_2, testDirectory_3],
            MemoPageModel(name: createdNewPageName, parentDirectory: testDirectory_3)
        )
    }
}
