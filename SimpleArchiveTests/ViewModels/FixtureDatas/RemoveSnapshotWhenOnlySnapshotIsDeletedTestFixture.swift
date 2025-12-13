import Foundation

@testable import SimpleArchive

final class RemoveSnapshotWhenOnlySnapshotIsDeletedTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = TextEditorComponent
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = Int

    let testTargetName = "test_removeSnapshot_whenOnlySnapshotIsDeleted()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var testTextEditorComponent: TextEditorComponent!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return testTextEditorComponent.snapshots.first!.snapshotID

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return 0

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        testTextEditorComponent = TextEditorComponent(
            title: "singleSnapshotStub",
            contents: "single snapshot.",
            componentSnapshots: [
                TextEditorComponentSnapshot(
                    contents: "Only Snapshot",
                    description: "Single Snapshot Description",
                    saveMode: .manual)
            ]
        )
        return testTextEditorComponent
    }
}
