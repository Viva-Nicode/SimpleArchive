import Combine
import UIKit

final class TextEditorComponentView:
    PageComponentView<UITextView, TextEditorComponent>, UITextViewDelegate, CaptureableComponentView
{
    static let identifierForUseCollectionView: String = "TextEditorComponentView"

    private let actionDispatcher = TextEditorComponentActionDispatcher()
    private var textEditorComponentViewModel: TextEditorComponentViewModel?
    weak var snapshotCapturePopupView: SnapshotCapturePopupView?

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

    override func prepareForReuse() {
        super.prepareForReuse()
        textEditorComponentViewModel?.clearSubscriptions()
        actionDispatcher.clearSubscriptions()
    }

    deinit {
        print("deinit TextEditorComponentView")
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

    private func setupActions() {
        redCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                contentView.endEditing(true)
                actionDispatcher.removePageComponent()
            }
            .store(in: &subscriptions)

        yellowCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                contentView.endEditing(true)
                actionDispatcher.foldPageComponent()
            }
            .store(in: &subscriptions)

        greenCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                if !isFolded {
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
                actionDispatcher.maximizePageComponent()
            }
            .store(in: &subscriptions)

        titleLabel.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                let popupView = ChangeComponentNamePopupView(componentTitle: componentTitle) { newName in
                    self.actionDispatcher.renamePageComponent(newName: newName)
                }
                popupView.show()
            }
            .store(in: &subscriptions)

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
                actionDispatcher.captureTextEditorComponentManual(snapshotDescription: snapshotDescription)
            }
            .store(in: &subscriptions)

        snapshotButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                actionDispatcher.navigateToSnapshotView()
            }
            .store(in: &subscriptions)
    }

    func configureTextComponentForMemoPageView(
        component: TextEditorComponent,
        viewModel: TextEditorComponentViewModel
    ) {
        componentID = component.id
        componentTitle = component.title
        isFolded = component.isMinimumHeight
        creationDateLabel.text = "created at \(component.creationDate.formattedDate)"

        componentContentView.text = component.componentContents
        captureButton.isEnabled = !component.componentContents.isEmpty

        if component.isMinimumHeight { componentContentView.alpha = 0 }

        textEditorComponentViewModel = viewModel

        actionDispatcher.bindToViewModel(
            viewModel: viewModel,
            updateUIWithEvent: UIupdateEventHandler)

        setupActions()
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

    private func UIupdateEventHandler(_ event: TextEditorComponentViewModel.Event) {
        switch event {
            // MARK: - Contents
            case .didUndoTextComponentContents(let undidText):
                componentContentView.text = undidText

            // MARK: - Capture & Snapshot
            case .didCaptureWithManual:
                completeSnapshotCapturePopupView()

            case .didRestoreComponentContents(let contents):
                UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: []) {
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) { [weak self] in
                        guard let self else { return }
                        componentContentView.alpha = 0
                    }

                    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.0) { [weak self] in
                        guard let self else { return }
                        componentContentView.text = contents
                    }

                    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) { [weak self] in
                        guard let self else { return }
                        componentContentView.alpha = 1
                    }
                }

            case .didNavigateSnapshotView(let viewModel):
                let snapshotView = ComponentSnapshotViewController(viewModel: viewModel)

                snapshotView.hasRestorePublisher
                    .sink { [weak self] _ in
                        guard let self else { return }
                        actionDispatcher.resotreComponentContents()
                    }
                    .store(in: &subscriptions)

                parentViewController?.navigationController?.pushViewController(snapshotView, animated: true)

            // MARK: - State
            case .didRenameComponent(let newName):
                componentTitle = newName

            case .didToggleFoldingComponent(let isMinimized):
                isFolded = isMinimized
                if let pageComponentCollectionView = collectionView {

                    if isMinimized {
                        setMinimizeState(isMinimized)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            UIView.animate(withDuration: 0.3) {
                                pageComponentCollectionView.collectionViewLayout.invalidateLayout()
                            }
                        }
                    } else {
                        pageComponentCollectionView.performBatchUpdates {
                            pageComponentCollectionView.collectionViewLayout.invalidateLayout()
                        } completion: { _ in
                            UIView.animate(withDuration: 0.3) {
                                self.setMinimizeState(isMinimized)
                            }
                        }
                    }
                }

            case .didRemovePageComponent:
                if let pageComponentCollectionView = collectionView {
                    if let targetComponentView = collectionView?.visibleCells
                        .compactMap({ $0 as? Self })
                        .first(where: { $0.componentID == self.componentID }),
                        let targetIndexPath = pageComponentCollectionView.indexPath(for: targetComponentView)
                    {
                        pageComponentCollectionView.deleteItems(at: [targetIndexPath])
                    }
                }

            case .didMaximizePageComponent:
                if let memoPageViewController = parentViewController as? MemoPageViewController {
                    memoPageViewController.selectedPageComponentCell = self
                    memoPageViewController.pageComponentContentViewRect = componentContentView.convert(
                        componentContentView.bounds,
                        to: memoPageViewController.view.window!)

                    let fullscreenComponentViewController = FullScreenTextEditorComponentViewController(
                        textEditorComponentModel: TextEditorComponent(),
                        componentTextView: componentContentView
                    )
                    fullscreenComponentViewController.modalPresentationStyle = .fullScreen
                    fullscreenComponentViewController.transitioningDelegate = memoPageViewController

                    memoPageViewController.present(fullscreenComponentViewController, animated: true)
                }
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        actionDispatcher.saveTextEditorComponentContentsChanged(contents: textView.text)
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
