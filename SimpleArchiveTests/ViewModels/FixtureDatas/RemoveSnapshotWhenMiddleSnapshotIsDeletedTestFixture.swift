import Foundation

@testable import SimpleArchive

final class RemoveSnapshotWhenMiddleSnapshotIsDeletedTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (TextEditorComponent, UUID)
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = (Int, SnapshotMetaData)

    let testTargetName = "test_removeSnapshot_whenMiddleSnapshotIsDeleted()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var testTextEditorComponent: TextEditorComponent!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return testTextEditorComponent.snapshots[2].snapshotID

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (2, testTextEditorComponent.snapshots[2].getSnapshotMetaData())

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        testTextEditorComponent = TextEditorComponent(
            title: "populatedTextEditorComponentStub",
            detail: "This is a test detail.",
            componentSnapshots: [
                TextEditorComponentSnapshot(
                    detail: "Snapshot 1 detail",
                    description: "First Snapshot",
                    saveMode: .manual),
                TextEditorComponentSnapshot(
                    detail: "Snapshot 2 detail",
                    description: "Second Snapshot",
                    saveMode: .automatic),
                TextEditorComponentSnapshot(
                    detail: "Snapshot 3 detail",
                    description: "Third Snapshot",
                    saveMode: .manual),
                TextEditorComponentSnapshot(
                    detail: "Snapshot 4 detail",
                    description: "fourth Snapshot",
                    saveMode: .manual),
                TextEditorComponentSnapshot(
                    detail: "Snapshot 5 detail",
                    description: "fifth Snapshot",
                    saveMode: .automatic),
            ]
        )
        return (testTextEditorComponent, testTextEditorComponent.snapshots[2].snapshotID)
    }
}
