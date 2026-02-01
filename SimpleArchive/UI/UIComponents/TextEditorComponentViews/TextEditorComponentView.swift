import Combine
import UIKit

final class TextEditorComponentView:
    PageComponentView<UITextView, TextEditorComponent>, UITextViewDelegate, CaptureableComponentView
{
    static let identifierForUseCollectionView: String = "TextEditorComponentView"

    private let actionDispatcher = TextEditorComponentActionDispatcher()
    private var textEditorComponentViewModel: TextEditorComponentViewModel?
    var snapshotCapturePopupView: SnapshotCapturePopupView?

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
    private let undoButton: UIButton = {
        let snapshotButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let snapshowUIImage = UIImage(systemName: "arrowshape.turn.up.backward.fill", withConfiguration: config)
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
        componentContentView.textContainerInset = .init(top: 10, left: 0, bottom: 0, right: 0)
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

        snapShotView.addArrangedSubview(undoButton)
        snapShotView.addArrangedSubview(captureButton)
        snapShotView.addArrangedSubview(snapshotButton)
        toolBarView.addSubview(snapShotView)
    }

    override func setupConstraints() {
        super.setupConstraints()
        snapShotView.centerYAnchor.constraint(equalTo: toolBarView.centerYAnchor).isActive = true
        snapShotView.trailingAnchor.constraint(equalTo: toolBarView.trailingAnchor, constant: -10).isActive = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        textEditorComponentViewModel?.clearSubscriptions()
        actionDispatcher.clearSubscriptions()
    }

    func configureTextComponentForMemoPageView(
        component: TextEditorComponent,
        viewModel: TextEditorComponentViewModel,
        input subject: PassthroughSubject<MemoPageViewInput, Never>
    ) {
        super.configure(component: component, input: subject)

        textEditorComponentViewModel = viewModel

        actionDispatcher.bindToViewModel(viewModel: viewModel) { [weak self] event in
            guard let self else { return }
            switch event {
                case .didUndoTextComponentContents(let undidText):
                    componentContentView.text = undidText
            }
        }

        componentContentView.text = component.componentContents

        undoButton.throttleTapPublisher(interval: 0.25)
            .sink { [weak self] _ in
                self?.actionDispatcher.undoTextEditorComponentContents()
            }
            .store(in: &subscriptions)

        captureButton.throttleTapPublisher()
            .flatMap { [weak self] _ -> AnyPublisher<String, Never> in
                guard let self else { return Empty().eraseToAnyPublisher() }

                let snapshotCapturePopupView = SnapshotCapturePopupView()
                self.snapshotCapturePopupView = snapshotCapturePopupView
                snapshotCapturePopupView.show()

                return snapshotCapturePopupView.captureButtonPublisher
            }
            .sink { [weak self] snapshotDescription in
                guard let self else { return }
                self.pageInputActionSubject?.send(.willCaptureComponent(componentID, snapshotDescription))
            }
            .store(in: &subscriptions)

        captureButton.isEnabled = !component.componentContents.isEmpty

        snapshotButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                pageInputActionSubject?.send(.willNavigateSnapshotView(componentID))
            }
            .store(in: &subscriptions)

        if component.isMinimumHeight { componentContentView.alpha = 0 }
    }

    func configureTextComponentForSnapshotView(
        snapshotID: UUID,
        snapshotDetail: String,
        input subject: PassthroughSubject<ComponentSnapshotViewModelInput, Never>
    ) {
        snapshotInputActionSubject = subject

        componentInformationView.removeFromSuperview()

        componentContentView.constraints
            .filter { $0.firstAnchor == componentContentView.topAnchor }
            .forEach { $0.isActive = false }

        componentContentView.topAnchor.constraint(equalTo: toolBarView.bottomAnchor).isActive = true

        componentContentView.text = snapshotDetail

        let minimizeRatio = (UIView.screenWidth - 80) / (UIView.screenWidth - 40)
        componentContentView.font = .systemFont(ofSize: 16 * minimizeRatio)

        redCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                self?.snapshotInputActionSubject?.send(.willRemoveSnapshot(snapshotID))
            }
            .store(in: &subscriptions)

        yellowCircleView.backgroundColor = .systemGray5
        greenCircleView.backgroundColor = .systemGray5

        componentContentView.isEditable = false
        undoButton.removeFromSuperview()
        captureButton.removeFromSuperview()
        snapshotButton.removeFromSuperview()
    }

    func textViewDidChange(_ textView: UITextView) {
        actionDispatcher.saveTextEditorComponentChanged(contents: textView.text)
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
