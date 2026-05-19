import Combine
import UIKit

final class RemovedFileInformationPopupView: PopupView {
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
        return titleLabel
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
            name.textColor = AppAppearanceManager.shared.appSecondaryTintColor
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
        return pageNameLabel
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
            createDate.textColor = AppAppearanceManager.shared.appSecondaryTintColor
            return createDate
        }()

        createDateView.addArrangedSubview(createDate)
        return createDateView
    }()
    private let createDateLabel: UILabel = {
        let createDateLabel = UILabel()
        createDateLabel.font = .systemFont(ofSize: 16, weight: .regular)
        return createDateLabel
    }()

    private let removeButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 0, bottom: 18, trailing: 0)
        buttonConfiguration.baseBackgroundColor = .systemPink

        var titleAttr = AttributedString.init("Remove")
        titleAttr.font = .systemFont(ofSize: 18, weight: .regular)

        buttonConfiguration.attributedTitle = titleAttr

        return UIButton(configuration: buttonConfiguration)
    }()
    private var informationString: UILabel = {
        let informationString = UILabel()
        informationString.numberOfLines = 0
        informationString.textColor = .black
        return informationString
    }()

    private var itemID: UUID!
    private var itemName: String!
    private var itemCreationDate: Date!

    var removeButtonPublisher: AnyPublisher<UUID?, Never> {
        removeButton.throttleTapPublisher()
            .map { [weak self] _ in
                self?.dismiss()
                return self?.itemID
            }
            .eraseToAnyPublisher()
    }

    var attrString = NSMutableAttributedString()

    init(itemID: UUID, itemName: String, itemCreationDate: Date) {
        self.itemID = itemID
        self.itemName = itemName
        self.itemCreationDate = itemCreationDate
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func popupViewDetailConfigure() {
        pageNameLabel.text = itemName
        createDateLabel.text = itemCreationDate.formattedDate

        titleView.addArrangedSubview(titleIconView)
        titleView.addArrangedSubview(informationTitleLabel)
        alertContainer.addArrangedSubview(titleView)

        pageNameStackView.addArrangedSubview(pageNameLabel)

        pageNameView.addArrangedSubview(pageNameStackView)
        alertContainer.addArrangedSubview(pageNameView)

        createDateView.addArrangedSubview(createDateLabel)
        alertContainer.addArrangedSubview(createDateView)

        alertContainer.addArrangedSubview(informationString)

        alertContainer.addArrangedSubview(removeButton)
        applyColor()
    }

    func setInfoAttrString() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 0
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left

        attrString.addAttribute(
            .paragraphStyle,
            value: paragraphStyle,
            range: NSRange(location: 0, length: attrString.length)
        )

        informationString.attributedText = attrString
    }

    override func applyColor(_ colorManager: any AppAppearanceManagerType = AppAppearanceManager.shared) {
        super.applyColor()
        informationString.textColor = colorManager.appTintColor
        pageNameLabel.textColor = colorManager.appTintColor
        createDateLabel.textColor = colorManager.appTintColor
    }
}
