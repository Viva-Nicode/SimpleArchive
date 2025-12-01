import Foundation

@testable import SimpleArchive

final class FetchDormantBoxDirectorySuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = NoUsed
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_fetchDormantBoxDirectory_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData

    func getFixtureData() -> Any {
        switch provideState {

            default:
                return ()
        }
    }
}
