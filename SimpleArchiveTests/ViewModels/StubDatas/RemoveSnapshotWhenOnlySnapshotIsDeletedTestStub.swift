import Foundation

@testable import SimpleArchive

final class RemoveSnapshotWhenOnlySnapshotIsDeletedTestStub: StubDatable {
    typealias GivenStubDataType = TextEditorComponent
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = Int

    let testTargetName = "test_removeSnapshot_whenOnlySnapshotIsDeleted()"

    private var provideState: TestDataProvideState = .givenStubData
    private var testTextEditorComponent: TextEditorComponent!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

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

    private func provideGivenStub() -> GivenStubDataType {
        testTextEditorComponent = TextEditorComponent(
            title: "singleSnapshotStub",
            detail: "This is a single snapshot.",
            componentSnapshots: [
                TextEditorComponentSnapshot(
                    detail: "Only Snapshot",
                    description: "Single Snapshot Description",
                    saveMode: .manual)
            ]
        )
        return testTextEditorComponent
    }
}
