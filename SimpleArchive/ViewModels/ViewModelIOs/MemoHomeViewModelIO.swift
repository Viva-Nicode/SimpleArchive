import Foundation

enum MemoHomeViewInput {
    case viewDidLoad
    case didTappedDirectoryPath(UUID)
    case getDormantBoxViewModel
    case didTappedFixedPageRow(Int)
    case didPerformDropOperationInFixedTable([UUID])
    case changeFileName(UUID, String)
    case changeFileSortBy(SortCriterias)
    case toggleAscendingOrder
}

enum MemoHomeSubViewInput {
    case didCreatedNewDirectory(String)
    case didCreatedNewPage(String, ComponentType?)
    case didTappedDirectoryRow(Int)
    case didTappedPageRow(Int)
    case showFileInformation(Int)
    case removeFile(Int)
    case didPerformDropOperationInHomeTable([UUID])
}

enum MemoHomeViewOutput {
    case didfetchMemoData(UUID, SortCriterias, FixedFileCollectionViewDataSource, Int)
    case insertRowToTable(Int, [Int])
    case didTappedDirectoryPath([Int], SortCriterias, Int)
    case didTappedDirectoryRow(String, UUID, SortCriterias, Int)
    case showFileInformation(StorageItemInformationType)
    case didRemoveFile(Int)
    case moveDoramntBoxView(DormantBoxViewModel)
    case getMemoPageViewModel(MemoPageViewModel)
    case presentSingleTextEditorComponentPage(SingleTextEditorPageViewModel)
    case presentSingleTableComponentPage(SingleTablePageViewModel)
    case presentSingleAudioComponentPage(SingleAudioPageViewModel)
    case didPerformDropOperationInFixedTable(Int, [IndexPath], [IndexPath])
    case didPerformDropOperationInHomeTable(Int, [IndexPath], [IndexPath])
    case didChangedFileName(String, Int, Int)
    case didChangeSortCriteria([(Int, Int)])
}

enum MemoHomeViewModelError: MessageErrorType {
    case canNotLoadMemoData

    var errorMessage: String {
        switch self {
            case .canNotLoadMemoData:
                "An error occurred while loading the memo data."
        }
    }
}
