import Foundation

@testable import SimpleArchive

final class FetchMemoDataSuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = [SystemDirectories: MemoDirectoryModel]
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = (UUID, SortCriterias, Int)

    let testTargetName = "test_fetchMemoData_successfully()"

    private var provideState: TestDataProvideState = .givenStubData
    private var mainDirectoryID = UUID(uuidString: "502a9fea-d6ea-4103-a25e-4e622a6c2759")!
    private var mainDirectorySortCriteria: SortCriterias = .name

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testVerifyOutput
                return provideGivenStub()

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (mainDirectoryID, mainDirectorySortCriteria, 0)

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
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
