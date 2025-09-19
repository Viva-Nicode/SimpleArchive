import Foundation

enum DormantBoxViewInput {
    case viewDidLoad
    case showFileInformation(Int)
    case restoreFile(Int)
    case moveToPage(Int)
}

enum DormantBoxViewOutput {
    case didfetchMemoData
    case showFileInformation(any StorageItem)
    case getMemoPageViewModel(MemoPageViewModel)
}

