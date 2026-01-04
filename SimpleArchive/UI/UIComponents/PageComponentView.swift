import Combine
import UIKit

protocol PageComponentViewType {
    associatedtype T: UIView

    func getContentView() -> T
    var toolBarView: UIView { get set }
    var redCircleView: UIView { get set }
    var yellowCircleView: UIView { get set }
    var greenCircleView: UIView { get set }
    var titleLabel: UILabel { get set }
    var creationDateLabel: UILabel { get set }
    var componentInformationView: UIStackView { get set }
    func resetupComponentContentViewToDismissFullScreenAnimation()
    func setMinimizeState(_ isMinimize: Bool)
}

class PageComponentView<ComponentContentType, PageComponentType>: UICollectionViewCell, PageComponentViewType
where ComponentContentType: UIView, PageComponentType: PageComponent {

    func getContentView() -> ComponentContentType { self.componentContentView }

    var subscriptions = Set<AnyCancellable>()
    var pageInputActionSubject: PassthroughSubject<MemoPageViewInput, Never>?
    var componentID: UUID!
    var componentContentViewSnapshot: UIView?
    var componentContentView: ComponentContentType!

    deinit { subscriptions.removeAll() }

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
        containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        circleStackView.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor).isActive = true
        circleStackView.leadingAnchor.constraint(equalTo: toolBarView.leadingAnchor, constant: 10).isActive = true

        titleLabel.centerXAnchor.constraint(equalTo: toolBarView.centerXAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor).isActive = true

        titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 130).isActive = true

        toolBarView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        toolBarView.heightAnchor.constraint(equalToConstant: 35).isActive = true
        toolBarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        toolBarView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

        componentInformationView.topAnchor.constraint(equalTo: toolBarView.bottomAnchor).isActive = true
        componentInformationView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        componentInformationView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        componentInformationView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

        componentContentView.topAnchor.constraint(equalTo: componentInformationView.bottomAnchor).isActive = true
        componentContentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        componentContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        componentContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
    }

    func configure(
        component: PageComponentType,
        input subject: PassthroughSubject<MemoPageViewInput, Never>,
    ) {
        pageInputActionSubject = subject
        componentID = component.id
        titleLabel.text = component.title
        creationDateLabel.text = "created at \(component.creationDate.formattedDate)"

        subscriptions.removeAll()

        redCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                contentView.endEditing(true)
                pageInputActionSubject?.send(.willRemoveComponent(componentID))
            }
            .store(in: &subscriptions)

        yellowCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                contentView.endEditing(true)
                pageInputActionSubject?.send(.willToggleComponentSize(componentID))
            }
            .store(in: &subscriptions)

        greenCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                // 컨텐츠 뷰가 깜빡거리는게 싫어서 최대화 애니메이션이 진행되는 동안 컨텐츠 뷰위에 임시로 덧대는 뷰.
                if !component.isMinimumHeight {
                    if let componentTextViewSnapshot = componentContentView.snapshotView(afterScreenUpdates: true) {
                        self.componentContentViewSnapshot = componentTextViewSnapshot
                        componentTextViewSnapshot.translatesAutoresizingMaskIntoConstraints = false
                        containerView.addSubview(componentTextViewSnapshot)
                        componentTextViewSnapshot.topAnchor.constraint(equalTo: componentInformationView.bottomAnchor)
                            .isActive = true
                        componentTextViewSnapshot.leadingAnchor.constraint(equalTo: containerView.leadingAnchor)
                            .isActive = true
                        componentTextViewSnapshot.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
                            .isActive = true
                        componentTextViewSnapshot.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
                            .isActive = true
                    }
                }
                pageInputActionSubject?.send(.willMaximizeComponent(componentID))
            }
            .store(in: &subscriptions)

        titleLabel.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                let popupView = ChangeComponentNamePopupView(
                    componentTitle: component.title
                ) { newTitle in
                    self.pageInputActionSubject?.send(.willChangeComponentName(self.componentID, newTitle))
                    self.titleLabel.text = newTitle
                }
                popupView.show()
            }
            .store(in: &subscriptions)
    }

    func resetupComponentContentViewToDismissFullScreenAnimation() {
        containerView.addSubview(componentContentView)
        componentContentView.topAnchor.constraint(equalTo: componentInformationView.bottomAnchor).isActive = true
        componentContentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        componentContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true
        componentContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true

        componentContentViewSnapshot?.removeFromSuperview()
        componentContentViewSnapshot = nil
    }

    func setMinimizeState(_ isMinimize: Bool) {}
}
