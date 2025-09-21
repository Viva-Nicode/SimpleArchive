import Combine
import UIKit

final class FullScreenTextEditorComponentViewController: ComponentFullScreenView<UITextView>, UITextViewDelegate {

    private var detailAssignSubject = PassthroughSubject<String, Never>()

    init(textEditorComponentModel: TextEditorComponent, componentTextView: UITextView) {
        super.init(componentContentView: componentTextView)
        textEditorComponentModel
            .assignDetail(subject: detailAssignSubject)
            .store(in: &subscriptions)

        super.setupUI()
        super.setupConstraints()

        toolBarView.backgroundColor = UIColor(named: "TextEditorComponentToolbarColor")

        setupData(title: textEditorComponentModel.title, date: textEditorComponentModel.creationDate)
        self.componentContentView.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("FullScreenComponentViewController deinit") }

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

    func textViewDidChange(_ textView: UITextView) {
        detailAssignSubject.send(textView.text)
    }
}
