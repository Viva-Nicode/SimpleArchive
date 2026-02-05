import Combine
import UIKit

final class SingleTextEditorPageViewController: UIViewController, UITextViewDelegate,
    UIScrollViewDelegate, CaptureableComponentView
{
    private let actionDispatcher = TextEditorComponentActionDispatcher()
    private var textEditorComponentViewModel: TextEditorComponentViewModel?

    var subscriptions = Set<AnyCancellable>()
    var snapshotCapturePopupView: SnapshotCapturePopupView?

    private let captureDispatchSemaphore = DispatchSemaphore(value: 1)

    private(set) var headerView: UIView = {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    private(set) var titleLable: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private(set) var createDateLabel: UILabel = {
        let createDateLabel = UILabel()
        createDateLabel.font = .systemFont(ofSize: 15)
        createDateLabel.translatesAutoresizingMaskIntoConstraints = false
        return createDateLabel
    }()
    private(set) var textEditorView: UITextView = {
        let textEditorView = UITextView()
        textEditorView.autocorrectionType = .no
        textEditorView.spellCheckingType = .no
        textEditorView.autocapitalizationType = .none
        textEditorView.keyboardDismissMode = .onDrag
        textEditorView.textColor = .label
        textEditorView.font = .systemFont(ofSize: 15)
        textEditorView.translatesAutoresizingMaskIntoConstraints = false
        return textEditorView
    }()
    private let undoButton: UIButton = {
        let snapshotButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let snapshowUIImage = UIImage(systemName: "arrowshape.turn.up.backward.fill", withConfiguration: config)
        snapshotButton.setImage(snapshowUIImage, for: .normal)
        snapshotButton.translatesAutoresizingMaskIntoConstraints = false
        return snapshotButton
    }()
    private(set) var captureButton: UIButton = {
        let snapshotButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 22)
        let snapshowUIImage = UIImage(systemName: "arrow.down.document.fill", withConfiguration: config)
        snapshotButton.setImage(snapshowUIImage, for: .normal)
        snapshotButton.translatesAutoresizingMaskIntoConstraints = false
        return snapshotButton
    }()
    private(set) var snapshotButton: UIButton = {
        let snapshotButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 22)
        let snapshowUIImage = UIImage(systemName: "square.3.layers.3d.down.right", withConfiguration: config)
        snapshotButton.setImage(snapshowUIImage, for: .normal)
        snapshotButton.translatesAutoresizingMaskIntoConstraints = false
        return snapshotButton
    }()

    init(textEditorComponentViewModel: TextEditorComponentViewModel) {
        self.textEditorComponentViewModel = textEditorComponentViewModel

        super.init(nibName: nil, bundle: nil)

        actionDispatcher.bindToViewModel(
            viewModel: textEditorComponentViewModel,
            updateUIWithEvent: UIupdateEventHandler)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(autoCapture),
            name: UIScene.didEnterBackgroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(autoCapture),
            name: UIScene.didDisconnectNotification,
            object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("SingleTextEditorPageViewController deinit") }

    override func viewDidLoad() {
        if let (title, createdDate, contents) = textEditorComponentViewModel?
            .singleTextEditorComponentViewControllerInitialData
        {
            setupUI(title: title, createDate: createdDate, contents: contents)
            setupConstraint()
        }
    }

    private func UIupdateEventHandler(_ event: TextEditorComponentViewModel.Event) {
        switch event {
            case .didUndoTextComponentContents(let undidText):
                textEditorView.text = undidText

            case .didCaptureWithManual:
                completeSnapshotCapturePopupView()

            case .didRestoreComponentContents(let contents):
                UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: []) {
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                        self.textEditorView.alpha = 0
                    }
                    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.0) {
                        self.textEditorView.text = contents
                    }
                    UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                        self.textEditorView.alpha = 1
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
                navigationController?.pushViewController(snapshotView, animated: true)

            case .didRenameComponent:
                break

            case .didToggleFoldingComponent:
                break

            case .didRemovePageComponent:
                break

            case .didMaximizePageComponent:
                break
        }
    }

    private func setupUI(title: String, createDate: Date, contents: String) {
        view.backgroundColor = .systemBackground
        view.addSubview(headerView)

        headerView.addSubview(titleLable)
        headerView.addSubview(createDateLabel)
        headerView.addSubview(undoButton)

        undoButton.addAction(
            UIAction { [weak self] _ in
                guard let self else { return }
                actionDispatcher.undoTextEditorComponentContents()
            }, for: .touchUpInside)

        headerView.addSubview(captureButton)

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

        headerView.addSubview(snapshotButton)

        snapshotButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                actionDispatcher.navigateToSnapshotView()
            }
            .store(in: &subscriptions)

        titleLable.text = title
        createDateLabel.text = createDate.formattedDate

        view.addSubview(textEditorView)
        textEditorView.delegate = self
        textEditorView.text = contents
    }

    private func setupConstraint() {
        headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        headerView.heightAnchor.constraint(equalToConstant: 60).isActive = true

        titleLable.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true
        titleLable.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10).isActive = true

        createDateLabel.topAnchor.constraint(equalTo: titleLable.bottomAnchor, constant: 3).isActive = true
        createDateLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true

        snapshotButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -10).isActive = true
        snapshotButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true

        captureButton.trailingAnchor.constraint(equalTo: snapshotButton.leadingAnchor, constant: -10).isActive = true
        captureButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true

        undoButton.trailingAnchor.constraint(equalTo: captureButton.leadingAnchor, constant: -10).isActive = true
        undoButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor).isActive = true

        textEditorView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10).isActive = true
        textEditorView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        textEditorView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        textEditorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    func textViewDidChange(_ textView: UITextView) {
        actionDispatcher.saveTextEditorComponentContentsChanged(contents: textView.text)
        captureButton.isEnabled = !textView.text.isEmpty
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let userInfo = notification.userInfo,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else { return }

        let keyboardHeight = view.convert(endFrame, from: nil).intersection(view.frame).height

        textEditorView.contentInset.bottom = keyboardHeight
        textEditorView.verticalScrollIndicatorInsets.bottom = keyboardHeight
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        autoCapture()
        if isMovingFromParent || isBeingDismissed { subscriptions.removeAll() }
    }

    @objc private func autoCapture() {
        captureDispatchSemaphore.wait()
        defer { captureDispatchSemaphore.signal() }

        var taskID: UIBackgroundTaskIdentifier = .invalid

        taskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(taskID)
            taskID = .invalid
        }
        actionDispatcher.captureTextEditorComponentAutomatic()
        UIApplication.shared.endBackgroundTask(taskID)
    }
}
