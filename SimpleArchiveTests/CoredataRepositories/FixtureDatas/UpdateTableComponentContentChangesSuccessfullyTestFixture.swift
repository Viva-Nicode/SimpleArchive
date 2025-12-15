import Foundation

@testable import SimpleArchive

final class UpdateTableComponentContentChangesWithAppendColumnSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = TableComponent
    typealias ExpectedOutputType = ([TableComponentRow], [TableComponentColumn], Int)

    private var testDirectory: MemoDirectoryModel!
    private var tableComponent: TableComponent!

    let testTargetName = "test_updateTableComponentContentChanges_withAppendColumn_successfully()"
    private var provideState: TestDataProvideState = .givenFixtureData

    func getFixtureData() -> Any {
        switch provideState {
            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput

                let newColumn = tableComponent.componentContents.appendNewColumn(title: "newColumn")
                tableComponent.setCaptureState(to: .needsCapture)
                tableComponent.actions.append(.appendColumn(column: newColumn))

                return tableComponent!

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return (tableComponent.componentContents.rows, tableComponent.componentContents.columns, 4)

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        testDirectory = MemoDirectoryModel(name: "Test Directory")
        let testPage = MemoPageModel(name: "Test Page", parentDirectory: testDirectory)

        tableComponent = TableComponent()
        _ = tableComponent.componentContents.appendNewRow()
        testPage.appendChildComponent(component: tableComponent)

        return testDirectory
    }
}
