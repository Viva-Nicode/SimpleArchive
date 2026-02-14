import Combine
import UIKit

final class SingleTextEditorPageViewController: UIViewController, UITextViewDelegate, UIScrollViewDelegate {
    private let actionDispatcher = TextEditorComponentActionDispatcher()

    var subscriptions = Set<AnyCancellable>()
    var snapshotCapturePopupView: SnapshotCapturePopupView?

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
        super.init(nibName: nil, bundle: nil)

        let data = textEditorComponentViewModel.singleTextEditorComponentViewControllerInitialData

        setupUI(title: data.title, createDate: data.createdDate, contents: data.contents)
        setupConstraint()
        setupAction()

        actionDispatcher.bindToViewModel(
            viewModel: textEditorComponentViewModel,
            updateUIWithEvent: UIupdateEventHandler)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    private func UIupdateEventHandler(_ event: TextEditorComponentViewModelEvent) {
        switch event {
            case .textEditorComponentEvent(let textEvent):
                switch textEvent {
                    case .didUndoTextComponentContents(let undidText):
                        textEditorView.text = undidText
                }

            case .snapshotEvent(let snapshotEvent):
                switch snapshotEvent {
                    case .didManualCapturePageComponent:
                        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: []) {
                            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) {
                                self.textEditorView.alpha = 0
                            }
                            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.0) {
//                                self.textEditorView.text = contents
                            }
                            UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) {
                                self.textEditorView.alpha = 1
                            }
                        }

                    case .didNavigateComponentSnapshotView(let viewModel):
                        let snapshotView = ComponentSnapshotViewController(viewModel: viewModel)
                        snapshotView.hasRestorePublisher
                            .sink { [weak self] _ in
                                guard let self else { return }
//                                actionDispatcher.resotreComponentContents()
                            }
                            .store(in: &subscriptions)
                        navigationController?.pushViewController(snapshotView, animated: true)
                }
        }
    }

    private func setupUI(title: String, createDate: Date, contents: String) {
        view.backgroundColor = .systemBackground
        view.addSubview(headerView)

        headerView.addSubview(titleLable)
        headerView.addSubview(createDateLabel)
        headerView.addSubview(undoButton)
        headerView.addSubview(snapshotButton)
        headerView.addSubview(captureButton)

        titleLable.text = title
        createDateLabel.text = createDate.formattedDate

        view.addSubview(textEditorView)
        textEditorView.delegate = self
        textEditorView.text = contents
    }

    private func setupConstraint() {
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            titleLable.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),
            titleLable.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 10),

            createDateLabel.topAnchor.constraint(equalTo: titleLable.bottomAnchor, constant: 3),
            createDateLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10),

            snapshotButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -10),
            snapshotButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            captureButton.trailingAnchor.constraint(equalTo: snapshotButton.leadingAnchor, constant: -10),
            captureButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            undoButton.trailingAnchor.constraint(equalTo: captureButton.leadingAnchor, constant: -10),
            undoButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            textEditorView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            textEditorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textEditorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textEditorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupAction() {
        undoButton
            .throttleTapPublisher(owner: self, interval: 0.25)
            .sink { $0.actionDispatcher.undoTextEditorComponentContents() }
            .store(in: &subscriptions)

        snapshotButton
            .throttleTapPublisher(owner: self)
            .sink { $0.actionDispatcher.navigateComponentSnapshotView() }
            .store(in: &subscriptions)

        captureButton
            .throttleTapPublisher(owner: self)
            .flatMap { weakself -> AnyPublisher<String, Never> in
                let snapshotCapturePopupView = SnapshotCapturePopupView()
                weakself.snapshotCapturePopupView = snapshotCapturePopupView
                snapshotCapturePopupView.show()

                return snapshotCapturePopupView.captureButtonPublisher
            }
            .sink { [weak self] snapshotDescription in
                guard let self else { return }
                actionDispatcher.captureComponentManual(description: snapshotDescription)
            }
            .store(in: &subscriptions)
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
        if isMovingFromParent || isBeingDismissed {
            actionDispatcher.clearSubscriptions()
            subscriptions.removeAll()
        }
    }
}
