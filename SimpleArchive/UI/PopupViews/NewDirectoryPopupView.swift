import UIKit
import Combine

class NewDirectoryPopupView: PopupView {
    
    private let subject: PassthroughSubject<MemoHomeSubViewInput, Never>

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Create New Directory"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        return titleLabel
    }()
    private let newDirectoryNameTextField: RoundedTextField = {
        let newDirectoryNameTextField = RoundedTextField()
        newDirectoryNameTextField.attributedPlaceholder = NSAttributedString(
            string: "Directory Name",
            attributes: [.foregroundColor: UIColor.systemGray])
        return newDirectoryNameTextField
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
        confirmButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Create")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()

    init(subject: PassthroughSubject<MemoHomeSubViewInput, Never>) {
        self.subject = subject
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { print("deinit NewDirectoryPopupView") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            newDirectoryNameTextField.becomeFirstResponder()
        } else {
            newDirectoryNameTextField.resignFirstResponder()
        }
    }

    override func popupViewDetailConfigure() {
        alertContainer.addArrangedSubview(titleLabel)
        alertContainer.addArrangedSubview(newDirectoryNameTextField)
        alertContainer.addArrangedSubview(confirmButton)
        newDirectoryNameTextField.delegate = self

        confirmButton.throttleTapPublisher()
            .sink { _ in
            self.subject.send(.willCreatedNewDirectory(self.newDirectoryNameTextField.text ?? "new directory"))
            self.dismiss()
        }.store(in: &subscriptions)
    }
}

extension NewDirectoryPopupView: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text else {
            confirmButton.isEnabled = false
            return
        }
        confirmButton.isEnabled = !text.isEmpty
    }
}
