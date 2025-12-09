import Combine
import UIKit

final class SingleTablePageViewController: UIViewController, ViewControllerType,
    UIScrollViewDelegate, NavigationViewControllerDismissible, CaptureableComponentView
{
    typealias Input = SingleTablePageInput
    typealias ViewModelType = SingleTablePageViewModel

    var input = PassthroughSubject<SingleTablePageInput, Never>()
    var viewModel: SingleTablePageViewModel
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
    private(set) var tableComponentContentView: TableComponentContentView = {
        let tableComponentContentView = TableComponentContentView()
        tableComponentContentView.backgroundColor = .systemGray6
        tableComponentContentView.translatesAutoresizingMaskIntoConstraints = false
        return tableComponentContentView
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

    override func viewDidLoad() {
        bind()
        input.send(.viewDidLoad)
    }

    init(viewModel: SingleTablePageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("SingleTablePageViewController deinit") }

    func bind() {
        let output = viewModel.subscribe(input: input.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .viewDidLoad(let title, let date, let detail, let id):
                    setupUI(memoTitle: title, createDate: date)
                    setupConstraint()

                    tableComponentContentView.configure(
                        columns: detail.columns,
                        rows: detail.cellValues,
                        dispatcher: SinglePageTableComponentActionDispatcher(subject: input),
                        isMinimum: false,
                        componentID: id)

                case .didNavigateSnapshotView(let vm):
                    let snapshotView = ComponentSnapshotViewController(viewModel: vm)

                    snapshotView.hasRestorePublisher
                        .sink { [weak self] _ in
                            guard let self else { return }
                            input.send(.willRestoreComponent)
                        }
                        .store(in: &subscriptions)
                    navigationController?.pushViewController(snapshotView, animated: true)

                case .didRestoreComponent(let detail):
                    UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: []) {

                        UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.5) { [weak self] in
                            guard let self else { return }
                            tableComponentContentView.alpha = 0
                        }

                        UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.0) { [weak self] in
                            guard let self else { return }
                            tableComponentContentView.configure(
                                columns: detail.columns,
                                rows: detail.cellValues,
                                dispatcher: SinglePageTableComponentActionDispatcher(subject: input),
                                isMinimum: false,
                                componentID: UUID())
                        }

                        UIView.addKeyframe(withRelativeStartTime: 0.5, relativeDuration: 0.5) { [weak self] in
                            guard let self else { return }
                            tableComponentContentView.alpha = 1
                        }
                    }

                case .didAppendRowToTableView(let row):
                    tableComponentContentView.appendEmptyRowToStackView(rowID: row.id)

                case .didAppendColumnToTableView(let column):
                    tableComponentContentView.appendEmptyColumnToStackView(column: column)

                case .didApplyTableCellValueChanges(let row, let column, let newCellValue):
                    tableComponentContentView.updateUILabelText(
                        rowIndex: row,
                        cellIndex: column,
                        with: newCellValue
                    )

                case .didRemoveRowToTableView(let removedRowIndex):
                    tableComponentContentView.removeTableComponentRowView(idx: removedRowIndex)

                case .didPresentTableColumnEditPopupView(let columns, let columnIndex):
                    let tableComponentColumnEditPopupView = TableComponentColumnEditPopupView(
                        columns: columns, tappedColumnIndex: columnIndex)

                    tableComponentColumnEditPopupView.confirmButtonPublisher
                        .sink { self.input.send(.willApplyTableColumnChanges($0)) }
                        .store(in: &subscriptions)

                    tableComponentColumnEditPopupView.show()

                case .didApplyTableColumnChanges(let columns):
                    tableComponentContentView.applyColumns(columns: columns)

                case .didCompleteComponentCapture:
                    completeSnapshotCapturePopupView()
            }
        }
        .store(in: &subscriptions)
    }

    private func setupUI(memoTitle: String, createDate: Date) {
        view.backgroundColor = .systemBackground
        view.addSubview(headerView)
        headerView.addSubview(titleLable)
        headerView.addSubview(createDateLabel)
        headerView.addSubview(captureButton)

        captureButton.throttleTapPublisher()
            .flatMap { [weak self] _ -> AnyPublisher<String, Never> in
                guard let self else { return Empty().eraseToAnyPublisher() }

                let popup = SnapshotCapturePopupView()
                self.snapshotCapturePopupView = popup
                popup.show()

                return popup.captureButtonPublisher
            }
            .sink { [weak self] snapshotDescription in
                guard let self else { return }
                self.input.send(.willCaptureComponent(snapshotDescription))
            }
            .store(in: &subscriptions)
        headerView.addSubview(snapshotButton)

        snapshotButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                input.send(.willNavigateSnapshotView)
            }
            .store(in: &subscriptions)

        titleLable.text = memoTitle
        createDateLabel.text = createDate.formattedDate

        view.addSubview(tableComponentContentView)
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

            tableComponentContentView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            tableComponentContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableComponentContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableComponentContentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    func onDismiss() {
        input.send(.viewWillDisappear)
        subscriptions.removeAll()
    }
}
