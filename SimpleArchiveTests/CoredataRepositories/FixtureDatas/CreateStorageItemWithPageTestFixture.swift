import Foundation

@testable import SimpleArchive

final class CreateStorageItemWithPageTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = MemoPageModel
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_createStorageItem_withPage()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var testParentDirectory: MemoDirectoryModel!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .allDataConsumed
                return provideTargetInput()

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        testParentDirectory = MemoDirectoryModel(name: "test parent directory")
        return testParentDirectory
    }

    private func provideTargetInput() -> TestTargetInputType {
        MemoPageModel(name: "test page", parentDirectory: testParentDirectory)
    }
}
