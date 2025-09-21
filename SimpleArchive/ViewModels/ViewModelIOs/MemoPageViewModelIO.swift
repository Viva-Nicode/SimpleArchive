import Foundation

enum MemoPageViewInput {
    case viewDidLoad
    case createNewComponent(ComponentType)
    case minimizeComponent(UUID)
    case maximizeComponent(UUID)
    case removeComponent(UUID)
    case changeComponentName(UUID, String)
    case changeComponentOrder(Int, Int)
    case tappedSnapshotButton(UUID)
    case tappedCaptureButton(UUID, String)
    case appendTableComponentRow(UUID)
    case removeTableComponentRow(UUID, UUID)
    case appendTableComponentColumn(UUID)
    case editTableComponentColumn(UUID,[TableComponentColumn])
    case editTableComponentCellValue(UUID, UUID, String)
    case presentTableComponentColumnEditPopupView(UUID, Int)
    case viewWillDisappear
}

enum MemoPageViewOutput {
    case viewDidLoad(String, Bool)
    case insertNewComponentAtLastIndex(Int)
    case removeComponentAtIndex(Int)
    case maximizeComponent(any PageComponent, Int)
    case didTappedSnapshotButton(ComponentSnapshotViewModel, Int)
    case didMinimizeComponentHeight(Int)
    case didAppendTableComponentRow(Int, TableComponentRow)
    case didRemoveTableComponentRow(Int, Int)
    case didAppendTableComponentColumn(Int, (TableComponentColumn, [TableComponentCell]))
    case didEditTableComponentCellValue(Int, Int, Int, String)
    case didPresentTableComponentColumnEditPopupView([TableComponentColumn], Int,UUID)
    case didEditTableComponentColumn(Int,[TableComponentColumn])
    
}
