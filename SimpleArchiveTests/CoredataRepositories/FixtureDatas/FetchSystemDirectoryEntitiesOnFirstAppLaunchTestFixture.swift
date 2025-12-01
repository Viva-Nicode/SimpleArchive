import Foundation

@testable import SimpleArchive

final class FetchSystemDirectoryEntitiesOnFirstAppLaunchTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = any FileCreatorType
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_fetchSystemDirectoryEntities_onFirstAppLaunch()"

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
