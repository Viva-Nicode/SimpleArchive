import Foundation

@testable import SimpleArchive

final class FixPagesSuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = MemoDirectoryModel
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_fixPages_successfully()"

    private var provideState: TestDataProvideState = .givenStubData
    private var testPageId: UUID!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return testPageId!

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        let testDirectory = MemoDirectoryModel(name: "test directory")
        let testSubDirectory = MemoDirectoryModel(name: "test sub directory", parentDirectory: testDirectory)

        _ = MemoPageModel(name: "test page_1", parentDirectory: testSubDirectory)
        _ = MemoPageModel(name: "test page_2", parentDirectory: testSubDirectory)
        testPageId = MemoPageModel(name: "test page_3", parentDirectory: testSubDirectory).id

        return testDirectory
    }
}
