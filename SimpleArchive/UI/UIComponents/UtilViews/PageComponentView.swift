import Combine
import UIKit

protocol PageComponentViewType: UIView {
    associatedtype T: UIView

    func getContentView() -> T
    var toolBarView: UIView { get set }
    var redCircleView: UIView { get set }
    var yellowCircleView: UIView { get set }
    var greenCircleView: UIView { get set }
    var titleLabel: UILabel { get set }
    var creationDateLabel: UILabel { get set }
    var componentInformationView: UIStackView { get set }

    func setMinimizeState(_ isMinimize: Bool)
    func detachContentsSnapshotViewDuringDismissFullScreenAnimation()
    func attachContentsSnapshotViewDuringPresentingFullScreenAnimation()
    func presentFullScreenPageComponentView()
    func freedReferences()
}

class PageComponentView<ComponentContentType, PageComponentType>: UICollectionViewCell, PageComponentViewType
where ComponentContentType: UIView, PageComponentType: PageComponent {

    func getContentView() -> ComponentContentType { self.componentContentView }

    var subscriptions = Set<AnyCancellable>()
    var pageActionDispatcher: PassthroughSubject<MemoPageViewInput, Never>?
    var componentID: UUID!
    var createdAt: Date = Date() {
        didSet {
            creationDateLabel.text = "created at \(createdAt.formattedDate)"
        }
    }

    var snapshotOverlayViewForMaximizationTransition: UIView?
    var componentContentView: ComponentContentType!
    func freedReferences() { subscriptions.removeAll() }

    var containerView: UIView = {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        return containerView
    }()
    var toolBarView: UIView = {
        let toolBarView = UIView()
        toolBarView.layer.cornerRadius = 10
        toolBarView.layer.masksToBounds = false
        toolBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        toolBarView.isUserInteractionEnabled = true
        return toolBarView
    }()
    var circleStackView: UIStackView = {
        let circleStackView = UIStackView()
        circleStackView.axis = .horizontal
        circleStackView.spacing = 10
        circleStackView.alignment = .center
        circleStackView.translatesAutoresizingMaskIntoConstraints = false
        return circleStackView
    }()
    var redCircleView: UIView = {
        let circleView = UIView()
        circleView.backgroundColor = UIColor(red: 0.99, green: 0.27, blue: 0.27, alpha: 1)
        circleView.layer.cornerRadius = 9
        circleView.translatesAutoresizingMaskIntoConstraints = false
        circleView.widthAnchor.constraint(equalToConstant: 18).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: 18).isActive = true
        return circleView
    }()
    var yellowCircleView: UIView = {
        let circleView = UIView()
        circleView.backgroundColor = UIColor(red: 1.0, green: 0.69, blue: 0.14, alpha: 1)
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
    var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 18, weight: .regular)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.isUserInteractionEnabled = true
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
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
        creationDate.font = .systemFont(ofSize: 14, weight: .thin)
        return creationDate
    }()

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    func setupUI() {
        contentView.layer.masksToBounds = false
        contentView.layer.shadowColor = UIColor.gray.cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        contentView.layer.shadowOpacity = 0.7
        contentView.layer.shadowRadius = 4.0

        circleStackView.addArrangedSubview(redCircleView)
        circleStackView.addArrangedSubview(yellowCircleView)
        circleStackView.addArrangedSubview(greenCircleView)
        toolBarView.addSubview(circleStackView)

        toolBarView.addSubview(titleLabel)

        componentInformationView.addArrangedSubview(creationDateLabel)

        containerView.addSubview(toolBarView)
        containerView.addSubview(componentInformationView)
        containerView.addSubview(componentContentView)

        contentView.addSubview(containerView)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            circleStackView.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor),
            circleStackView.leadingAnchor.constraint(equalTo: toolBarView.leadingAnchor, constant: 10),

            titleLabel.centerXAnchor.constraint(equalTo: toolBarView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor),

            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 130),

            toolBarView.topAnchor.constraint(equalTo: containerView.topAnchor),
            toolBarView.heightAnchor.constraint(equalToConstant: 35),
            toolBarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            toolBarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            componentInformationView.topAnchor.constraint(equalTo: toolBarView.bottomAnchor),
            componentInformationView.heightAnchor.constraint(equalToConstant: 30),
            componentInformationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            componentInformationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            componentContentView.topAnchor.constraint(equalTo: componentInformationView.bottomAnchor),
            componentContentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            componentContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            componentContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        subscriptions.removeAll()
    }

    func configure(
        componentID: UUID,
        componentTitle: String,
        componentCreateAt: Date,
        pageActionDispatcher: PassthroughSubject<MemoPageViewInput, Never>,
    ) {
        self.pageActionDispatcher = pageActionDispatcher
        self.componentID = componentID

        titleLabel.text = componentTitle
        createdAt = componentCreateAt

        setupPageComponentCommonActions()
    }

    private func setupPageComponentCommonActions() {
        redCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                contentView.endEditing(true)
                pageActionDispatcher?.send(.willRemovePageComponent(componentID: componentID))
            }
            .store(in: &subscriptions)

        yellowCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                contentView.endEditing(true)
                pageActionDispatcher?.send(.willToggleFoldingComponent(componentID: componentID))

            }
            .store(in: &subscriptions)

        greenCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                pageActionDispatcher?.send(.willMaximizePageComponent(componentID: componentID))
            }
            .store(in: &subscriptions)

        titleLabel.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                let popupView = ChangeComponentNamePopupView(componentTitle: titleLabel.text!) { newName in
                    self.pageActionDispatcher?
                        .send(
                            .willRenameComponent(componentID: self.componentID, newName: newName)
                        )
                }
                popupView.show()
            }
            .store(in: &subscriptions)
    }

    // MARK: - Maximization Animation
    func detachContentsSnapshotViewDuringDismissFullScreenAnimation() {
        containerView.addSubview(componentContentView)
        componentContentView.topAnchor.constraint(equalTo: componentInformationView.bottomAnchor).isActive = true
        componentContentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        componentContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        componentContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true

        snapshotOverlayViewForMaximizationTransition?.removeFromSuperview()
        snapshotOverlayViewForMaximizationTransition = nil
    }

    func attachContentsSnapshotViewDuringPresentingFullScreenAnimation() {
        if let componentTextViewSnapshot = componentContentView.snapshotView(afterScreenUpdates: true) {
            snapshotOverlayViewForMaximizationTransition = componentTextViewSnapshot
            componentTextViewSnapshot.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(componentTextViewSnapshot)
            NSLayoutConstraint.activate([
                componentTextViewSnapshot.topAnchor.constraint(
                    equalTo: componentInformationView.bottomAnchor),
                componentTextViewSnapshot.leadingAnchor.constraint(
                    equalTo: containerView.leadingAnchor),
                componentTextViewSnapshot.trailingAnchor.constraint(
                    equalTo: containerView.trailingAnchor),
                componentTextViewSnapshot.bottomAnchor.constraint(
                    equalTo: containerView.bottomAnchor),
            ])
        }
    }

    func setMinimizeState(_ isMinimize: Bool) {
        fatalError("thie method must override in subclass.")
    }

    func presentFullScreenPageComponentView() {
        fatalError("thie method must override in subclass.")
    }
}
