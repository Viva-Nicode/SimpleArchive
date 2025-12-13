import Foundation

@testable import SimpleArchive

final class RemoveSnapshotFailureWhenNotFoundSnapshotTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = (TextEditorComponent, UUID)
    typealias TestTargetInputType = UUID
    typealias ExpectedOutputType = NoUsed

    let testTargetName = "test_removeSnapshot_failureWhenNotFoundSnapshot()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var notExistSnapshotID: UUID!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return notExistSnapshotID!

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
            ]
        )
        notExistSnapshotID = UUID()
        return (testTextEditorComponent, notExistSnapshotID)
    }
}
