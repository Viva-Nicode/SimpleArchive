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
        titleLabel.textColor = .black
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
    private let removeButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 18, leading: 0, bottom: 18, trailing: 0)
        buttonConfiguration.baseBackgroundColor = .systemPink

        var titleAttr = AttributedString.init("Remove")
        titleAttr.font = .systemFont(ofSize: 18, weight: .regular)

        buttonConfiguration.attributedTitle = titleAttr

        return UIButton(configuration: buttonConfiguration)
    }()

    private let pageInformation: PageInformation

    var removeButtonPublisher: AnyPublisher<UUID?, Never> {
        removeButton.throttleTapPublisher()
            .map { [weak self] _ in
                self?.dismiss()
                return self?.pageInformation.id
            }
            .eraseToAnyPublisher()
    }

    init(pageInformation: PageInformation) {
        self.pageInformation = pageInformation
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("deinit RemovedFileInformationPopupView") }

    override func popupViewDetailConfigure() {
        pageNameLabel.text = pageInformation.name
        filePathLabel.text = pageInformation.filePath
        createDateLabel.text = pageInformation.created.formattedDate
        containedFileCountLabel.text = "Contains \(pageInformation.containedComponentCount) notes"

        titleView.addArrangedSubview(titleIconView)
        titleView.addArrangedSubview(informationTitleLabel)
        alertContainer.addArrangedSubview(titleView)

        pageNameStackView.addArrangedSubview(pageNameLabel)

        pageNameView.addArrangedSubview(pageNameStackView)
        alertContainer.addArrangedSubview(pageNameView)

        filePathView.addArrangedSubview(filePathLabel)
        alertContainer.addArrangedSubview(filePathView)

        createDateView.addArrangedSubview(createDateLabel)
        alertContainer.addArrangedSubview(createDateView)

        alertContainer.addArrangedSubview(containedFileCountLabel)
        alertContainer.addArrangedSubview(removeButton)
    }
}
