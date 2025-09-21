import Foundation

@testable import SimpleArchive

final class FetchSystemDirectoryEntitiesSuccessfullyTestStub: StubDatable {
    typealias GivenStubDataType = any FileCreatorType
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_fetchSystemDirectoryEntities_successfully()"

    private var provideState: TestDataProvideState = .givenStubData

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return DirectoryCreator()

            default:
                return ()
        }
    }
}
