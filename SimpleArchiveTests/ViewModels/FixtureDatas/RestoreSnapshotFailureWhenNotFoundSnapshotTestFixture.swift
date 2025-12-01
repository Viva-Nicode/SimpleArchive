import Foundation

@testable import SimpleArchive

final class RestoreSnapshotFailureWhenNotFoundSnapshotTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (TextEditorComponent, UUID)
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_restoreSnapshot_failureWhenNotFoundSnapshot()"

    private var provideState: TestDataProvideState = .givenFixtureData

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
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
