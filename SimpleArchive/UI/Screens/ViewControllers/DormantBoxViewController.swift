import Combine
import UIKit

class DormantBoxViewController: UIViewController, ViewControllerType, NavigationViewControllerDismissible {

    typealias Input = DormantBoxViewInput
    typealias ViewModelType = DormantBoxViewModel

    var input = PassthroughSubject<DormantBoxViewInput, Never>()
    var viewModel: DormantBoxViewModel
    var subscriptions = Set<AnyCancellable>()
    var removedItemCount: Int = 0 {
        didSet {
            self.totalFileCountLabel.text = "\(self.removedItemCount) files in total"
        }
    }

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
    private(set) var totalFileCountLabel: UILabel = {
        let totalFileCountLabel = BasePaddingLabel(padding: .init(top: 10, left: 15, bottom: 20, right: 0))
        return totalFileCountLabel
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
        tableView.register(
            DirectoryFileItemRowView.self,
            forCellReuseIdentifier: DirectoryFileItemRowView.reuseIdentifier)
        return tableView

    }()

    init(viewModel: DormantBoxViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit { print("deinit DormantBoxViewController") }

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

                case .didfetchMemoData(let itemCount):
                    setupUI(itemCount: itemCount)
                    setupConstraints()

                case .showFileInformation(let pageInfo):
                    showFileInformation(pageInfo: pageInfo)

                case .didRemovePageFromDormantBox(let index):
                    removedItemCount -= 1
                    tableView.deleteSections(.init(integer: index), with: .fade)
            }
        }
        .store(in: &subscriptions)
    }

    private func setupUI(itemCount: Int) {
        removedItemCount = itemCount
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backButton.throttleTapPublisher()
            .sink { _ in self.navigationController?.popViewController(animated: true) }
            .store(in: &subscriptions)

        headerStackView.addArrangedSubview(backButton)
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(UIView.spacerView)

        backgroundView.addArrangedSubview(headerStackView)
        backgroundView.addArrangedSubview(totalFileCountLabel)
        totalFileCountLabel.text = "\(itemCount) files in total"
        totalFileCountLabel.textAlignment = .left

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

    private func showFileInformation(pageInfo: PageInformation) {
        let fileInformationView = RemovedFileInformationPopupView(pageInformation: pageInfo)
        fileInformationView.removeButtonPublisher
            .sink { [weak self] id in
                guard let id else { return }
                self?.input.send(.willRemovePageFromDormantBox(id))
            }
            .store(in: &subscriptions)
        fileInformationView.show()
    }

    func onDismiss() {
        subscriptions.removeAll()
    }
}

extension DormantBoxViewController: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {

        let restoreFileButton =
            UIContextualAction(style: .normal, title: "restore") { (_, _, success: @escaping (Bool) -> Void) in
                self.input.send(.restoreFile(indexPath.section))
                self.removedItemCount -= 1
                tableView.deleteSections(.init(integer: indexPath.section), with: .fade)
                success(true)
            }

        restoreFileButton.backgroundColor = .systemGreen
        restoreFileButton.image = UIImage(systemName: "arrow.up.trash")
        let config = UISwipeActionsConfiguration(actions: [restoreFileButton])
        config.performsFirstActionWithFullSwipe = false
        return config
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        input.send(.showFileInformation(indexPath.section))
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 70 }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 0 }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat { 13 }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
}
