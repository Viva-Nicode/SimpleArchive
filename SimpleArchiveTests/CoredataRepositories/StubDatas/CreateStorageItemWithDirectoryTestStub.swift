import Combine
import Foundation

@testable import SimpleArchive

final class CreateStorageItemWithDirectoryTestStub: StubDatable {
    typealias GivenStubDataType = MemoDirectoryModel
    typealias TestTargetInputType = MemoDirectoryModel
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_createStorageItem_withDirectory()"

    private var provideState: TestDataProvideState = .givenStubData
    private var testParentDirectory: MemoDirectoryModel!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .allDataConsumed
                return provideTargetInput()

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        testParentDirectory = MemoDirectoryModel(name: "test parent directory")
        return testParentDirectory
    }

    private func provideTargetInput() -> TestTargetInputType {
        MemoDirectoryModel(name: "test directory", parentDirectory: testParentDirectory)
    }
}
