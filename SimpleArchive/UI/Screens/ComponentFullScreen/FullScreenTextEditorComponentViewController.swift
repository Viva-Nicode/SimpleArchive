import Combine
import UIKit

final class FullScreenTextEditorComponentViewController: ComponentFullScreenView<UITextView> {

    init(title: String, createDate: Date, componentTextView: UITextView) {
        super.init(componentContentView: componentTextView)

        super.setupUI()
        super.setupConstraints()

        toolBarView.backgroundColor = UIColor(named: "TextEditorComponentToolbarColor")

        setupData(title: title, date: createDate)
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
}
