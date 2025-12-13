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
        let notExistSnapshotID = UUID()
        return (testTextEditorComponent, notExistSnapshotID)
    }
}
