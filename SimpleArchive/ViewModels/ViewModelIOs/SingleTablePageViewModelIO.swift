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
    case willApplyTableCellChanges(UUID, UUID, String)
    case willPresentTableColumnEditingPopupView(UUID)
    case willApplyTableColumnChanges([TableComponentColumn])
}

enum SingleTablePageOutput {
    case viewDidLoad(String, Date, TableComponentContents, UUID)

    case didNavigateSnapshotView(ComponentSnapshotViewModel)
    case didRestoreComponent(TableComponentContents)
    case didCompleteComponentCapture

    case didAppendRowToTableView(TableComponentRow)
    case didAppendColumnToTableView(TableComponentColumn)
    case didRemoveRowToTableView(Int)
    case didApplyTableCellValueChanges(Int, Int, String)
    case didPresentTableColumnEditPopupView([TableComponentColumn], Int)
    case didApplyTableColumnChanges([TableComponentColumn])
}
