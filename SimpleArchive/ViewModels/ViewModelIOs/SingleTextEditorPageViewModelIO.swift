import Combine
import Foundation

enum SingleTextEditorPageInput {
    case viewDidLoad(PassthroughSubject<String, Never>)
    case viewWillDisappear
    case willPresentSnapshotView
    case willRestoreComponentWithSnapshot
    case willCaptureToComponent(String)
}

enum SingleTextEditorPageOutput {
    case viewDidLoad(String, Date, String)
    case didTappedSnapshotButton(ComponentSnapshotViewModel)
    case didTappedCaptureButton(String)

}
