import Combine
import UIKit

final class TableComponentView: PageComponentView<TableComponentContentView, TableComponent> {

    static let reuseTableComponentIdentifier: String = "reuseTableComponentIdentifier"
    private var snapshotInputActionSubject: PassthroughSubject<ComponentSnapshotViewModelInput, Never>?

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

    override func setupConstraints() {
        super.setupConstraints()
        snapShotView.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor).isActive = true
        snapShotView.trailingAnchor.constraint(equalTo: toolBarView.trailingAnchor, constant: -10).isActive = true
    }

    override func configure(
        component: TableComponent,
        input subject: PassthroughSubject<MemoPageViewInput, Never>,
        isReadOnly: Bool
    ) {
        super.configure(component: component, input: subject, isReadOnly: isReadOnly)

        componentContentView.configure(
            content: component.componentDetail,
            pageInputActionSubject: pageInputActionSubject,
            componentID: componentID
        )

        if isReadOnly {
            snapshotButton.removeFromSuperview()
            captureButton.removeFromSuperview()
        } else {
            captureButton.throttleTapPublisher()
                .sink { [weak self] _ in
                    guard let self else { return }
                    let snapshotCapturePopupView = SnapshotCapturePopupView { snapshotDescription in
                        self.pageInputActionSubject?
                            .send(.tappedCaptureButton(self.componentID, snapshotDescription))
                    }
                    snapshotCapturePopupView.show()
                }
                .store(in: &subscriptions)

            snapshotButton.throttleTapPublisher()
                .sink { [weak self] _ in
                    guard let self else { return }
                    pageInputActionSubject?.send(.tappedSnapshotButton(componentID))
                }
                .store(in: &subscriptions)
        }
    }

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
}
