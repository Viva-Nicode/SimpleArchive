import Foundation

@testable import SimpleArchive

final class CreatedNewDirectorySuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = ([MemoDirectoryModel], MemoDirectoryModel)
    typealias TestTargetInputType = String
    typealias ExpectedOutputType = (Int, [Int])

    let testTargetName = "test_createdNewDirectory_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var createdNewDirectoryName = "test directory_8"

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return createdNewDirectoryName

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (2, [3])

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testDirectory = MemoDirectoryModel(name: "test directory")
        let testDirectory_2 = MemoDirectoryModel(name: "test directory_2", parentDirectory: testDirectory)
        let testDirectory_3 = MemoDirectoryModel(name: "test directory_3", parentDirectory: testDirectory_2)

        _ = MemoPageModel(name: "test_Page_1", parentDirectory: testDirectory_3)
        _ = MemoPageModel(name: "test_Page_2", parentDirectory: testDirectory_3)
        _ = MemoPageModel(name: "test_Page_3", parentDirectory: testDirectory_3)
        _ = MemoDirectoryModel(name: "test directory_5", parentDirectory: testDirectory_3)
        _ = MemoDirectoryModel(name: "test directory_6", parentDirectory: testDirectory_3)
        _ = MemoDirectoryModel(name: "test directory_7", parentDirectory: testDirectory_3)

        return (
            [testDirectory, testDirectory_2, testDirectory_3],
            MemoDirectoryModel(
                name: createdNewDirectoryName,
                parentDirectory: testDirectory_3)
        )
    }
}
