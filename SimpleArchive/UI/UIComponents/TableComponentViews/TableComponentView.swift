import Combine
import UIKit

final class TableComponentView: PageComponentView<TableComponentContentView, TableComponent> {
    static let reuseIdentifier = "reuseTableComponentIdentifier"

    private let tableActionDispatcher = TableComponentActionDispatcher()
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
        componentContentView.prepareForReuse()
        tableActionDispatcher.clearSubscriptions()
    }

    override func freedReferences() {
        super.freedReferences()
        tableActionDispatcher.clearSubscriptions()
    }

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

    func configureTableComponentForMemoPageView(
        component: TableComponent,
        viewModel: any PageComponentViewModelType,
        pageActionDispatcher: PassthroughSubject<MemoPageViewInput, Never>
    ) {
        super.configure(component: component, pageActionDispatcher: pageActionDispatcher)

        componentContentView.configure(
            columns: component.componentContents.columns,
            rows: component.componentContents.cellValues,
            actionDispatcher: tableActionDispatcher,
            isMinimum: component.isMinimumHeight)

        tableActionDispatcher.bindToViewModel(
            viewModel: viewModel,
            updateUIWithEvent: UIupdateEventHandler)

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
                tableActionDispatcher.captureComponentManual(description: snapshotDescription)
            }
            .store(in: &subscriptions)

        snapshotButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                tableActionDispatcher.navigateComponentSnapshotView()
            }
            .store(in: &subscriptions)
    }

    func configure(
        snapshotID: UUID,
        snapshotDetail: TableComponentContents,
        snapshotActionDispatcher: PassthroughSubject<ComponentSnapshotViewModel.Action, Never>
    ) {
        self.componentSnapshotActionDispatcher = snapshotActionDispatcher
        pageActionDispatcher = PassthroughSubject<MemoPageViewInput, Never>()

        componentContentView.configure(
            columns: snapshotDetail.columns,
            rows: snapshotDetail.cellValues)

        componentInformationView.removeFromSuperview()

        componentContentView.constraints
            .filter { $0.firstAnchor == componentContentView.topAnchor }
            .forEach { $0.isActive = false }

        componentContentView.topAnchor.constraint(equalTo: toolBarView.bottomAnchor).isActive = true

        subscriptions.removeAll()

        redCircleView.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                componentSnapshotActionDispatcher?.send(.willRemoveSnapshot(snapshotID))
            }
            .store(in: &subscriptions)

        yellowCircleView.backgroundColor = .systemGray5
        greenCircleView.backgroundColor = .systemGray5

        captureButton.removeFromSuperview()
        snapshotButton.removeFromSuperview()
    }

    override func setMinimizeState(_ isMinimize: Bool) {
        componentContentView.minimizeContentView(isMinimize, isAnimated: true)
    }

    override func reloadComponentContentsWhenRestoreUsingSnapshot(contents: Codable) {
        if let tableContents = contents as? TableComponentContents {
            componentContentView.alpha = 0

            componentContentView = TableComponentContentView()
            componentContentView.alpha = 0
            componentContentView.translatesAutoresizingMaskIntoConstraints = false
            componentContentView.layer.cornerRadius = 10
            componentContentView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            componentContentView.backgroundColor = .systemGray6

            containerView.addSubview(componentContentView)

            NSLayoutConstraint.activate([
                componentContentView.topAnchor.constraint(equalTo: componentInformationView.bottomAnchor),
                componentContentView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                componentContentView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                componentContentView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ])

            componentContentView.configure(
                columns: tableContents.columns,
                rows: tableContents.cellValues,
                actionDispatcher: tableActionDispatcher,
                isMinimum: false)

            UIView.animateKeyframes(withDuration: 0.8, delay: 0, options: []) {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.4) {
                    self.collectionView?.collectionViewLayout.invalidateLayout()
                }
                UIView.addKeyframe(withRelativeStartTime: 0.4, relativeDuration: 0.8) {
                    self.componentContentView.alpha = 1
                }
            }
        }
    }

    override func presentFullScreenPageComponentView() {
        if let memoPageViewController = parentViewController as? MemoPageViewController {
            memoPageViewController.fullscreenTargetComponentContentsViewFrame = componentContentView.convert(
                componentContentView.bounds, to: memoPageViewController.view.window!)

            let fullscreenComponentViewController = FullScreenTableComponentViewController(
                title: titleLabel.text!,
                createdDate: createdAt,
                tableComponentContentView: componentContentView
            )
            fullscreenComponentViewController.modalPresentationStyle = .fullScreen
            fullscreenComponentViewController.transitioningDelegate = memoPageViewController

            memoPageViewController.present(fullscreenComponentViewController, animated: true)
        }
    }
}

// MARK: - Event Handler
extension TableComponentView {
    private func tableComponentEventHandler(_ event: TableComponentViewModel.Event) {
        switch event {
            case .didAppendRowToTableView(let row):
                componentContentView.appendEmptyRowToStackView(rowID: row.id)

            case .didAppendColumnToTableView(let column):
                componentContentView.appendEmptyColumnToStackView(column: column)

            case .didApplyTableCellValueChanges(let cellCoord, let cellValue):
                componentContentView.updateUILabelText(
                    rowIndex: cellCoord.rowIndex,
                    cellIndex: cellCoord.columnIndex,
                    with: cellValue)

            case .didRemoveRowToTableView(let rowIdx):
                componentContentView.removeTableComponentRowView(idx: rowIdx)

            case .didApplyTableColumnChanges(let columns):
                componentContentView.applyColumns(columns: columns)

            case .didPresentTableColumnEditPopupView(let columns, let columnIndexTapped):
                let tableComponentColumnEditPopupView = TableComponentColumnEditPopupView(
                    columns: columns,
                    tappedColumnIndex: columnIndexTapped)

                tableComponentColumnEditPopupView.confirmButtonPublisher
                    .sink { [weak self] colums in
                        guard let self else { return }
                        tableActionDispatcher.applyColumnChanges(editedColumns: colums)
                    }
                    .store(in: &subscriptions)

                tableComponentColumnEditPopupView.show()
        }
    }

    private func UIupdateEventHandler(_ event: TableComponentViewModelEvent) {
        switch event {
            case .tableComponentEvent(let tableComponentEvent):
                tableComponentEventHandler(tableComponentEvent)

            case .snapshotEvent(let event):
                commonPageEventHandler(event: event)
        }
    }
}
