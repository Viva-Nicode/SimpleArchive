import UIKit

class SnapshotCapturePopupView: PopupView {

    private let confirmToSnapshot: (String) -> ()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Capture Snapshot"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = .black
        return titleLabel
    }()
    private let snapshotDescriptionLabel: UILabel = {
        let snapshotDescriptionLabel = UILabel()
        snapshotDescriptionLabel.text = "snapshot comment"
        snapshotDescriptionLabel.font = .systemFont(ofSize: 16, weight: .regular)
        snapshotDescriptionLabel.textColor = .systemGray3
        return snapshotDescriptionLabel
    }()
    private let snapshotDesctiptionTextView: UITextView = {
        let snapshotDesctiptionTextField = UITextView()
        snapshotDesctiptionTextField.autocorrectionType = .no
        snapshotDesctiptionTextField.spellCheckingType = .no
        snapshotDesctiptionTextField.autocapitalizationType = .none
        snapshotDesctiptionTextField.backgroundColor = .white
        snapshotDesctiptionTextField.textColor = .black
        snapshotDesctiptionTextField.font = .systemFont(ofSize: 15)
        snapshotDesctiptionTextField.isScrollEnabled = false
        return snapshotDesctiptionTextField
    }()
    private let bottomBorder: UIView = {
        let bottomBorder = UIView()
        bottomBorder.backgroundColor = .blue
        bottomBorder.translatesAutoresizingMaskIntoConstraints = false
        bottomBorder.heightAnchor.constraint(equalToConstant: 1.2).isActive = true
        return bottomBorder
    }()
    private let textLengthLabel: UILabel = {
        let textLengthLabel = UILabel()
        textLengthLabel.text = "0 / 100"
        textLengthLabel.font = .systemFont(ofSize: 13)
        textLengthLabel.textColor = .gray
        return textLengthLabel
    }()
    private let confirmButton: DynamicBackgrounColordButton = {
        let confirmButton = DynamicBackgrounColordButton()
        confirmButton.setBackgroundColor(.systemBlue, for: .normal)
        confirmButton.setBackgroundColor(.lightGray, for: .disabled)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.tintColor = .white
        confirmButton.layer.cornerRadius = 5
        confirmButton.configuration = .plain()
        confirmButton.configuration?.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Capture")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(confirmToSnapshot: @escaping (String) -> ()) {
        self.confirmToSnapshot = confirmToSnapshot
        super.init()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            snapshotDesctiptionTextView.becomeFirstResponder()
        } else {
            snapshotDesctiptionTextView.resignFirstResponder()
        }
    }

    override func popupViewDetailConfigure() {
        let descriptionTextStackView = UIStackView()
        descriptionTextStackView.axis = .vertical
        descriptionTextStackView.spacing = 0
        descriptionTextStackView.addArrangedSubview(snapshotDescriptionLabel)
        descriptionTextStackView.addArrangedSubview(snapshotDesctiptionTextView)
        descriptionTextStackView.addArrangedSubview(bottomBorder)
        descriptionTextStackView.addArrangedSubview(textLengthLabel)

        snapshotDesctiptionTextView.delegate = self

        alertContainer.addArrangedSubview(titleLabel)
        alertContainer.addArrangedSubview(descriptionTextStackView)

        let buttonAction = UIAction { [weak self] _ in
            self?.confirmToSnapshot(self?.snapshotDesctiptionTextView.text ?? "")
            self?.dismiss()
        }

        confirmButton.addAction(buttonAction, for: .touchUpInside)
        alertContainer.addArrangedSubview(confirmButton)
    }
}

extension SnapshotCapturePopupView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentText = textView.text ?? ""
        let updatedText = (currentText as NSString).replacingCharacters(in: range, with: text)
        textLengthLabel.text = "\(min(100, updatedText.count)) / 100"
        return updatedText.count <= 100
    }
}
