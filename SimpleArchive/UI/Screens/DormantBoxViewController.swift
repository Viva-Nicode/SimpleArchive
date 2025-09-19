import UIKit
import Combine

class DormantBoxViewController: UIViewController, ViewControllerType, NavigationViewControllerDismissible {

    typealias Input = DormantBoxViewInput
    typealias ViewModelType = DormantBoxViewModel

    var input = PassthroughSubject<DormantBoxViewInput, Never>()
    var viewModel: DormantBoxViewModel
    var subscriptions = Set<AnyCancellable>()

    private let backgroundView: UIStackView = {
        let bg = UIStackView()
        bg.axis = .vertical
        bg.backgroundColor = .systemBackground
        bg.translatesAutoresizingMaskIntoConstraints = false
        return bg
    }()
    private let headerStackView: UIStackView = {
        let headerStackView = UIStackView()
        headerStackView.axis = .horizontal
        headerStackView.alignment = .center
        headerStackView.spacing = 10
        headerStackView.distribution = .fill
        headerStackView.isLayoutMarginsRelativeArrangement = true
        headerStackView.layoutMargins = .init(top: 10, left: 15, bottom: 10, right: 15)
        return headerStackView
    }()
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Dormant Box"
        titleLabel.font = .boldSystemFont(ofSize: 26)
        titleLabel.textColor = .label
        return titleLabel
    }()
    private let backButton: UIButton = {
        let backButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20)
        let buttonImage = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(buttonImage, for: .normal)
        backButton.tintColor = .label
        return backButton
    }()
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.backgroundColor = .systemBackground
        tableView.register(MemoTableRowView.self, forCellReuseIdentifier: MemoTableRowView.cellId)
        return tableView

    }()

    init(viewModel: DormantBoxViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("DormantBoxViewController deinit") }

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

            case .didfetchMemoData:
                setupUI()
                setupConstraints()

            case .showFileInformation(let file):
                showFileInformation(file: file)

            case .getMemoPageViewModel(let vm):
                self.navigationController?.pushViewController(MemoPageViewController(viewModel: vm), animated: true)
            }
        }.store(in: &subscriptions)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backButton.throttleTapPublisher()
            .sink(receiveValue: { _ in self.navigationController?.popViewController(animated: true) })
            .store(in: &subscriptions)

        headerStackView.addArrangedSubview(backButton)
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(UIView.spacerView)

        backgroundView.addArrangedSubview(headerStackView)

        tableView.dataSource = viewModel
        tableView.delegate = self

        backgroundView.addArrangedSubview(tableView)
    }

    private func setupConstraints() {
        backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    }

    private func showFileInformation(file: any StorageItem) {
        guard let info = file.getFileInformation() as? PageInformation else { return }
        let fileInformationView = PageInformationPopupView(pageInformation: info, isReadOnly: true)
        fileInformationView.show()
    }

    func onDismiss() { subscriptions.removeAll() }
}

extension DormantBoxViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        let showFileInfomation =
            UIContextualAction(style: .normal, title: "share") { (_, _, success: @escaping (Bool) -> Void) in
            self.input.send(.showFileInformation(indexPath.row))
            success(true)
        }

        let restoreFileButton =
            UIContextualAction(style: .normal, title: "restore") { (_, _, success: @escaping (Bool) -> Void) in
            self.input.send(.restoreFile(indexPath.row))
            tableView.deleteRows(at: [indexPath], with: .fade)
            success(true)
        }

        showFileInfomation.backgroundColor = .systemBlue
        showFileInfomation.image = UIImage(systemName: "info.circle")
        restoreFileButton.backgroundColor = .systemGreen
        restoreFileButton.image = UIImage(systemName: "arrow.up.trash")

        return UISwipeActionsConfiguration(actions: [restoreFileButton, showFileInfomation])
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        input.send(.moveToPage(indexPath.row))
    }
}
