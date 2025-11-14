import Combine
import Foundation

enum SingleTextEditorPageInput {
    case viewDidLoad(PassthroughSubject<String, Never>)
    case viewWillDisappear
    
    case willNavigateSnapshotView
    case willRestoreComponent
    case willCaptureComponent(String)
}

enum SingleTextEditorPageOutput {
    case viewDidLoad(String, Date, String)
    
    case didNavigateSnapshotView(ComponentSnapshotViewModel)
    case didRestoreComponent(String)
    case didCompleteComponentCapture
}
