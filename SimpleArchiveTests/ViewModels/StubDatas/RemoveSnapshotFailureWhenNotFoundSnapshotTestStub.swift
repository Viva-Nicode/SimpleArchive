import Foundation

@testable import SimpleArchive

final class RemoveSnapshotFailureWhenNotFoundSnapshotTestStub: StubDatable {
    typealias GivenStubDataType = (TextEditorComponent, UUID)
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_removeSnapshot_failureWhenNotFoundSnapshot()"

    private var provideState: TestDataProvideState = .givenStubData
    private var notExistSnapshotID: UUID!

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return notExistSnapshotID!

            default:
                return ()
        }
    }

    private func provideGivenStub() -> GivenStubDataType {
        let testTextEditorComponent = TextEditorComponent(
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
            ]
        )
        notExistSnapshotID = UUID()
        return (testTextEditorComponent, notExistSnapshotID)
    }
}
