import Combine
import Foundation

@testable import SimpleArchive

final class CreateStorageItemWithDirectoryTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = MemoDirectoryModel
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_createStorageItem_withDirectory()"

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
        MemoDirectoryModel(name: "test directory", parentDirectory: testParentDirectory)
    }
}
