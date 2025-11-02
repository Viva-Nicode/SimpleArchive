import Combine
import UIKit

final class SingleTablePageViewController: UIViewController, ViewControllerType,
    UIScrollViewDelegate, NavigationViewControllerDismissible, ComponentSnapshotViewControllerDelegate
{
    typealias Input = SingleTablePageInput
    typealias ViewModelType = SingleTablePageViewModel

    var input = PassthroughSubject<SingleTablePageInput, Never>()
    var viewModel: SingleTablePageViewModel
    var subscriptions = Set<AnyCancellable>()

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
                        content: detail,
                        dispatcher: SinglePageTableComponentActionDispatcher(subject: input),
                        isMinimum: false,
                        componentID: id)

                case .didTappedSnapshotButton(let vm):
                    let snapshotView = ComponentSnapshotViewController(viewModel: vm)
                    snapshotView.delegate = self
                    navigationController?.pushViewController(snapshotView, animated: true)

                case .didTappedCaptureButton(let detail):
                    UIView.animate(
                        withDuration: 0.25,
                        animations: {
                            self.tableComponentContentView.alpha = 0
                        }
                    ) { _ in
                        self.tableComponentContentView.configure(
                            content: detail,
                            dispatcher: SinglePageTableComponentActionDispatcher(subject: self.input),
                            isMinimum: false,
                            componentID: UUID())
                        UIView.animate(withDuration: 0.25) {
                            self.tableComponentContentView.alpha = 1
                        }
                    }

                case .didAppendTableComponentColumn(let column):
                    tableComponentContentView.appendColumnToColumnStackView(column)

                case .didAppendTableComponentRow(let row):
                    tableComponentContentView.appendRowToRowStackView(row: row)

                case .didRemoveTableComponentRow(let removedRowIndex):
                    tableComponentContentView.removeTableComponentRowView(idx: removedRowIndex)

                case .didEditTableComponentCellValue(let r, let c, let newCellValue):
                    tableComponentContentView.updateUILabelText(
                        rowIndex: r,
                        cellIndex: c,
                        with: newCellValue
                    )

                case .didPresentTableComponentColumnEditPopupView(let columns, let columnIndex):
                    let tableComponentColumnEditPopupView = TableComponentColumnEditPopupView(
                        columns: columns, tappedColumnIndex: columnIndex)

                    tableComponentColumnEditPopupView.confirmButtonPublisher
                        .sink { self.input.send(.editTableComponentColumn($0)) }
                        .store(in: &subscriptions)
                    tableComponentColumnEditPopupView.show()

                case .didEditTableComponentColumn(let columns):
                    tableComponentContentView.applyColumns(columns: columns)
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
            .sink { [weak self] _ in
                guard let self else { return }
                let snapshotCapturePopupView = SnapshotCapturePopupView { snapshotDescription in
                    self.input.send(.willCaptureToComponent(snapshotDescription))
                }
                snapshotCapturePopupView.show()
            }
            .store(in: &subscriptions)
        headerView.addSubview(snapshotButton)
        snapshotButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                input.send(.willPresentSnapshotView)
            }
            .store(in: &subscriptions)

        titleLable.text = memoTitle
        createDateLabel.text = createDate.formattedDate

        view.addSubview(tableComponentContentView)

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

        tableComponentContentView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10).isActive = true
        tableComponentContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableComponentContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableComponentContentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive =
            true
    }

    func onDismiss() {
        input.send(.viewWillDisappear)
        subscriptions.removeAll()
    }

    func reloadCellForRestoredComponent() {
        input.send(.willRestoreComponentWithSnapshot)
    }
}
