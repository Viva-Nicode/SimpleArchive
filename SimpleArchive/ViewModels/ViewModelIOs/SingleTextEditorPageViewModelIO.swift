import Combine
import Foundation

enum SingleTextEditorPageInput {
    case viewDidLoad
    case viewWillDisappear
    
    case willNavigateSnapshotView
    case willRestoreComponent
    case willCaptureComponent(String)
    
    case willEditTextComponent(String)
}

enum SingleTextEditorPageOutput {
    case viewDidLoad(String, Date, String)
    
    case didNavigateSnapshotView(ComponentSnapshotViewModel)
    case didRestoreComponent(String)
    case didCompleteComponentCapture
}
