import Combine
import UIKit

final class TextEditorComponentView: PageComponentView<UITextView, TextEditorComponent>, UITextViewDelegate {

    static let identifierForUseCollectionView: String = "TextEditorComponentView"
    private var snapshotInputActionSubject: PassthroughSubject<ComponentSnapshotViewModelInput, Never>?
    private var detailAssignSubject = PassthroughSubject<String, Never>()

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

    deinit { print("deinit TextEditorComponentView") }

    override func setupUI() {
        componentContentView = UITextView(usingTextLayoutManager: false)
        componentContentView.textContainerInset = .init(top: 0, left: 0, bottom: 0, right: 0)
        componentContentView.autocorrectionType = .no
        componentContentView.spellCheckingType = .no
        componentContentView.autocapitalizationType = .none
        componentContentView.backgroundColor = .systemGray6
        componentContentView.textColor = .label
        componentContentView.font = .systemFont(ofSize: 15)
        componentContentView.translatesAutoresizingMaskIntoConstraints = false
        componentContentView.layer.cornerRadius = 10
        componentContentView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        componentContentView.accessibilityIdentifier = "TextEditorComponentTextView"
        componentContentView.delegate = self

        super.setupUI()

        toolBarView.backgroundColor = UIColor(named: "TextEditorComponentToolbarColor")

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
        component: TextEditorComponent,
        input subject: PassthroughSubject<MemoPageViewInput, Never>,
        isReadOnly: Bool
    ) {
        super.configure(component: component, input: subject, isReadOnly: isReadOnly)

        componentContentView.text = component.detail

        if isReadOnly {
            componentContentView.isEditable = false
            snapshotButton.removeFromSuperview()
            captureButton.removeFromSuperview()
        } else {
            component
                .assignDetail(subject: detailAssignSubject)
                .store(in: &subscriptions)

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

            captureButton.isEnabled = !component.detail.isEmpty

            snapshotButton.throttleTapPublisher()
                .sink { [weak self] _ in
                    guard let self else { return }
                    pageInputActionSubject?.send(.tappedSnapshotButton(componentID))
                }
                .store(in: &subscriptions)
        }

        if component.isMinimumHeight {
            componentContentView.alpha = 0
        }
    }

    func configure(
        snapshotID: UUID,
        snapshotDetail: String,
        title: String,
        createDate: Date,
        input subject: PassthroughSubject<ComponentSnapshotViewModelInput, Never>
    ) {
        snapshotInputActionSubject = subject

        creationDateLabel.text = "created at \(createDate.formattedDate)"
        titleLabel.text = title
        componentContentView.text = snapshotDetail

        let minimizeRatio = (UIView.screenWidth - 80) / (UIView.screenWidth - 40)
        componentContentView.font = .systemFont(ofSize: 16 * minimizeRatio)

        subscriptions.removeAll()

        redCircleView.throttleUIViewTapGesturePublisher()
            .sink { _ in self.snapshotInputActionSubject?.send(.removeSnapshot(snapshotID)) }
            .store(in: &subscriptions)

        yellowCircleView.backgroundColor = .systemGray5
        greenCircleView.backgroundColor = .systemGray5

        componentContentView.isEditable = false
        pencilButton.removeFromSuperview()
        captureButton.removeFromSuperview()
        snapshotButton.removeFromSuperview()
    }

    func textViewDidChange(_ textView: UITextView) {
        detailAssignSubject.send(textView.text)
        captureButton.isEnabled = !textView.text.isEmpty
    }

    override func setMinimizeState(_ isMinimize: Bool) {
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.componentContentView.alpha = isMinimize ? 0 : 1
            }
        )
    }
}
