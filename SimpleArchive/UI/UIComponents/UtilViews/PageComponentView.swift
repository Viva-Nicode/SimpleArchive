import Combine
import UIKit

protocol PageComponentViewType: UIView {
    associatedtype T: UIView

    func getContentView() -> T
    var toolBarView: UIView { get set }
    var redCircleView: CircleButton { get set }
    var yellowCircleView: CircleButton { get set }
    var greenCircleView: CircleButton { get set }
    var titleLabel: UILabel { get set }
    var creationDateLabel: UILabel { get set }
    var componentInformationView: UIStackView { get set }

    func setMinimizeState(_ isMinimize: Bool)
    func detachContentsSnapshotViewDuringDismissFullScreenAnimation()
    func attachContentsSnapshotViewDuringPresentingFullScreenAnimation()
    func presentFullScreenPageComponentView()
    func freedReferences()
}

class PageComponentView<ComponentContentType, PageComponentType>: UICollectionViewCell, PageComponentViewType,
    BaseColorUpdatable
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
        toolBarView.layer.cornerRadius = 20
        toolBarView.layer.masksToBounds = false
        toolBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        toolBarView.isUserInteractionEnabled = true
        return toolBarView
    }()
    var circleStackView: UIStackView = {
        let circleStackView = UIStackView()
        circleStackView.axis = .horizontal
        circleStackView.spacing = 0
        circleStackView.alignment = .center
        circleStackView.translatesAutoresizingMaskIntoConstraints = false
        return circleStackView
    }()

    var redCircleView = CircleButton(.red)
    var yellowCircleView = CircleButton(.yellow)
    var greenCircleView = CircleButton(.green)
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
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOffset = .init(width: -1, height: 1)
        contentView.layer.shadowOpacity = 0.15
        contentView.layer.shadowRadius = 4

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
            circleStackView.leadingAnchor.constraint(equalTo: toolBarView.leadingAnchor, constant: 5),

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
        if isMinimize {
            componentInformationView.layer.cornerRadius = 20
            componentInformationView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        } else {
            componentInformationView.layer.cornerRadius = 0
        }
    }

    func presentFullScreenPageComponentView() {
        fatalError("thie method must override in subclass.")
    }
	
	func applyColor(_ colorManager: any AppAppearanceManagerType = AppAppearanceManager.shared) {
		componentInformationView.backgroundColor = colorManager.appBaseColor
		creationDateLabel.textColor = colorManager.appTintColor
		titleLabel.textColor = colorManager.appTintColor
	}
}

final class CircleButton: UIControl {
    private(set) var circleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 9
        view.isUserInteractionEnabled = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    enum CircleColor {
        case red
        case green
        case yellow
        case gray

        var color: UIColor {
            switch self {
                case .red: UIColor(red: 0.99, green: 0.27, blue: 0.27, alpha: 1)
                case .yellow: UIColor(red: 1.0, green: 0.69, blue: 0.14, alpha: 1)
                case .green: UIColor(red: 0.16, green: 0.79, blue: 0.19, alpha: 1)
                case .gray: .gray
            }
        }
    }

    func setCircleColor(_ color: CircleColor) {
        circleView.backgroundColor = color.color
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        addSubview(circleView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 30),
            heightAnchor.constraint(equalToConstant: 35),

            circleView.widthAnchor.constraint(equalToConstant: 18),
            circleView.heightAnchor.constraint(equalToConstant: 18),
            circleView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    convenience init(_ color: CircleColor) {
        self.init(frame: .zero)
        circleView.backgroundColor = color.color
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
