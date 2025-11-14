import Foundation

enum SingleTablePageInput {
    case viewDidLoad
    case viewWillDisappear

    case willNavigateSnapshotView
    case willRestoreComponent
    case willCaptureComponent(String)

    case willAppendRowToTable
    case willRemoveRowToTable(UUID)
    case willAppendColumnToTable
    case willApplyTableCellChanges(UUID, String)
    case willPresentTableColumnEditingPopupView(Int)
    case willApplyTableColumnChanges([TableComponentColumn])
}

enum SingleTablePageOutput {
    case viewDidLoad(String, Date, TableComponentContent, UUID)

    case didNavigateSnapshotView(ComponentSnapshotViewModel)
    case didRestoreComponent(TableComponentContent)
    case didCompleteComponentCapture

    case didAppendRowToTableView(TableComponentRow)
    case didAppendColumnToTableView((TableComponentColumn, [TableComponentCell]))
    case didRemoveRowToTableView(Int)
    case didApplyTableCellValueChanges(Int, Int, String)
    case didPresentTableColumnEditPopupView([TableComponentColumn], Int)
    case didApplyTableColumnChanges([TableComponentColumn])
}
