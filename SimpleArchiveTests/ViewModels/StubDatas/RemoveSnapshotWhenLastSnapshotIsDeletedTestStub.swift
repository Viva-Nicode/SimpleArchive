import Foundation

@testable import SimpleArchive

final class RemoveSnapshotWhenLastSnapshotIsDeletedTestStub: StubDatable {
    typealias GivenStubDataType = (TextEditorComponent, UUID)
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = (Int, SnapshotMetaData)

    let testTargetName = "test_removeSnapshot_whenLastSnapshotIsDeleted()"

    private var provideState: TestDataProvideState = .givenStubData
    private var testTextEditorComponent: TextEditorComponent!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

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

    private func provideGivenStub() -> GivenStubDataType {
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
        return (testTextEditorComponent, testTextEditorComponent.snapshots.last!.snapshotID)
    }
}
