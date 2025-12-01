import Foundation

@testable import SimpleArchive

final class FetchSystemDirectoryEntitiesSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = any FileCreatorType
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_fetchSystemDirectoryEntities_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return DirectoryCreator()

            default:
                return ()
        }
    }
}
