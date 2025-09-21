import UIKit
import Combine

class PageInformationPopupView: PopupView {

    private let pageInformation: PageInformation
    private var state: InformationPopupViewState = .information
    var delegate: InformationPopupViewDelegate?
    let isReadOnly: Bool

    private let titleView: UIStackView = {
        let titleView = UIStackView()
        titleView.axis = .horizontal
        titleView.alignment = .center
        titleView.spacing = 4
        return titleView
    }()
    private let titleIconView: UIImageView = {
        let titleIconView = UIImageView()
        titleIconView.image = UIImage(systemName: "note.text")
        titleIconView.tintColor = .systemBlue
        titleIconView.contentMode = .scaleAspectFit
        titleIconView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        titleIconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return titleIconView
    }()
    private let informationTitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Information"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .black
        return titleLabel
    }()
    private let renameTitleLabel: UILabel = {
        let renameTitleLabel = UILabel()
        renameTitleLabel.text = "Rename"
        renameTitleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        renameTitleLabel.textColor = .black
        renameTitleLabel.isHidden = true
        renameTitleLabel.alpha = 0
        return renameTitleLabel
    }()
    private let pageNameView: UIStackView = {
        let pageNameView = UIStackView()
        pageNameView.axis = .vertical
        pageNameView.spacing = 0
        pageNameView.alignment = .leading

        let name: UILabel = {
            let name = UILabel()
            name.text = "name"
            name.font = .systemFont(ofSize: 15, weight: .regular)
            name.textColor = .systemGray2
            return name
        }()

        pageNameView.addArrangedSubview(name)
        return pageNameView
    }()
    private let pageNameStackView: UIStackView = {
        let pageNameStackView = UIStackView()
        pageNameStackView.axis = .horizontal
        pageNameStackView.alignment = .center
        pageNameStackView.spacing = 0
        return pageNameStackView
    }()
    private let pageNameLabel: UILabel = {
        let pageNameLabel = UILabel()
        pageNameLabel.font = .systemFont(ofSize: 16, weight: .regular)
        pageNameLabel.textColor = .black
        return pageNameLabel
    }()
    private let renamePencilButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.plain()
        let image = UIImage(systemName: "pencil.circle")?
            .withConfiguration(UIImage.SymbolConfiguration(pointSize: 14))
        buttonConfiguration.image = image
        buttonConfiguration.contentInsets = .zero
        let renamePencilButton = UIButton(configuration: buttonConfiguration)
        renamePencilButton.tintColor = .systemGray3
        return renamePencilButton
    }()
    private let filePathView: UIStackView = {
        let filePathView = UIStackView()
        filePathView.axis = .vertical
        filePathView.spacing = 0
        filePathView.alignment = .leading

        let location: UILabel = {
            let location = UILabel()
            location.text = "location"
            location.font = .systemFont(ofSize: 15, weight: .regular)
            location.textColor = .systemGray2
            return location
        }()

        filePathView.addArrangedSubview(location)
        return filePathView
    }()
    private let filePathLabel: UILabel = {
        let filePathLabel = UILabel()
        filePathLabel.font = .systemFont(ofSize: 16, weight: .regular)
        filePathLabel.textColor = .black
        return filePathLabel
    }()
    private let createDateView: UIStackView = {
        let createDateView = UIStackView()
        createDateView.axis = .vertical
        createDateView.spacing = 0
        createDateView.alignment = .leading

        let createDate: UILabel = {
            let createDate = UILabel()
            createDate.text = "create date"
            createDate.font = .systemFont(ofSize: 15, weight: .regular)
            createDate.textColor = .systemGray2
            return createDate
        }()

        createDateView.addArrangedSubview(createDate)
        return createDateView
    }()
    private let createDateLabel: UILabel = {
        let createDateLabel = UILabel()
        createDateLabel.font = .systemFont(ofSize: 16, weight: .regular)
        createDateLabel.textColor = .black
        return createDateLabel
    }()
    private let containedFileCountLabel: UILabel = {
        let containedFileCountLabel = UILabel()
        containedFileCountLabel.font = .systemFont(ofSize: 15, weight: .thin)
        containedFileCountLabel.textColor = .black
        containedFileCountLabel.alpha = 0.8
        return containedFileCountLabel
    }()
    private let newNameTextField: RoundedTextField = {
        let newNameTextField = RoundedTextField()
        newNameTextField.isHidden = true
        newNameTextField.alpha = 0
        return newNameTextField
    }()
    private let buttonContainer: UIStackView = {
        let buttonContainer = UIStackView()
        buttonContainer.axis = .horizontal
        buttonContainer.spacing = 15
        buttonContainer.alignment = .center
        buttonContainer.distribution = .fillEqually
        buttonContainer.isHidden = true
        buttonContainer.alpha = 0
        return buttonContainer
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

        var titleAttr = AttributedString.init("Yes, Change!")
        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        confirmButton.configuration?.attributedTitle = titleAttr

        return confirmButton
    }()
    private let cancelButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.filled()
        var titleAttr = AttributedString.init("No, Keep It.")

        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        buttonConfiguration.baseBackgroundColor = .systemPink

        titleAttr.font = .systemFont(ofSize: 15, weight: .regular)
        buttonConfiguration.attributedTitle = titleAttr

        return UIButton(configuration: buttonConfiguration)
    }()

    init(pageInformation: PageInformation, isReadOnly: Bool = false) {
        self.pageInformation = pageInformation
        self.isReadOnly = isReadOnly
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("FileInformationPopupView deinit") }

    override func popupViewDetailConfigure() {
        pageNameLabel.text = pageInformation.name
        filePathLabel.text = pageInformation.filePath
        createDateLabel.text = pageInformation.created.formattedDate
        containedFileCountLabel.text = "Contains \(pageInformation.containedComponentCount) notes"

        titleView.addArrangedSubview(titleIconView)
        titleView.addArrangedSubview(informationTitleLabel)
        titleView.addArrangedSubview(renameTitleLabel)
        alertContainer.addArrangedSubview(titleView)

        pageNameStackView.addArrangedSubview(pageNameLabel)

        if !isReadOnly {
            pageNameStackView.addArrangedSubview(renamePencilButton)
            renamePencilButton.throttleUIViewTapGesturePublisher()
                .sink { _ in self.transformToDirectoryRenameViewWithAnimation() }
                .store(in: &subscriptions)
        }

        pageNameView.addArrangedSubview(pageNameStackView)
        alertContainer.addArrangedSubview(pageNameView)

        filePathView.addArrangedSubview(filePathLabel)
        alertContainer.addArrangedSubview(filePathView)

        createDateView.addArrangedSubview(createDateLabel)
        alertContainer.addArrangedSubview(createDateView)

        alertContainer.addArrangedSubview(containedFileCountLabel)

        alertContainer.addArrangedSubview(newNameTextField)

        newNameTextField.delegate = self
        newNameTextField.attributedPlaceholder = NSAttributedString(
            string: pageInformation.name,
            attributes: [.foregroundColor: UIColor.systemGray])

        buttonContainer.addArrangedSubview(cancelButton)
        buttonContainer.addArrangedSubview(confirmButton)
        alertContainer.addArrangedSubview(buttonContainer)

        cancelButton.throttleTapPublisher()
            .sink { _ in self.transformToDirectoryRenameViewWithAnimation() }
            .store(in: &subscriptions)

        confirmButton.throttleTapPublisher()
            .sink { _ in
            self.delegate?.rename(
                fileID: self.pageInformation.id,
                newName: self.newNameTextField.text!)
            self.dismiss()
        }.store(in: &subscriptions)
    }

    func transformToDirectoryRenameViewWithAnimation() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self else { return }

            [informationTitleLabel, renameTitleLabel, pageNameView,
                filePathView, createDateView, containedFileCountLabel,
                newNameTextField, buttonContainer].forEach {
                $0.isHidden.toggle()
                $0.alpha = $0.alpha == 0 ? 1 : 0
            }

            if newNameTextField.isHidden == false {
                newNameTextField.becomeFirstResponder()
                newNameTextField.text = ""
                confirmButton.isEnabled = false
            } else {
                newNameTextField.resignFirstResponder()
            }
        }
    }
}

extension PageInformationPopupView: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text else {
            confirmButton.isEnabled = false
            return
        }
        confirmButton.isEnabled = !text.isEmpty
    }
}
