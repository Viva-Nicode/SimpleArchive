import Combine
import UIKit

class MemoPageViewController: UIViewController, ViewControllerType, UIScrollViewDelegate,
    NavigationViewControllerDismissible, ComponentSnapshotViewControllerDelegate
{
    typealias Input = MemoPageViewInput
    typealias ViewModelType = MemoPageViewModel

    var input = PassthroughSubject<MemoPageViewInput, Never>()
    var viewModel: MemoPageViewModel
    var subscriptions = Set<AnyCancellable>()

    var selectedPageComponentCell: (any PageComponentViewType)?
    var pageComponentContentViewRect: CGRect?

    var selectedComponentIndexForMoveSnapshotView: Int?

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
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        return titleLabel
    }()
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPrefetchingEnabled = false
        collectionView.contentInset = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
        collectionView.keyboardDismissMode = .onDrag
        collectionView.register(
            TextEditorComponentView.self,
            forCellWithReuseIdentifier: TextEditorComponentView.identifierForUseCollectionView
        )
        collectionView.register(
            TableComponentView.self,
            forCellWithReuseIdentifier: TableComponentView.reuseTableComponentIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    private let newComponentAddButton: UIButton = {
        let newComponentAddButton = UIButton()
        let config = UIImage.SymbolConfiguration(pointSize: 25, weight: .regular)
        let buttonImage = UIImage(systemName: "macwindow.badge.plus", withConfiguration: config)

        newComponentAddButton.frame.origin.y = newComponentAddButton.frame.origin.y + 2

        newComponentAddButton.setImage(buttonImage, for: .normal)
        newComponentAddButton.tintColor = .label
        newComponentAddButton.translatesAutoresizingMaskIntoConstraints = false
        return newComponentAddButton
    }()

    private var headerHeight: CGFloat = 60
    private var headerOffset: CGFloat = 0
    private var lastContentOffsetY: CGFloat = 0

    init(viewModel: MemoPageViewModel) {
        self.viewModel = viewModel
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

    deinit { print("MemoPageViewController deinit") }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        input.send(.viewDidLoad)
    }

    func bind() {
        let output = viewModel.subscribe(input: input.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .viewDidLoad(let pageName, let isReadOnly):
                    setupUI(pageName: pageName, isReadOnly: isReadOnly)
                    setupConstraints(isReadOnly: isReadOnly)

                case .insertNewComponentAtLastIndex(let index):
                    collectionView.insertItems(at: [IndexPath(item: index, section: 0)])
                    collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .top, animated: true)

                case .removeComponentAtIndex(let index):
                    collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])

                case .didMinimizeComponentHeight(let componentIndexMinimized):
                    updateComponentHeight(componentIndexMinimized: componentIndexMinimized)

                case .maximizeComponent(let component, let index):
                    presentComponentFullScreen(with: component, index: index)

                case .didTappedSnapshotButton(let vm, let itemIndex):
                    let snapshotView = ComponentSnapshotViewController(viewModel: vm)

                    snapshotView.delegate = self
                    selectedComponentIndexForMoveSnapshotView = itemIndex
                    navigationController?.pushViewController(snapshotView, animated: true)

                case .didAppendTableComponentRow(let index, let row):
                    if let
                        tableComponentView = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
                        as? TableComponentView
                    {
                        tableComponentView.componentContentView.appendRowToRowStackView(row: row)
                    }

                case .didEditTableComponentCellValue(let componentIndex, let rowIndex, let cellIndex, let newCellValue):
                    if let
                        tableComponentView = collectionView.cellForItem(at: IndexPath(item: componentIndex, section: 0))
                        as? TableComponentView
                    {
                        tableComponentView.componentContentView.updateUILabelText(
                            rowIndex: rowIndex,
                            cellIndex: cellIndex,
                            with: newCellValue
                        )
                    }

                case .didAppendTableComponentColumn(let componentIndex, let column):
                    if let
                        tableComponentView = collectionView.cellForItem(at: IndexPath(item: componentIndex, section: 0))
                        as? TableComponentView
                    {
                        tableComponentView.componentContentView.appendColumnToColumnStackView(column)
                    }

                case .didRemoveTableComponentRow(let componentIndex, let removedRowIndex):
                    if let
                        tableComponentView = collectionView.cellForItem(at: IndexPath(item: componentIndex, section: 0))
                        as? TableComponentView
                    {
                        tableComponentView.componentContentView.removeTableComponentRowView(idx: removedRowIndex)
                    }

                case .didPresentTableComponentColumnEditPopupView(let columns, let tappedColumnIndex, let componentID):
                    let tableComponentColumnEditPopupView = TableComponentColumnEditPopupView(
                        columns: columns, tappedColumnIndex: tappedColumnIndex)

                    tableComponentColumnEditPopupView.confirmButtonPublisher
                        .sink { colums in
                            self.input.send(.editTableComponentColumn(componentID, colums))
                        }
                        .store(in: &subscriptions)
                    tableComponentColumnEditPopupView.show()

                case .didEditTableComponentColumn(let index, let columns):
                    if let
                        tableComponentView = collectionView.cellForItem(at: IndexPath(item: index, section: 0))
                        as? TableComponentView
                    {
                        tableComponentView.componentContentView.applyColumns(columns: columns)
                    }
            }
        }
        .store(in: &subscriptions)
    }

    private func setupUI(pageName: String, isReadOnly: Bool) {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backButton.addAction(
            UIAction { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }, for: .touchUpInside)

        titleLable.text = pageName

        if !isReadOnly {
            headerView.addSubview(newComponentAddButton)

            newComponentAddButton.throttleTapPublisher()
                .sink { _ in self.presentCreatingNewComponentView() }
                .store(in: &subscriptions)
        }

        view.addSubview(headerView)

        headerView.addSubview(backButton)
        headerView.addSubview(titleLable)

        backgroundView.addArrangedSubview(collectionView)

        collectionView.dataSource = viewModel
        collectionView.dropDelegate = self
        collectionView.dragDelegate = self
        collectionView.delegate = self
    }

    private func setupConstraints(isReadOnly: Bool) {
        backgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        headerView.heightAnchor.constraint(equalToConstant: 90).isActive = true
        headerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        backButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20).isActive = true
        backButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10).isActive = true

        if !isReadOnly {
            newComponentAddButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20)
                .isActive = true
            newComponentAddButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -5).isActive =
                true
        }

        titleLable.widthAnchor.constraint(equalTo: headerView.widthAnchor, multiplier: 0.6).isActive = true
        titleLable.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -10).isActive = true
        titleLable.centerXAnchor.constraint(equalTo: headerView.centerXAnchor).isActive = true

        collectionView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor).isActive = true
        collectionView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor).isActive = true
    }

    func reloadCellForRestoredComponent() {
        if let selectedComponentIndexForMoveSnapshotView {
            let indexPath = IndexPath(item: selectedComponentIndexForMoveSnapshotView, section: 0)
            collectionView.reloadItems(at: [indexPath])
        }
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

        for item in 0..<collectionView.numberOfItems(inSection: .zero) {
            let indexPath = IndexPath(item: item, section: .zero)
            if let cell = collectionView.cellForItem(at: indexPath) as? TextEditorComponentView {
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
                self.collectionView.contentInset.bottom = keyboardHeight
                if let targetIndexPath, keyboardHeight != .zero {
                    self.collectionView.scrollToItem(at: targetIndexPath, at: .bottom, animated: true)
                }
            }
        )
    }

    private func updateComponentHeight(componentIndexMinimized: Int) {
        collectionView.performBatchUpdates({
            if let cell = self.collectionView.cellForItem(
                at: IndexPath(item: componentIndexMinimized, section: 0)
            ) {
                cell.setNeedsLayout()
                cell.layoutIfNeeded()
            }
        })
    }

    private func presentComponentFullScreen(with data: any PageComponent, index: Int) {

        selectedPageComponentCell =
            collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? (any PageComponentViewType)

        switch data {
            case let textEditorComponent as TextEditorComponent:

                let contentView = selectedPageComponentCell!.getContentView() as! UITextView
                pageComponentContentViewRect = contentView.convert(contentView.bounds, to: self.view.window!)

                let fullscreenComponentViewController = FullScreenTextEditorComponentViewController(
                    textEditorComponentModel: textEditorComponent,
                    componentTextView: contentView
                )
                fullscreenComponentViewController.modalPresentationStyle = .fullScreen
                fullscreenComponentViewController.transitioningDelegate = self

                present(fullscreenComponentViewController, animated: true)

            case let tableComponent as TableComponent:

                let contentView = selectedPageComponentCell!.getContentView() as! TableComponentContentView
                pageComponentContentViewRect = contentView.convert(contentView.bounds, to: self.view.window!)

                let fullScreenTableComponentViewController = FullScreenTableComponentViewController(
                    tableComponent: tableComponent,
                    tableComponentContentView: contentView
                )
                fullScreenTableComponentViewController.modalPresentationStyle = .fullScreen
                fullScreenTableComponentViewController.transitioningDelegate = self

                present(fullScreenTableComponentViewController, animated: true)

            default:
                break
        }
    }

    private func presentCreatingNewComponentView() {
        let createNewComponentView = CreateNewComponentView()
        createNewComponentView.delegate = self

        if let sheet = createNewComponentView.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }

        present(createNewComponentView, animated: true)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let delta = offsetY - lastContentOffsetY

        let minOffsetY: CGFloat = 0
        let maxOffsetY: CGFloat = max(scrollView.contentSize.height - scrollView.bounds.height, 0)

        if offsetY >= minOffsetY && offsetY <= maxOffsetY {
            headerOffset += delta
            headerOffset = min(max(headerOffset, 0), headerHeight + 50)

            headerView.transform = CGAffineTransform(translationX: 0, y: -headerOffset)
        }

        lastContentOffsetY = offsetY
    }

    func onDismiss() {
        input.send(.viewWillDisappear)
        subscriptions.removeAll()
    }
}

extension MemoPageViewController: CreateNewComponentViewDelegate {
    func createNewComponent(with: ComponentType) {
        input.send(.createNewComponent(with))
    }
}
