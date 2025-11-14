import Foundation

enum MemoHomeViewInput {
    case viewDidLoad

    case willMovePreviousDirectoryPath(UUID)
    case willNavigateDormantBoxView
    case willNavigateFixedPageView(Int)
    case willAppendPageToFixedTable([UUID])
    case willChangeFileName(UUID, String)
    case willSortDirectoryItems(SortCriterias)
    case willToggleAscendingOrder
}

enum MemoHomeSubViewInput {
    case willCreatedNewDirectory(String)
    case willCreatedNewPage(String, ComponentType?)
    case willMoveToFollowingDirectory(Int)
    case willNavigatePageView(Int)
    case willPresentFileInformationPopupView(Int)
    case willMoveFileToDormantBox(Int)
    case willAppendPageToHomeTable([UUID])
}

enum MemoHomeViewOutput {
    case didFetchMemoData(UUID, SortCriterias, FixedFileCollectionViewDataSource, Int)
    case didInsertRowToHomeTable(Int, [Int])
    case didMovePreviousDirectoryPath([Int], SortCriterias, Int)
    case didMoveToFollowingDirectory(String, UUID, SortCriterias, Int)
    case didPresentFileInformationPopupView(StorageItemInformationType)
    case didMoveFileToDormantBox(Int)
    case didNavigateDormantBoxView(DormantBoxViewModel)
    case didNavigatePageView(MemoPageViewModel)
    case didNavigateSingleTextEditorComponentPageView(SingleTextEditorPageViewModel)
    case didNavigateSingleTableComponentPageView(SingleTablePageViewModel)
    case didNavigateSingleAudioComponentPageView(SingleAudioPageViewModel)
    case didAppendPageToFixedTable(Int, [IndexPath], [IndexPath])
    case didAppendPageToHomeTable(Int, [IndexPath], [IndexPath])
    case didChangedFileName(String, Int, Int)
    case didSortDirectoryItems([(Int, Int)])
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
