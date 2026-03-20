import Combine
import UIKit

final class FullScreenTextEditorComponentViewController: ComponentFullScreenView<UITextView> {

    init(title: String, createDate: Date, componentTextView: UITextView) {
        super.init(componentContentView: componentTextView)

        super.setupUI()
        super.setupConstraints()

        toolBarView.backgroundColor = UIColor(named: "TextEditorComponentToolbarColor")

        setupData(title: title, date: createDate)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var toolbarColor: UIColor? {
        UIColor(named: "TextEditorComponentToolbarColor")
    }

    private func setupData(title: String, date: Date) {
        titleLabel.text = title
        creationDateLabel.text = "created at \(date.formattedDate)"

        greenCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                dismiss(animated: true)
            }
            .store(in: &subscriptions)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let keyboardHeight = view.convert(endFrame, from: nil).intersection(view.frame).height

        componentContentView.contentInset.bottom = keyboardHeight
        componentContentView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }

    @objc private func keyboardDidHide(_ notification: Notification) {
        componentContentView.contentInset.bottom = 170
        componentContentView.verticalScrollIndicatorInsets.bottom = 0
    }
}
