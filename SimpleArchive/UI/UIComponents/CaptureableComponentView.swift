import UIKit

protocol CaptureableComponentView: AnyObject {
    var snapshotCapturePopupView: SnapshotCapturePopupView? { get set }
    func completeSnapshotCapturePopupView()
}

extension CaptureableComponentView {
    func completeSnapshotCapturePopupView() {
        snapshotCapturePopupView?.state = .complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.snapshotCapturePopupView?.dismiss()
            self?.snapshotCapturePopupView = nil
        }
    }
}
