import Foundation

@testable import SimpleArchive

final class CreateStorageItemWithPageTestStub: StubDatable {
    typealias GivenStubDataType = MemoDirectoryModel
    typealias TestTargetInputType = MemoPageModel
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_createStorageItem_withPage()"

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
        MemoPageModel(name: "test page", parentDirectory: testParentDirectory)
    }
}
