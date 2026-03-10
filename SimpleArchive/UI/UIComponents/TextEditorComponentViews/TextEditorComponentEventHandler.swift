import Combine
import UIKit

class TextEditorComponentViewEventHandler: ComponentViewEventHandlerType {
    private var contentsView: UITextView
    private var restorePublisherSubscription: AnyCancellable?

    init(contentsView: UITextView) {
        self.contentsView = contentsView
    }

    func UIupdateEventHandler(_ event: TextEditorComponentViewModelEvent) {
        switch event {
            case .textEditorComponentEvent(let event):
                switch event {
                    case .didUndoTextComponentContents(let undidText):
                        contentsView.text = undidText
                }

            case .snapshotEvent(let snapshotRestorableComponentEvent):
                switch snapshotRestorableComponentEvent {
                    case .didManualCapturePageComponent:
                        guard let host = contentsView.parentViewController as? ManualCaptureHost else { return }
                        host.completeManualCapture()

                    case .didNavigateComponentSnapshotView(let componentSnapshotViewModel):
                        guard let vc = contentsView.parentViewController else { return }
                        let snapshotView = ComponentSnapshotViewController(viewModel: componentSnapshotViewModel)

                        restorePublisherSubscription = snapshotView.hasRestorePublisher
                            .sink { [weak self] contents in
                                guard let self else { return }
                                if let loadableSuperView: ContentsReloadableView = contentsView.findSuperViewMatched() {
                                    loadableSuperView.reloadUsingRestoredContents(contents: contents)
                                }
                                restorePublisherSubscription = nil
                            }
                        vc.navigationController?.pushViewController(snapshotView, animated: true)
                }
        }
    }
}
