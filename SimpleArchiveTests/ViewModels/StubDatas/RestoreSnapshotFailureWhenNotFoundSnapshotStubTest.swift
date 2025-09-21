import Foundation

@testable import SimpleArchive

final class RestoreSnapshotFailureWhenNotFoundSnapshotStubTest: StubDatable {
    typealias GivenStubDataType = (TextEditorComponent, UUID)
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_restoreSnapshot_failureWhenNotFoundSnapshot()"

    private var provideState: TestDataProvideState = .givenStubData

    func getStubData() -> Any {
        switch provideState {

            case .givenStubData:
                provideState = .testTargetInput
                return provideGivenStub()

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
        let notExistSnapshotID = UUID()
        return (testTextEditorComponent, notExistSnapshotID)
    }
}
