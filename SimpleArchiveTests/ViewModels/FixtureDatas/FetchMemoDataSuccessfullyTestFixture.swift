import Foundation

@testable import SimpleArchive

final class FetchMemoDataSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = [SystemDirectories: MemoDirectoryModel]
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = (UUID, DirectoryContentsSortCriterias, Int)

    let testTargetName = "test_fetchMemoData_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var mainDirectoryID = UUID(uuidString: "502a9fea-d6ea-4103-a25e-4e622a6c2759")!
    private var mainDirectorySortCriteria: DirectoryContentsSortCriterias = .name

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testVerifyOutput
                return provideGivenFixture()

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (mainDirectoryID, mainDirectorySortCriteria, 0)

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let mainDirectory = MemoDirectoryModel(
            id: mainDirectoryID,
            name: "mainDirectory",
            sortBy: mainDirectorySortCriteria)

        return [
            .mainDirectory: mainDirectory,
            .fixedFileDirectory: MemoDirectoryModel(name: "fixedDirectory"),
        ]
    }
}
