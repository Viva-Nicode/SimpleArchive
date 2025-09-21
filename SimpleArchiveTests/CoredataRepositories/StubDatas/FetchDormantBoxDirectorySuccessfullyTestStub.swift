import Foundation

@testable import SimpleArchive

final class FetchDormantBoxDirectorySuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = NoUsed
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_fetchDormantBoxDirectory_successfully()"

    private var provideState: TestDataProvideState = .givenStubData

    func getStubData() -> Any {
        switch provideState {

            default:
                return ()
        }
    }
}
