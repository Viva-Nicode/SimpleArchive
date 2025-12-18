import Combine
import UIKit

class ErrorMessagePopupView: PopupView {

    private var cancelable: AnyCancellable?

    private let popupViewHeaderStackView: UIStackView = {
        let popupViewHeaderStackView = UIStackView()
        popupViewHeaderStackView.axis = .horizontal
        popupViewHeaderStackView.alignment = .center
        popupViewHeaderStackView.spacing = 4
        return popupViewHeaderStackView
    }()
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Error"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .systemPink
        return titleLabel
    }()
    private let titleIcon: UIImageView = {
        let titleIcon = UIImageView()
        titleIcon.image = UIImage(systemName: "exclamationmark.square")
        titleIcon.tintColor = .systemPink
        titleIcon.contentMode = .scaleAspectFit
        titleIcon.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleIcon.setContentCompressionResistancePriority(.required, for: .horizontal)
        return titleIcon
    }()
    private let errorMessageLabel: UILabel = {
        let errorMessageLabel = UILabel()
        errorMessageLabel.numberOfLines = 0
        return errorMessageLabel
    }()
    private let confirmButton: UIButton = {
        let confirmButton = UIButton()
        confirmButton.backgroundColor = .systemPink
        confirmButton.tintColor = .white
        confirmButton.layer.cornerRadius = 5
        confirmButton.configuration = .plain()
        confirmButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("damn it!")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()

    init(error: any MessageErrorType, confirmButtomAction: (() -> Void)? = nil) {
        errorMessageLabel.text = error.errorMessage
        super.init()
        cancelable = confirmButton.throttleTapPublisher()
            .map { _ in confirmButtomAction?() }
            .sink {
                self.dismiss()
                self.cancelable = nil
            }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("ErrorMessagePopupView deinit") }

    override func popupViewDetailConfigure() {
        popupViewHeaderStackView.addArrangedSubview(titleIcon)
        popupViewHeaderStackView.addArrangedSubview(titleLabel)

        alertContainer.addArrangedSubview(popupViewHeaderStackView)
        alertContainer.addArrangedSubview(errorMessageLabel)
        alertContainer.addArrangedSubview(confirmButton)
    }
}
