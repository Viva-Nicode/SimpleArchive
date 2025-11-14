import Combine
import UIKit

final class TableComponentView: PageComponentView<TableComponentContentView, TableComponent>,
    CaptureableComponentView
{

    static let reuseTableComponentIdentifier: String = "reuseTableComponentIdentifier"
    private var snapshotInputActionSubject: PassthroughSubject<ComponentSnapshotViewModelInput, Never>?
    var snapshotCapturePopupView: SnapshotCapturePopupView?

    private let snapShotView: UIStackView = {
        let snapShotView = UIStackView()
        snapShotView.axis = .horizontal
        snapShotView.alignment = .center
        snapShotView.spacing = 8
        snapShotView.translatesAutoresizingMaskIntoConstraints = false
        return snapShotView
    }()
    private let captureButton: UIButton = {
        let snapshotButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let snapshowUIImage = UIImage(systemName: "arrow.down.document.fill", withConfiguration: config)
        snapshotButton.setImage(snapshowUIImage, for: .normal)
        snapshotButton.tintColor = UIColor(named: "MyGray")
        return snapshotButton
    }()
    private let snapshotButton: UIButton = {
        let snapshotButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let snapshowUIImage = UIImage(systemName: "square.3.layers.3d.down.right", withConfiguration: config)
        snapshotButton.setImage(snapshowUIImage, for: .normal)
        snapshotButton.tintColor = UIColor(named: "MyGray")
        return snapshotButton
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("deinit TableComponentView") }

    override func setupUI() {
        componentContentView = TableComponentContentView()
        componentContentView.translatesAutoresizingMaskIntoConstraints = false
        componentContentView.layer.cornerRadius = 10
        componentContentView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        componentContentView.backgroundColor = .systemGray6

        super.setupUI()

        toolBarView.backgroundColor = UIColor(named: "TableComponentToolbarColor")

        snapShotView.addArrangedSubview(captureButton)
        snapShotView.addArrangedSubview(snapshotButton)
        toolBarView.addSubview(snapShotView)
    }

    override func prepareForReuse() {
        componentContentView.prepareForReuse()
    }

    override func setupConstraints() {
        super.setupConstraints()
        snapShotView.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor).isActive = true
        snapShotView.trailingAnchor.constraint(equalTo: toolBarView.trailingAnchor, constant: -10).isActive = true
    }

    // 페이지 뷰 전용 configure
    override func configure(
        component: TableComponent,
        input subject: PassthroughSubject<MemoPageViewInput, Never>
    ) {

        super.configure(component: component, input: subject)

        componentContentView.configure(
            content: component.componentDetail,
            dispatcher: MemoPageTableComponentActionDispatcher(subject: subject),
            isMinimum: component.isMinimumHeight,
            componentID: componentID
        )

        captureButton.throttleTapPublisher()
            .flatMap { [weak self] _ -> AnyPublisher<String, Never> in
                guard let self else { return Empty().eraseToAnyPublisher() }

                let popup = SnapshotCapturePopupView()
                self.snapshotCapturePopupView = popup
                popup.show()

                return popup.captureButtonPublisher
            }
            .sink { [weak self] snapshotDescription in
                guard let self else { return }
                self.pageInputActionSubject?.send(.willCaptureComponent(componentID, snapshotDescription))
            }
            .store(in: &subscriptions)

        snapshotButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                pageInputActionSubject?.send(.willNavigateSnapshotView(componentID))
            }
            .store(in: &subscriptions)
    }

    // 스냅샷 뷰 전용 configure
    func configure(
        snapshotID: UUID,
        snapshotDetail: TableComponentContent,
        title: String,
        createDate: Date,
        input subject: PassthroughSubject<ComponentSnapshotViewModelInput, Never>
    ) {
        snapshotInputActionSubject = subject
        pageInputActionSubject = PassthroughSubject<MemoPageViewInput, Never>()

        componentContentView.configure(content: snapshotDetail)

        creationDateLabel.text = "created at \(createDate.formattedDate)"
        titleLabel.text = title

        subscriptions.removeAll()

        redCircleView.throttleUIViewTapGesturePublisher()
            .sink { _ in
                self.snapshotInputActionSubject?.send(.removeSnapshot(snapshotID))
            }
            .store(in: &subscriptions)

        yellowCircleView.backgroundColor = .systemGray5
        greenCircleView.backgroundColor = .systemGray5

        pencilButton.removeFromSuperview()
        captureButton.removeFromSuperview()
        snapshotButton.removeFromSuperview()
    }

    override func setMinimizeState(_ isMinimize: Bool) {
        componentContentView.minimizeContentView(isMinimize)
    }
}
