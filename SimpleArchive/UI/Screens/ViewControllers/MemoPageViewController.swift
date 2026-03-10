import Combine
import UIKit

final class MemoPageViewController:
    UIViewController,
    UICollectionViewDelegateFlowLayout,
    ManualCaptureHost
{
    var pageViewModel: MemoPageViewModel
    var pageActionDispatcher = PassthroughSubject<MemoPageViewInput, Never>()

    var subscriptions = Set<AnyCancellable>()

    var fullscreenTargetComponentView: (any PageComponentViewType)?
    var fullscreenTargetComponentContentsViewFrame: CGRect?

    private var componentCollectionViewDataSource: MemoPageComponentCollectionViewDataSource?
    var snapshotCapturePopupView: SnapshotCapturePopupView?

    private let backgroundView: UIStackView = {
        let backgroundView = UIStackView()
        backgroundView.backgroundColor = .systemBackground
        backgroundView.axis = .vertical
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundView
    }()
    private let headerView: UIView = {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        headerView.translatesAutoresizingMaskIntoConstraints = false
        return headerView
    }()
    private let backButton: UIButton = {
        let backButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let buttonImage = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(buttonImage, for: .normal)
        backButton.tintColor = .label
        backButton.translatesAutoresizingMaskIntoConstraints = false
        return backButton
    }()
    private let titleLable: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 23, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private let componentPlusButton: UIButton = {
        let componentPlusButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let buttonImage = UIImage(systemName: "plus", withConfiguration: config)
        componentPlusButton.setImage(buttonImage, for: .normal)
        componentPlusButton.tintColor = .label
        componentPlusButton.translatesAutoresizingMaskIntoConstraints = false
        return componentPlusButton
    }()

    private(set) var pageComponentCollectionView: UICollectionView!
    private(set) var audioControlBarHost: AudioControlBarHostType

    init(pageViewModel: MemoPageViewModel, audioControlBarHost: AudioControlBarHostType) {
        self.pageViewModel = pageViewModel
        self.audioControlBarHost = audioControlBarHost

        super.init(nibName: nil, bundle: nil)

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

    func bindToMemoPageVM() {
        let output = pageViewModel.subscribe(input: pageActionDispatcher.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .viewDidLoad(let memoPageData):
                    let factory = PageComponentCollectionViewCellFactory(
                        collectionView: pageComponentCollectionView,
                        input: pageActionDispatcher,
                        audioControlBarHost: audioControlBarHost)

                    audioControlBarHost.injectDispatcherContinuousPlaybackSessionInFactory(
                        factory: factory,
                        pageData: memoPageData,
                        collectionView: pageComponentCollectionView)

                    componentCollectionViewDataSource = MemoPageComponentCollectionViewDataSource(
                        pageComponentViewFactory: factory,
                        memoPage: memoPageData)

                    setupUI(pageName: memoPageData.name)
                    setupConstraints()

                case .didAppendComponentAt(let index):
                    appendNewComponentView(index: index)

                case .didRemovePageComponent(let componentIndex):
                    removePageComponent(componentIndex: componentIndex)

                case .didRenameComponent(let componentIndex, let newName):
                    renamePageComponent(componentIndex: componentIndex, newName: newName)

                case .didToggleFoldingComponent(let componentIndex, let isMinimized):
                    toggleComponentFolding(componentIndex: componentIndex, isMinimized: isMinimized)

                case .didMaximizePageComponent(let componentIndex):
                    presentComponentFullScreen(componentIndex: componentIndex)
            }
        }
        .store(in: &subscriptions)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = UIConstants.memoPageViewControllerCollectionViewCellSpacing
        flowLayout.minimumInteritemSpacing = .zero
        flowLayout.sectionInset = .init(top: .zero, left: 20, bottom: .zero, right: 20)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)

        collectionView.backgroundColor = .clear
        collectionView.keyboardDismissMode = .onDrag
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        collectionView.register(
            TextEditorComponentView.self,
            forCellWithReuseIdentifier: TextEditorComponentView.reuseIdentifier)
        collectionView.register(
            TableComponentView.self,
            forCellWithReuseIdentifier: TableComponentView.reuseIdentifier)
        collectionView.register(
            AudioComponentView.self,
            forCellWithReuseIdentifier: AudioComponentView.reuseAudioComponentIdentifier)

        pageComponentCollectionView = collectionView
        applyCollectionViewInsets(bottomInset: UIConstants.memoPageViewControllerCollectionViewFooterHeight)
        bindToMemoPageVM()
        pageActionDispatcher.send(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        audioControlBarHost.setAudioControlBarLayoutAsDefault()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let isfreedFromMemory = isMovingFromParent || isBeingDismissed

        if isfreedFromMemory {
            audioControlBarHost.setAudioControlBarLayoutAsThin()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        let isfreedFromMemory = isMovingFromParent || isBeingDismissed

        if isfreedFromMemory {
            componentCollectionViewDataSource?.freedDataSource()
            componentCollectionViewDataSource = nil

            subscriptions.removeAll()

            audioControlBarHost.setAudioControlBarEventHandlerForThin()
        }
    }

    private func setupUI(pageName: String) {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backButton.addAction(
            UIAction { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }, for: .touchUpInside)

        titleLable.text = pageName

        componentPlusButton.throttleTapPublisher()
            .sink { _ in self.presentCreatingNewComponentView() }
            .store(in: &subscriptions)

        view.addSubview(headerView)

        headerView.addSubview(backButton)
        headerView.addSubview(titleLable)
        headerView.addSubview(componentPlusButton)

        backgroundView.addArrangedSubview(pageComponentCollectionView)

        pageComponentCollectionView.dataSource = componentCollectionViewDataSource
        pageComponentCollectionView.dropDelegate = self
        pageComponentCollectionView.dragDelegate = self
        pageComponentCollectionView.delegate = self
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            headerView.heightAnchor.constraint(equalToConstant: 50),
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            backButton.widthAnchor.constraint(equalToConstant: 50),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),

            titleLable.heightAnchor.constraint(equalToConstant: 50),
            titleLable.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLable.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            componentPlusButton.widthAnchor.constraint(equalToConstant: 50),
            componentPlusButton.heightAnchor.constraint(equalToConstant: 50),
            componentPlusButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),

            pageComponentCollectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor),
            pageComponentCollectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor),
        ])
    }

    private func appendNewComponentView(index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        pageComponentCollectionView.insertItems(at: [indexPath])
        pageComponentCollectionView.scrollToItem(at: indexPath, at: .top, animated: true)
    }

    private func renamePageComponent(componentIndex: Int, newName: String) {
        let indexPath = IndexPath(item: componentIndex, section: 0)
        if let cell = pageComponentCollectionView.cellForItem(at: indexPath),
            let pageComponentView = cell as? (any PageComponentViewType)
        {
            pageComponentView.titleLabel.text = newName
        }
    }

    private func removePageComponent(componentIndex: Int) {
        let indexPath = IndexPath(item: componentIndex, section: 0)
        pageComponentCollectionView.deleteItems(at: [indexPath])
    }

    private func presentCreatingNewComponentView() {
        let createNewComponentView = CreateNewComponentView()

        createNewComponentView.componentTypePublisher
            .sink { [weak self] componentType in
                guard let self else { return }
                pageActionDispatcher.send(.willCreateNewComponent(componentType))
            }
            .store(in: &subscriptions)

        if let sheet = createNewComponentView.sheetPresentationController {
            sheet.detents = [.medium()]
        }

        present(createNewComponentView, animated: true)
    }

    private func toggleComponentFolding(componentIndex: Int, isMinimized: Bool) {
        let path = IndexPath(item: componentIndex, section: .zero)
        if let cell = pageComponentCollectionView.cellForItem(at: path),
            let pageComponentView = cell as? (any PageComponentViewType)
        {
            pageComponentView.setMinimizeState(isMinimized)
        }

        pageComponentCollectionView.performBatchUpdates {
            pageComponentCollectionView.collectionViewLayout.invalidateLayout()
        }
    }

    private func presentComponentFullScreen(componentIndex: Int) {
        let indexPath = IndexPath(item: componentIndex, section: 0)
        fullscreenTargetComponentView =
            pageComponentCollectionView.cellForItem(at: indexPath) as? (any PageComponentViewType)
        fullscreenTargetComponentView?.attachContentsSnapshotViewDuringPresentingFullScreenAnimation()
        fullscreenTargetComponentView?.presentFullScreenPageComponentView()
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let textView = UIResponder.current as? UITextView,
            textView.accessibilityIdentifier == "TextEditorComponentTextView"
        else { return }

        guard
            let userInfo = notification.userInfo,
            let endFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        var targetIndexPath: IndexPath?

        for item in 0..<pageComponentCollectionView.numberOfItems(inSection: .zero) {
            let indexPath = IndexPath(item: item, section: .zero)
            if let cell = pageComponentCollectionView.cellForItem(at: indexPath) as? TextEditorComponentView {
                if cell.componentContentView == textView {
                    targetIndexPath = indexPath
                    break
                }
            }
        }

        let keyboardHeight = UIScreen.main.bounds.height - endFrame.origin.y
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: {
                let bottomInset = max(UIConstants.memoPageViewControllerCollectionViewFooterHeight, keyboardHeight)
                self.applyCollectionViewInsets(bottomInset: bottomInset)
                if let targetIndexPath, keyboardHeight != .zero {
                    self.pageComponentCollectionView.scrollToItem(at: targetIndexPath, at: .bottom, animated: true)
                }
            }
        )
    }

    private func applyCollectionViewInsets(bottomInset: CGFloat) {
        let inset = UIEdgeInsets(
            top: UIConstants.memoPageViewControllerCollectionViewHeaderHeight,
            left: .zero,
            bottom: bottomInset,
            right: .zero
        )
        pageComponentCollectionView.contentInset = inset
        pageComponentCollectionView.scrollIndicatorInsets = inset
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let horizontalInset: CGFloat
        if let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout {
            horizontalInset = flowLayout.sectionInset.left + flowLayout.sectionInset.right
        } else {
            horizontalInset = 40
        }

        let width = collectionView.bounds.width - horizontalInset
        let isMin = pageViewModel.memoPage[indexPath.item].isMinimumHeight
        let height = isMin ? UIConstants.componentMinimumHeight : width
        return .init(width: width, height: height)
    }
}
