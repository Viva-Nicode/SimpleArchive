import Foundation

@testable import SimpleArchive

final class UnfixPageSuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = ([MemoDirectoryModel], MemoDirectoryModel)
    typealias TestTargetInputType = [UUID]
    typealias ExpectedOutputType = (Int, [IndexPath], [IndexPath])

    let testTargetName = "test_unfixPage_successfully()"

    private var provideState: TestDataProvideState = .givenStubData
    private var unfixedPageID: UUID!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return [unfixedPageID]

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (2, [IndexPath(row: 0, section: 3)], [IndexPath(row: 2, section: 0)])

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        let testDirectory_1 = MemoDirectoryModel(name: "test directory")
        let testDirectory_2 = MemoDirectoryModel(name: "test directory_2", parentDirectory: testDirectory_1)
        let testDirectory_3 = MemoDirectoryModel(name: "test directory_3", parentDirectory: testDirectory_2)

        _ = MemoPageModel(name: "test page_1", parentDirectory: testDirectory_3)
        _ = MemoPageModel(name: "test page_2", parentDirectory: testDirectory_3)
        _ = MemoPageModel(name: "test page_3", parentDirectory: testDirectory_3)
        _ = MemoPageModel(name: "test page_8", parentDirectory: testDirectory_3)

        let fixedDirectory = MemoDirectoryModel(name: "fixedDirectory")

        _ = MemoPageModel(name: "test page_4", parentDirectory: fixedDirectory)
        _ = MemoPageModel(name: "test page_5", parentDirectory: fixedDirectory)
        unfixedPageID = MemoPageModel(name: "test page_6", parentDirectory: fixedDirectory).id
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
