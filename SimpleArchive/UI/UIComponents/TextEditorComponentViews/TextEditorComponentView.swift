import Combine
import UIKit

final class TextEditorComponentView: PageComponentView<UITextView, TextEditorComponent> {
    static let reuseIdentifier = "TextEditorComponentView"

    private let textEditorActionDispatcher = TextEditorComponentActionDispatcher()
    private var componentSnapshotActionDispatcher: PassthroughSubject<ComponentSnapshotViewModel.Action, Never>?

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
    private let undoButton: UIButton = {
        let snapshotButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let snapshowUIImage = UIImage(systemName: "arrowshape.turn.up.backward.fill", withConfiguration: config)
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

    override func prepareForReuse() {
        super.prepareForReuse()
        textEditorActionDispatcher.clearSubscriptions()
    }

    override func freedReferences() {
        super.freedReferences()
        textEditorActionDispatcher.clearSubscriptions()
    }

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

    func configureTextComponentForMemoPageView(
        component: TextEditorComponent,
        viewModel: any PageComponentViewModelType,
        pageActionDispatcher: PassthroughSubject<MemoPageViewInput, Never>
    ) {
        super
            .configure(
                componentID: component.id,
                componentTitle: component.title,
                componentCreateAt: component.creationDate,
                pageActionDispatcher: pageActionDispatcher)

        componentContentView.text = component.componentContents
        captureButton.isEnabled = !component.componentContents.isEmpty

        componentContentView.alpha = component.isMinimumHeight ? 0 : 1

        textEditorActionDispatcher.bindToViewModel(viewModel: viewModel, updateUIWithEvent: UIupdateEventHandler)

        captureButton.throttleTapPublisher()
            .flatMap { [weak self] _ -> AnyPublisher<String, Never> in
                guard let self,
                    let memoPageVC = parentViewController as? MemoPageViewController
                else { return Empty().eraseToAnyPublisher() }

                let snapshotCapturePopupView = SnapshotCapturePopupView()
                memoPageVC.snapshotCapturePopupView = snapshotCapturePopupView
                snapshotCapturePopupView.show()

                return snapshotCapturePopupView.captureButtonPublisher
            }
            .sink { [weak self] snapshotDescription in
                guard let self else { return }
                textEditorActionDispatcher.captureComponentManual(description: snapshotDescription)
            }
            .store(in: &subscriptions)

        snapshotButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                textEditorActionDispatcher.navigateComponentSnapshotView()
            }
            .store(in: &subscriptions)

        undoButton.throttleTapPublisher(interval: 0.25)
            .sink { [weak self] _ in
                guard let self else { return }
                textEditorActionDispatcher.undoTextEditorComponentContents()
            }
            .store(in: &subscriptions)
    }

    func configureTextComponentForSnapshotView(
        snapshotID: UUID,
        snapshotDetail: String,
        snapshotDispatcher: PassthroughSubject<ComponentSnapshotViewModel.Action, Never>
    ) {
        self.componentSnapshotActionDispatcher = snapshotDispatcher
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
                guard let self else { return }
                componentSnapshotActionDispatcher?.send(.willRemoveSnapshot(snapshotID))
            }
            .store(in: &subscriptions)

        yellowCircleView.backgroundColor = .systemGray5
        greenCircleView.backgroundColor = .systemGray5

        componentContentView.isEditable = false

        undoButton.removeFromSuperview()
        captureButton.removeFromSuperview()
        snapshotButton.removeFromSuperview()
    }

    override func setMinimizeState(_ isMinimize: Bool) {
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] in
                self?.componentContentView.alpha = isMinimize ? 0 : 1
            }
        )
    }

    override func reloadComponentContentsWhenRestoreUsingSnapshot(contents: Codable) {
        if let textContents = contents as? String {
            UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: []) {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2) {
                    self.collectionView?.collectionViewLayout.invalidateLayout()
                }
                UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.4) {
                    self.componentContentView.alpha = 0
                }
            } completion: { _ in
                self.componentContentView.text = textContents
                UIView.animate(withDuration: 0.2) {
                    self.componentContentView.alpha = 1
                }
            }
        }
    }

    override func presentFullScreenPageComponentView() {
        if let memoPageViewController = parentViewController as? MemoPageViewController {
            memoPageViewController.fullscreenTargetComponentContentsViewFrame = componentContentView.convert(
                componentContentView.bounds,
                to: memoPageViewController.view.window!)

            let fullscreenComponentViewController = FullScreenTextEditorComponentViewController(
                title: titleLabel.text!,
                createDate: createdAt,
                componentTextView: componentContentView
            )
            fullscreenComponentViewController.modalPresentationStyle = .fullScreen
            fullscreenComponentViewController.transitioningDelegate = memoPageViewController

            memoPageViewController.present(fullscreenComponentViewController, animated: true)
        }
    }
}

// MARK: - Event Handler
extension TextEditorComponentView {
    private func textEditorComponentEventHandler(_ event: TextEditorComponentViewModel.Event) {
        switch event {
            case .didUndoTextComponentContents(let undidText):
                componentContentView.text = undidText
        }
    }

    private func UIupdateEventHandler(_ event: TextEditorComponentViewModelEvent) {
        switch event {
            case .textEditorComponentEvent(let event):
                textEditorComponentEventHandler(event)

            case .snapshotEvent(let event):
                commonPageEventHandler(event: event)
        }
    }
}

extension TextEditorComponentView: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textEditorActionDispatcher.saveTextEditorComponentContentsChanged(contents: textView.text)
        captureButton.isEnabled = !textView.text.isEmpty
    }
}
