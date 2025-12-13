import Foundation

@testable import SimpleArchive

final class RestoreSnapshotSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = TextEditorComponent
    typealias TestTargetInputType = NoUsed
    typealias ExpectedOutputType = (String, CaptureState)

    let testTargetName = "test_restoreSnapshot_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var testTextEditorComponent: TextEditorComponent!

    func getFixtureData() -> Any {
        switch provideState {

            case .givenFixtureData:
                provideState = .testVerifyOutput
                return provideGivenFixture()

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return ExpectedOutputType("Snapshot 1 contents", .captured)
            
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
        return testTextEditorComponent
    }
}
