import Foundation

@testable import SimpleArchive

final class FixPageSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = ([MemoDirectoryModel], MemoDirectoryModel)
    typealias TestTargetInputType = [UUID]
    typealias ExpectedOutputType = (Int, [IndexPath], [IndexPath])

    let testTargetName = "test_fixPage_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var testPage: UUID!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return [testPage]

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (2, [IndexPath(row: 3, section: 0)], [IndexPath(row: 0, section: 2)])

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testDirectory_1 = MemoDirectoryModel(name: "test directory")
        let testDirectory_2 = MemoDirectoryModel(name: "test directory_2", parentDirectory: testDirectory_1)
        let testDirectory_3 = MemoDirectoryModel(name: "test directory_3", parentDirectory: testDirectory_2)

        _ = MemoPageModel(name: "test page_1", parentDirectory: testDirectory_3)
        _ = MemoPageModel(name: "test page_2", parentDirectory: testDirectory_3)
        testPage = MemoPageModel(name: "test page_6", parentDirectory: testDirectory_3).id

        let fixedDirectory = MemoDirectoryModel(name: "fixedDirectory")

        _ = MemoPageModel(name: "test page_3", parentDirectory: fixedDirectory)
        _ = MemoPageModel(name: "test page_4", parentDirectory: fixedDirectory)
        _ = MemoPageModel(name: "test page_5", parentDirectory: fixedDirectory)
        _ = MemoPageModel(name: "test page_7", parentDirectory: fixedDirectory)

        return (
            [
                testDirectory_1,
                testDirectory_2,
                testDirectory_3,
            ],
            fixedDirectory
        )
    }
}
