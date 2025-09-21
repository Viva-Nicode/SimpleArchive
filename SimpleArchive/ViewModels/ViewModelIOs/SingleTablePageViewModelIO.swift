import Foundation

enum SingleTablePageInput {
    case viewDidLoad
    case viewWillDisappear
    case willPresentSnapshotView
    case willRestoreComponentWithSnapshot
    case willCaptureToComponent(String)
    case willRemoveTableComponentRow(UUID)
    case willEditTableComponentCellValue(UUID, String)
    case willAppendTableComponentColumn
    case willAppendTableComponentRow
    case presentTableComponentColumnEditPopupView(Int)
    case editTableComponentColumn([TableComponentColumn])
}

enum SingleTablePageOutput {
    case viewDidLoad(String, Date, TableComponentContent, UUID)
    case didTappedSnapshotButton(ComponentSnapshotViewModel)
    case didTappedCaptureButton(TableComponentContent)
    case didAppendTableComponentColumn((TableComponentColumn, [TableComponentCell]))
    case didAppendTableComponentRow(TableComponentRow)
    case didRemoveTableComponentRow(Int)
    case didEditTableComponentCellValue(Int, Int, String)
    case didPresentTableComponentColumnEditPopupView([TableComponentColumn], Int)
    case didEditTableComponentColumn([TableComponentColumn])

}
