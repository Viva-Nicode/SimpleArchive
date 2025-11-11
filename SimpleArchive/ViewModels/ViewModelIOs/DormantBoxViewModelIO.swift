import Foundation

enum DormantBoxViewInput {
    case viewDidLoad
    case showFileInformation(Int)
    case restoreFile(Int)
    case willRemovePageFromDormantBox(UUID)
}

enum DormantBoxViewOutput {
    case didfetchMemoData(Int)
    case showFileInformation(PageInformation)
    case didRemovePageFromDormantBox(Int)
}
