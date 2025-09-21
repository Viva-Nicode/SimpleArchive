import Combine
import UIKit

class ComponentFullScreenView<ContentViewType>: UIViewController, ComponentFullScreenViewType
where ContentViewType: UIView {

    var subscriptions = Set<AnyCancellable>()

    func getView() -> UIView! { self.view }

    func getContentView() -> ContentViewType { componentContentView }

    var toolbarColor: UIColor? { nil }

    var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.backgroundColor = .systemBackground
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    var toolBarView: UIView = {
        let uiview = UIView()
        uiview.translatesAutoresizingMaskIntoConstraints = false
        uiview.isUserInteractionEnabled = true
        return uiview
    }()
    var componentContentViewContainer: UIView = {
        let textViewContainer = UIView()
        textViewContainer.backgroundColor = .systemGray6
        return textViewContainer
    }()
    var componentContentView: ContentViewType!

    // MARK: - Circle Stack View
    let circleStackView: UIStackView = {
        let circleStackView = UIStackView()
        circleStackView.axis = .horizontal
        circleStackView.spacing = 10
        circleStackView.alignment = .center
        circleStackView.translatesAutoresizingMaskIntoConstraints = false
        return circleStackView
    }()
    var redCircleView: UIView = {
        let circleView = UIView()
        circleView.backgroundColor = .systemGray5
        circleView.layer.cornerRadius = 9
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return circleView
    }()
    var yellowCircleView: UIView = {
        let circleView = UIView()
        circleView.backgroundColor = .systemGray5
        circleView.layer.cornerRadius = 9
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return circleView
    }()
    var greenCircleView: UIView = {
        let circleView = UIView()
        circleView.backgroundColor = UIColor(red: 0.16, green: 0.79, blue: 0.19, alpha: 1)
        circleView.layer.cornerRadius = 9
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return circleView
    }()

    // MARK: - Title Stack View
    let titleStackView: UIStackView = {
        let titleStackView = UIStackView()
        titleStackView.axis = .horizontal
        titleStackView.alignment = .center
        titleStackView.spacing = 2
        titleStackView.translatesAutoresizingMaskIntoConstraints = false
        return titleStackView
    }()
    var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        return titleLabel
    }()
    var componentInformationView: UIStackView = {
        let componentInformationView = UIStackView()
        componentInformationView.axis = .vertical
        componentInformationView.backgroundColor = .systemGray6
        componentInformationView.spacing = 10
        componentInformationView.alignment = .center
        componentInformationView.isLayoutMarginsRelativeArrangement = true
        componentInformationView.translatesAutoresizingMaskIntoConstraints = false
        componentInformationView.layoutMargins = .init(top: 5, left: 10, bottom: 5, right: 10)
        return componentInformationView
    }()
    var creationDateLabel: UILabel = {
        let creationDate = UILabel()
        creationDate.textColor = .label
        creationDate.font = UIFont.systemFont(ofSize: 14, weight: .thin)
        return creationDate
    }()

    init(componentContentView: ContentViewType) {
        super.init(nibName: nil, bundle: nil)
        self.componentContentView = componentContentView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(containerStackView)

        containerStackView.addArrangedSubview(toolBarView)
        componentInformationView.addArrangedSubview(creationDateLabel)
        containerStackView.addArrangedSubview(componentInformationView)
        containerStackView.addArrangedSubview(componentContentView)
        containerStackView.addArrangedSubview(componentContentViewContainer)

        componentContentViewContainer.addSubview(componentContentView)

        circleStackView.addArrangedSubview(redCircleView)
        circleStackView.addArrangedSubview(yellowCircleView)
        circleStackView.addArrangedSubview(greenCircleView)

        toolBarView.addSubview(circleStackView)

        titleStackView.addArrangedSubview(titleLabel)
        toolBarView.addSubview(titleStackView)
    }

    func setupConstraints() {
        containerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        containerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        containerStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        toolBarView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        toolBarView.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor).isActive = true
        toolBarView.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor).isActive = true

        circleStackView.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor).isActive = true
        circleStackView.leadingAnchor.constraint(equalTo: toolBarView.leadingAnchor, constant: 10).isActive = true

        titleStackView.centerXAnchor.constraint(equalTo: toolBarView.centerXAnchor).isActive = true
        titleStackView.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor).isActive = true

        titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 150).isActive = true

        componentInformationView.heightAnchor.constraint(equalToConstant: 30).isActive = true

        componentContentViewContainer.topAnchor.constraint(equalTo: componentInformationView.bottomAnchor).isActive =
            true

        componentContentView
            .leadingAnchor
            .constraint(equalTo: componentContentViewContainer.leadingAnchor, constant: 20)
            .isActive = true
        componentContentView
            .trailingAnchor
            .constraint(equalTo: componentContentViewContainer.trailingAnchor, constant: -20)
            .isActive = true
        componentContentView
            .topAnchor
            .constraint(equalTo: componentContentViewContainer.topAnchor).isActive = true
        componentContentView
            .bottomAnchor
            .constraint(equalTo: componentContentViewContainer.bottomAnchor)
            .isActive = true
    }
}
