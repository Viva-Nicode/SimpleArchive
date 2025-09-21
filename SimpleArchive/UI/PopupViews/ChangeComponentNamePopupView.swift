import UIKit
import Combine

class ChangeComponentNamePopupView: PopupView {

    private var changeTitle: (String) -> ()
    let componentTitle: String

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Rename"
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .black
        return titleLabel
    }()
    private let newComponentNameTextField: RoundedTextField = {
        let newComponentNameTextField = RoundedTextField()
        return newComponentNameTextField
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

        var titleAttr = AttributedString.init("Yes, Change!")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()

    init(componentTitle: String, changeTitle: @escaping (String) -> ()) {
        self.componentTitle = componentTitle
        self.changeTitle = changeTitle
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("deinit ChangeComponentNamePopupView") }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            newComponentNameTextField.becomeFirstResponder()
        } else {
            newComponentNameTextField.resignFirstResponder()
        }
    }
    
    override func popupViewDetailConfigure() {
        alertContainer.addArrangedSubview(titleLabel)
        alertContainer.addArrangedSubview(newComponentNameTextField)
        newComponentNameTextField.attributedPlaceholder = NSAttributedString(
            string: componentTitle,
            attributes: [.foregroundColor: UIColor.systemGray])

        newComponentNameTextField.delegate = self

        alertContainer.addArrangedSubview(confirmButton)

        confirmButton.throttleTapPublisher()
            .sink { [weak self] _ in
            guard let self else { return }
            changeTitle(newComponentNameTextField.text!)
            dismiss()
        }.store(in: &subscriptions)
    }
}

extension ChangeComponentNamePopupView: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text else {
            confirmButton.isEnabled = false
            return
        }
        confirmButton.isEnabled = !text.isEmpty
    }
}


