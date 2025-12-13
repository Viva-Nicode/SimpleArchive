import Foundation

@testable import SimpleArchive

final class RemoveSnapshotWhenLastSnapshotIsDeletedTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (TextEditorComponent, UUID)
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = (Int, SnapshotMetaData)

    let testTargetName = "test_removeSnapshot_whenLastSnapshotIsDeleted()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var testTextEditorComponent: TextEditorComponent!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return testTextEditorComponent.snapshots.last!.snapshotID

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (4, testTextEditorComponent.snapshots[3].getSnapshotMetaData())

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        testTextEditorComponent = TextEditorComponent(
            title: "populatedTextEditorComponentStub",
            contents: "test contents.",
            componentSnapshots: [
                TextEditorComponentSnapshot(
                    contents: "Snapshot 1 contents",
                    description: "First Snapshot",
                    saveMode: .manual),
                TextEditorComponentSnapshot(
                    contents: "Snapshot 2 contents",
                    description: "",
                    saveMode: .automatic),
                TextEditorComponentSnapshot(
                    contents: "Snapshot 3 contents",
                    description: "Third Snapshot",
                    saveMode: .manual),
                TextEditorComponentSnapshot(
                    contents: "Snapshot 4 contents",
                    description: "fourth Snapshot",
                    saveMode: .manual),
                TextEditorComponentSnapshot(
                    contents: "Snapshot 5 contents",
                    description: "",
                    saveMode: .automatic),
            ]
        )
        return (testTextEditorComponent, testTextEditorComponent.snapshots.last!.snapshotID)
    }
}
