import Foundation

@testable import SimpleArchive

final class CaptureSnapshotWithAutoMaticSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = [any SnapshotRestorablePageComponent]
    typealias ExpectedOutputType = [UUID: (snapshotCount: Int, snapshotContents: String)]

    let testTargetName = "test_captureSnapshot_withAutoMatic_successfully()"
    private var provideState: TestDataProvideState = .givenFixtureData
    private var testPage: MemoPageModel!

    private var output: ExpectedOutputType = [:]

    func getFixtureData() -> Any {
        switch provideState {
            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return testPage
                    .getComponents
                    .compactMap { $0 as? any SnapshotRestorablePageComponent }
                    .compactMap { $0.currentIfUnsaved() }

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return output

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testDirectory = MemoDirectoryModel(name: "Test Directory")
        testPage = MemoPageModel(name: "Test Page", parentDirectory: testDirectory)

        let textEditorComponent = TextEditorComponent(
            contents: "first textEditorComponentContents has Changes",
            captureState: .needsCapture,
            componentSnapshots: [
                .init(contents: "contnet", description: "", saveMode: .automatic),
                .init(contents: "contnet", description: "", saveMode: .automatic),
                .init(contents: "contnet", description: "", saveMode: .automatic),
            ]
        )

        output[textEditorComponent.id] = (4, "first textEditorComponentContents has Changes")
        testPage.appendChildComponent(component: textEditorComponent)

        var tableComponentContents = TableComponentContents()
        _ = tableComponentContents.appendNewColumn(title: "column1")
        let col_2 = tableComponentContents.appendNewColumn(title: "column2")
        _ = tableComponentContents.appendNewRow()
        let row_2 = tableComponentContents.appendNewRow()
        _ = tableComponentContents.editCellValeu(rowID: row_2.id, colID: col_2.id, newValue: "cellValue")

        let tableComponent = TableComponent(
            contents: tableComponentContents,
            captureState: .needsCapture,
            componentSnapshots: [
                .init(contents: TableComponentContents(), description: "", saveMode: .automatic),
                .init(contents: TableComponentContents(), description: "", saveMode: .automatic),
                .init(contents: TableComponentContents(), description: "", saveMode: .automatic),
            ]
        )

        output[tableComponent.id] = (4, tableComponentContents.jsonString)
        testPage.appendChildComponent(component: tableComponent)

        let secondTextComponent = TextEditorComponent(
            contents: "second textEditorComponentContents has Changes",
            captureState: .needsCapture,
            componentSnapshots: [
                .init(contents: "contnet", description: "", saveMode: .automatic),
                .init(contents: "contnet", description: "", saveMode: .automatic),
                .init(contents: "contnet", description: "", saveMode: .automatic),
            ]
        )
        output[secondTextComponent.id] = (4, "second textEditorComponentContents has Changes")
        testPage.appendChildComponent(component: secondTextComponent)

        return testDirectory
    }
}
