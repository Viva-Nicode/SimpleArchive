import Combine
import UIKit

final class AudioDownloadPopupView: PopupView {

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "download music"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        return titleLabel
    }()
    private let downloadCodeTextField: RoundedTextField = {
        let downloadCodeTextField = RoundedTextField()
        downloadCodeTextField.attributedPlaceholder = NSAttributedString(
            string: "download code",
            attributes: [.foregroundColor: UIColor.systemGray])
        return downloadCodeTextField
    }()
    
    private let confirmButton: DynamicBackgrounColordButton = {
        let confirmButton = DynamicBackgrounColordButton()

        confirmButton.setBackgroundColor(.systemBlue, for: .normal)
        confirmButton.setBackgroundColor(.lightGray, for: .disabled)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.tintColor = .white
        confirmButton.isEnabled = false
        confirmButton.layer.cornerRadius = 5
        confirmButton.configuration = .plain()
        confirmButton.configuration?.contentInsets = NSDirectionalEdgeInsets(
            top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("download")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()

    var downloadButtonActionPublisher: AnyPublisher<String, Never> {
        confirmButton.throttleTapPublisher()
            .map { _ in self.dismiss() }
            .map { _ in self.downloadCodeTextField.text! }
            .eraseToAnyPublisher()
    }

    deinit { print("deinit MusicDownloadPopupView") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            downloadCodeTextField.becomeFirstResponder()
        } else {
            downloadCodeTextField.resignFirstResponder()
        }
    }

    override func popupViewDetailConfigure() {
        alertContainer.addArrangedSubview(titleLabel)
        alertContainer.addArrangedSubview(downloadCodeTextField)
        alertContainer.addArrangedSubview(confirmButton)
        downloadCodeTextField.delegate = self
    }
}

extension AudioDownloadPopupView: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text else {
            confirmButton.isEnabled = false
            return
        }
        confirmButton.isEnabled = !text.isEmpty
    }
}
