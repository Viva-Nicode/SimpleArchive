import Combine
import UIKit

final class SnapshotCapturePopupView: PopupView {

    enum SnapshotCapturePopupViewState {
        case initial
        case complete
    }

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
    private let captureButton: DynamicBackgrounColordButton = {
        let confirmButton = DynamicBackgrounColordButton()
        confirmButton.setBackgroundColor(.systemBlue, for: .normal)
        confirmButton.setBackgroundColor(.lightGray, for: .disabled)
        confirmButton.backgroundColor = .systemBlue
        confirmButton.tintColor = .white
        confirmButton.layer.cornerRadius = 5
        confirmButton.configuration = .plain()
        confirmButton.configuration?.contentInsets = .init(top: 12, leading: 0, bottom: 12, trailing: 0)

        var titleAttr = AttributedString.init("Capture")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()

    var state: SnapshotCapturePopupViewState = .initial {
        didSet {
            switch state {

                case .initial:
                    break

                case .complete:
                    setStateToCaptureComplete()
            }
        }
    }

    var captureButtonPublisher: AnyPublisher<String, Never> {
        captureButton.throttleTapPublisher()
            .map { [weak self] _ in
                self?.snapshotDesctiptionTextView.text ?? ""
            }
            .eraseToAnyPublisher()
    }

    deinit { print("deinit SnapshotCapturePopupView") }

    private func setStateToCaptureComplete() {
        let checkmark = UIImageView()
        let completeLabel = UILabel()

        let alertContainerWidth = alertContainer.frame.width
        let titleLabelMaxY = titleLabel.frame.maxY

        checkmark.image = UIImage(systemName: "checkmark.circle")
        checkmark.tintColor = .systemGreen
        checkmark.frame.size = .init(width: 65, height: 65)
        checkmark.frame.origin = .init(x: (alertContainerWidth * 0.5) - 65 * 0.5, y: titleLabelMaxY + 8)
        checkmark.alpha = 0

        completeLabel.text = "capture complete"
        completeLabel.textColor = .systemGreen
        completeLabel.font = .systemFont(ofSize: 15)
        completeLabel.sizeToFit()
        completeLabel.frame.origin = .init(
            x: (alertContainerWidth * 0.5) - completeLabel.frame.width * 0.5,
            y: checkmark.frame.maxY)
        completeLabel.alpha = 0

        alertContainer.addSubview(checkmark)
        alertContainer.addSubview(completeLabel)

        UIView.animateKeyframes(withDuration: 0.6, delay: 0, options: []) {

            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) { [weak self] in
                guard let self else { return }
                snapshotDescriptionLabel.alpha = 0
                snapshotDesctiptionTextView.alpha = 0
                bottomBorder.alpha = 0
                textLengthLabel.alpha = 0
                captureButton.isEnabled = false
            }

            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                checkmark.alpha = 1
                completeLabel.alpha = 1
            }
        }
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
        alertContainer.addArrangedSubview(captureButton)
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
