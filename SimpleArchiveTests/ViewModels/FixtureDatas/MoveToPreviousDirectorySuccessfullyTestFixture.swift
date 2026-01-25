import Foundation

@testable import SimpleArchive

final class MoveToPreviousDirectorySuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = [MemoDirectoryModel]
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = ([Int], DirectoryContentsSortCriterias, Int)

    let testTargetName = "test_moveToPreviousDirectory_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var willMoveDirectoryID: UUID!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return willMoveDirectoryID!

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return ([2, 3], DirectoryContentsSortCriterias.creationDate, 1)

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testDirectory_1 = MemoDirectoryModel(name: "testDirectory_1")
        let testDirectory_2 = MemoDirectoryModel(
            name: "testDirectory_2",
            sortBy: .creationDate,
            parentDirectory: testDirectory_1)
        let testDirectory_3 = MemoDirectoryModel(
            name: "testDirectory_3",
            parentDirectory: testDirectory_2)
        let testDirectory_4 = MemoDirectoryModel(
            name: "testDirectory_3",
            parentDirectory: testDirectory_3)

        willMoveDirectoryID = testDirectory_2.id
        return [testDirectory_1, testDirectory_2, testDirectory_3, testDirectory_4]
    }
}
