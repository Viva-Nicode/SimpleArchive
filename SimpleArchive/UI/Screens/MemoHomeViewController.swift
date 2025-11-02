import Combine
import UIKit

class MemoHomeViewController: UIViewController, ViewControllerType {

    typealias Input = MemoHomeViewInput
    typealias ViewModelType = MemoHomeViewModel

    var input = PassthroughSubject<MemoHomeViewInput, Never>()
    var viewModel: MemoHomeViewModel
    var subscriptions = Set<AnyCancellable>()

    private let backgroundView: UIStackView = {
        let backgroundView = UIStackView()
        backgroundView.axis = .vertical
        backgroundView.spacing = 10
        backgroundView.backgroundColor = .systemBackground
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundView
    }()

    // MARK: - Header Views
    private let headerStackView: UIStackView = {
        let headerStackView = UIStackView()
        headerStackView.axis = .horizontal
        headerStackView.alignment = .center
        headerStackView.spacing = 21
        headerStackView.distribution = .fill
        headerStackView.isLayoutMarginsRelativeArrangement = true
        headerStackView.layoutMargins = .init(top: 10, left: 15, bottom: 10, right: 15)
        return headerStackView
    }()
    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Memo"
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textColor = .label
        return titleLabel
    }()
    private let trashBoxButton: UIButton = {
        let trashBoxButton = UIButton(type: .system)
        trashBoxButton.setImage(UIImage(systemName: "trash"), for: .normal)
        trashBoxButton.tintColor = .systemBlue
        return trashBoxButton
    }()
    private let newFolderButton: UIButton = {
        let newFolderButton = UIButton(type: .system)
        let folderPlusImage = UIImage(named: "folder-plus")!
        let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 25, height: 25))
            .image { _ in
                folderPlusImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 25, height: 25)))
            }
        newFolderButton.setImage(resizedImage, for: .normal)
        newFolderButton.imageView?.contentMode = .scaleAspectFit
        newFolderButton.tintColor = .systemBlue
        return newFolderButton
    }()
    private(set) var newPageButton: UIButton = {
        let newPageButton = UIButton(type: .system)
        let PagePlusImage = UIImage(named: "file-plus")!
        let pagePlusResizedImage = UIGraphicsImageRenderer(size: CGSize(width: 25, height: 25))
            .image { _ in
                PagePlusImage.draw(in: CGRect(origin: .zero, size: CGSize(width: 25, height: 25)))
            }
        newPageButton.setImage(pagePlusResizedImage, for: .normal)
        newPageButton.imageView?.contentMode = .scaleAspectFit
        newPageButton.tintColor = .systemBlue
        newPageButton.accessibilityIdentifier = "newPageButton"
        return newPageButton
    }()

    // MARK: - FileSorting PullDown Button View
    private let sortingButtonView: UIStackView = {
        let sortingButtonView = UIStackView()
        sortingButtonView.axis = .horizontal
        sortingButtonView.alignment = .center
        sortingButtonView.spacing = 8
        sortingButtonView.isLayoutMarginsRelativeArrangement = true
        sortingButtonView.layoutMargins = .init(top: 0, left: 20, bottom: 0, right: 20)
        return sortingButtonView
    }()
    private let sortingButton: UIButton = {
        let sortingButton = UIButton(type: .system)
        sortingButton.setTitle("sort by", for: .normal)
        sortingButton.setTitleColor(.systemBlue, for: .normal)
        sortingButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .regular)
        sortingButton.showsMenuAsPrimaryAction = true
        return sortingButton
    }()
    private let ascendingOrderButton: UIButton = {
        var buttonConfiguration = UIButton.Configuration.plain()
        buttonConfiguration.image = UIImage(systemName: "arrow.up.and.down.text.horizontal")
        buttonConfiguration.contentInsets = .zero
        buttonConfiguration.baseForegroundColor = .systemBlue
        buttonConfiguration.buttonSize = .small
        return UIButton(configuration: buttonConfiguration)
    }()

    // MARK: - Directory Path Views
    private let rootDirectoryLable: BasePaddingLabel = {
        let rootDirectoryLable = BasePaddingLabel()
        rootDirectoryLable.layer.cornerRadius = 5
        rootDirectoryLable.backgroundColor = .blue
        rootDirectoryLable.clipsToBounds = true
        rootDirectoryLable.textColor = .white
        rootDirectoryLable.isUserInteractionEnabled = true
        rootDirectoryLable.font = .systemFont(ofSize: 14, weight: .medium)
        return rootDirectoryLable
    }()
    private let directoryPathView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    private let directoryPathStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 5
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .init(top: 10, left: 15, bottom: 0, right: 15)
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - Fixed File Views
    private let fixedFilesTableViewContainer: UIStackView = {
        let fixedFilesTableViewContainer = UIStackView()
        fixedFilesTableViewContainer.axis = .vertical
        fixedFilesTableViewContainer.isLayoutMarginsRelativeArrangement = true
        fixedFilesTableViewContainer.layoutMargins = .init(top: 0, left: 15, bottom: 0, right: 15)
        return fixedFilesTableViewContainer
    }()
    private let fixedFilesLable: BasePaddingLabel = {
        let fixedFilesLable = BasePaddingLabel(padding: .init(top: 0, left: 15, bottom: 0, right: 15))
        fixedFilesLable.text = "Fixed Files"
        fixedFilesLable.font = .boldSystemFont(ofSize: 21)
        fixedFilesLable.textColor = .label
        return fixedFilesLable
    }()
    private let fixedFilesTableView: UITableView = {
        let fixedFilesTableView = UITableView(frame: .zero, style: .plain)
        fixedFilesTableView.backgroundColor = .systemGray6
        fixedFilesTableView.layer.cornerRadius = 10
        fixedFilesTableView.separatorStyle = .none
        fixedFilesTableView.dragInteractionEnabled = true
        fixedFilesTableView.register(MemoTableRowView.self, forCellReuseIdentifier: MemoTableRowView.cellId)
        fixedFilesTableView.translatesAutoresizingMaskIntoConstraints = false
        return fixedFilesTableView
    }()

    // MARK: - Home File Views
    private let mainFilesLable: BasePaddingLabel = {
        let mainFilesLable = BasePaddingLabel(padding: .init(top: 0, left: 15, bottom: 0, right: 15))
        mainFilesLable.text = "Main Files"
        mainFilesLable.font = .boldSystemFont(ofSize: 21)
        mainFilesLable.textColor = .label
        return mainFilesLable
    }()
    private(set) var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.accessibilityIdentifier = "memoHomeCollectionView"
        collectionView.register(
            MemoHomeTableView.self,
            forCellWithReuseIdentifier: MemoHomeTableView.reuseIdentifier)
        collectionView.isPrefetchingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    init(memoHomeViewModel: MemoHomeViewModel) {
        self.viewModel = memoHomeViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        collectionView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        handleError()
        input.send(.viewDidLoad)
    }

    func bind() {
        let output = viewModel.subscribe(input: input.eraseToAnyPublisher())

        output.sink { [weak self] result in
            guard let self else { return }

            switch result {
                case .didfetchMemoData(let rootDirectoryID, let sortCriteria):
                    setupUI(sortBy: sortCriteria)
                    setupConstraints()
                    setupActions(rootDirectoryID)

                case .insertRowToTable(let collectionCellIndex, let tableCellIndices):
                    insertRowToTable(collectionCellIndex: collectionCellIndex, tableCellIndices: tableCellIndices)

                case .didTappedDirectoryPath(let removedIndexList, let sortCriteria):
                    sortingButton.menu = createUIMenu(sortBy: sortCriteria)
                    movePreviousDirectoryTappedLabel(removedIndexList: removedIndexList)

                case .didTappedDirectoryRow(let directoryName, let directoryID, let sortCriteria):
                    sortingButton.menu = createUIMenu(sortBy: sortCriteria)
                    moveToNextDirectory(directoryName: directoryName, directoryID: directoryID)

                case .showFileInformation(let fileInformation):
                    showFileInformation(for: fileInformation)

                case .moveDoramntBoxView(let vm):
                    navigationController?.pushViewController(DormantBoxViewController(viewModel: vm), animated: true)

                case .getMemoPageViewModel(let vm):
                    navigationController?.pushViewController(MemoPageViewController(viewModel: vm), animated: true)

                case .didPerformDropOperationInFixedTable(
                    let indexOfCell, let insertRowIndexPaths, let deleteRowIndexPaths):
                    didPerformDropOperationInFixedTable(
                        indexOfCell: indexOfCell,
                        insertRowIndexPaths: insertRowIndexPaths, deleteRowIndexPaths: deleteRowIndexPaths)

                case .didPerformDropOperationInHomeTable(
                    let indexOfCell, let insertRowIndexPaths, let deleteRowIndexPaths):
                    didPerformDropOperationInHomeTable(
                        indexOfCell: indexOfCell,
                        insertRowIndexPaths: insertRowIndexPaths, deleteRowIndexPaths: deleteRowIndexPaths)

                case .didChangedFileName(let newName, let before, let after):
                    changeRowFile(newName: newName, before: before, after: after)

                case .didChangeSortCriteria(let sortingResult):
                    resortFileTableRows(sortingResult)

                case .presentSingleTextEditorComponentPage(let vm):
                    let singleTextEditorPageViewController = SingleTextEditorPageViewController(viewModel: vm)
                    navigationController?.pushViewController(singleTextEditorPageViewController, animated: true)

                case .presentSingleTableComponentPage(let vm):
                    let singleTablePageViewController = SingleTablePageViewController(viewModel: vm)
                    navigationController?.pushViewController(singleTablePageViewController, animated: true)

                case .presentSingleAudioComponentPage(let vm):
                    let singleAudioPageViewController = SingleAudioPageViewController(viewModel: vm)
                    navigationController?.pushViewController(singleAudioPageViewController, animated: true)
            }
        }
        .store(in: &subscriptions)
    }

    func handleError() {
        viewModel.errorSubscribe()
            .sink { [weak self] errorCase in
                guard let self else { return }

                switch errorCase {
                    case .canNotLoadMemoData:
                        setupUI(sortBy: .name)
                        setupConstraints()
                        let errorPopupView = ErrorMessagePopupView(error: errorCase) {
                            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                exit(0)
                            }
                        }
                        errorPopupView.show()
                }
            }
            .store(in: &subscriptions)
    }

    private func setupUI(sortBy: SortCriterias) {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backgroundView.addArrangedSubview(headerStackView)
        backgroundView.addArrangedSubview(sortingButtonView)
        backgroundView.addArrangedSubview(directoryPathView)
        backgroundView.addArrangedSubview(fixedFilesLable)
        backgroundView.addArrangedSubview(fixedFilesTableViewContainer)
        backgroundView.addArrangedSubview(mainFilesLable)
        backgroundView.addArrangedSubview(collectionView)

        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(trashBoxButton)
        headerStackView.addArrangedSubview(newFolderButton)
        headerStackView.addArrangedSubview(newPageButton)

        sortingButtonView.addArrangedSubview(UIView.spacerView)
        sortingButton.menu = createUIMenu(sortBy: sortBy)
        sortingButtonView.addArrangedSubview(sortingButton)
        sortingButtonView.addArrangedSubview(ascendingOrderButton)

        directoryPathView.addSubview(directoryPathStackView)
        rootDirectoryLable.text = "Home"
        directoryPathStackView.addArrangedSubview(rootDirectoryLable)

        fixedFilesTableView.dataSource = viewModel
        fixedFilesTableView.delegate = self
        fixedFilesTableView.dragDelegate = self
        fixedFilesTableView.dropDelegate = self

        fixedFilesTableViewContainer.addArrangedSubview(fixedFilesTableView)
        collectionView.delegate = self
        collectionView.dataSource = viewModel

        collectionView.layoutIfNeeded()
    }

    private func setupConstraints() {
        backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true

        directoryPathView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        directoryPathStackView.topAnchor.constraint(equalTo: directoryPathView.topAnchor).isActive = true
        directoryPathStackView.bottomAnchor.constraint(equalTo: directoryPathView.bottomAnchor).isActive = true
        directoryPathStackView.leadingAnchor.constraint(equalTo: directoryPathView.leadingAnchor).isActive = true
        directoryPathStackView.trailingAnchor.constraint(equalTo: directoryPathView.trailingAnchor).isActive = true

        fixedFilesTableView.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }

    private func setupActions(_ rootDirectoryID: UUID) {
        trashBoxButton.throttleTapPublisher()
            .sink { _ in self.input.send(.getDormantBoxViewModel) }
            .store(in: &subscriptions)

        newFolderButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }

                let subject = PassthroughSubject<MemoHomeSubViewInput, Never>()
                viewModel.subscribe(input: subject.eraseToAnyPublisher())

                let popupView = NewDirectoryPopupView(subject: subject)
                popupView.show()
            }
            .store(in: &subscriptions)

        newPageButton.throttleTapPublisher()
            .sink { [weak self] _ in
                guard let self else { return }

                let subject = PassthroughSubject<MemoHomeSubViewInput, Never>()
                viewModel.subscribe(input: subject.eraseToAnyPublisher())

                let popupView = NewPagePopupView(subject: subject)
                popupView.show()
            }
            .store(in: &subscriptions)

        rootDirectoryLable.throttleUIViewTapGesturePublisher(interval: 0.5)
            .sink { [weak self] _ in
                guard let self else { return }
                input.send(.didTappedDirectoryPath(rootDirectoryID))
            }
            .store(in: &subscriptions)

        ascendingOrderButton.throttleTapPublisher(interval: 0.5)
            .sink { [weak self] _ in
                guard let self else { return }
                input.send(.toggleAscendingOrder)
            }
            .store(in: &subscriptions)
    }

    private func createUIMenu(sortBy: SortCriterias) -> UIMenu {
        var uiActions: [UIAction] = []

        for sortCriteria in SortCriterias.allCases {

            let uiAction = UIAction(title: sortCriteria.getUiActionTitle()) { action in
                self.input.send(.changeFileSortBy(sortCriteria))
                self.sortingButton.menu = self.createUIMenu(sortBy: sortCriteria)
            }

            if sortBy == sortCriteria {
                uiAction.image = UIImage(systemName: "checkmark")
            }

            uiActions.append(uiAction)
        }
        return UIMenu(children: uiActions)
    }

    private func moveToNextDirectory(directoryName: String, directoryID: UUID) {

        let lastItemIndex = collectionView.numberOfItems(inSection: .zero)
        let newIndexPath = IndexPath(item: lastItemIndex, section: .zero)

        let directoryPathLable: UIStackView = {
            let directoryPathLable = UIStackView()
            directoryPathLable.axis = .horizontal
            directoryPathLable.alignment = .center
            directoryPathLable.spacing = 5

            let imageView = UIImageView(image: UIImage(systemName: "chevron.forward"))
            imageView.tintColor = .systemGray4
            imageView.contentMode = .center
            imageView.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
            directoryPathLable.addArrangedSubview(imageView)

            let label = BasePaddingLabel()
            label.text = directoryName
            label.layer.cornerRadius = 5
            label.backgroundColor = .systemBlue
            label.clipsToBounds = true
            label.textColor = .white
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.isUserInteractionEnabled = true
            directoryPathLable.addArrangedSubview(label)

            return directoryPathLable
        }()

        directoryPathLable.throttleUIViewTapGesturePublisher(interval: 0.5)
            .sink { [weak self] _ in
                guard let self else { return }
                input.send(.didTappedDirectoryPath(directoryID))
            }
            .store(in: &subscriptions)

        directoryPathStackView.addArrangedSubview(directoryPathLable)

        collectionView.insertItems(at: [newIndexPath])
        collectionView.scrollToItem(at: newIndexPath, at: .right, animated: true)
    }

    private func movePreviousDirectoryTappedLabel(removedIndexList: [Int]) {
        removedIndexList.forEach { _ in
            directoryPathStackView.arrangedSubviews.last.map {
                directoryPathStackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        }

        let removeIndexPathList = removedIndexList.map { IndexPath(item: $0, section: 0) }
        collectionView.deleteItems(at: removeIndexPathList)
    }

    private func showFileInformation(for fileInformation: StorageItemInformationType) {

        switch fileInformation {
            case let info as DirectoryInformation:
                let view = DirectoryInformationPopupView(directoryInformation: info)
                view.delegate = self
                view.show()

            case let info as PageInformation:
                let view = PageInformationPopupView(pageInformation: info)
                view.delegate = self
                view.show()

            default:
                break
        }
    }

    private func changeRowFile(newName: String, before: Int, after: Int) {
        let lastItemIndex = collectionView.numberOfItems(inSection: .zero)
        let newIndexPath = IndexPath(item: lastItemIndex - 1, section: .zero)

        guard
            let collectionViewCell = collectionView.cellForItem(at: newIndexPath),
            let cell = collectionViewCell as? MemoHomeTableView,
            let tableCell = cell.directoryContentTableView.cellForRow(at: IndexPath(row: before, section: .zero)),
            let memoTableRow = tableCell as? MemoTableRowView
        else { return }

        memoTableRow.setFileNameLabelText(newName)
        cell.directoryContentTableView.moveRow(
            at: IndexPath(row: before, section: 0), to: IndexPath(row: after, section: 0))
    }

    private func insertRowToTable(collectionCellIndex: Int, tableCellIndices: [Int]) {
        if let collectionViewCell =
            collectionView
            .cellForItem(at: IndexPath(item: collectionCellIndex, section: 0)) as? MemoHomeTableView
        {

            collectionViewCell.directoryContentTableView.performBatchUpdates {
                let indexPaths = tableCellIndices.map { IndexPath(row: $0, section: 0) }
                collectionViewCell.directoryContentTableView.insertRows(at: indexPaths, with: .automatic)
            }
        }
    }

    private func didPerformDropOperationInFixedTable(
        indexOfCell: Int,
        insertRowIndexPaths: [IndexPath],
        deleteRowIndexPaths: [IndexPath]
    ) {
        let lastIndexPath = IndexPath(item: indexOfCell, section: 0)
        if let lastCell = collectionView.cellForItem(at: lastIndexPath) {
            let cell = lastCell as! MemoHomeTableView

            cell.directoryContentTableView.performBatchUpdates {
                cell.directoryContentTableView.deleteRows(at: deleteRowIndexPaths, with: .automatic)
            }
        }

        fixedFilesTableView.performBatchUpdates {
            fixedFilesTableView.insertRows(at: insertRowIndexPaths, with: .automatic)
        }
    }

    private func didPerformDropOperationInHomeTable(
        indexOfCell: Int,
        insertRowIndexPaths: [IndexPath], deleteRowIndexPaths: [IndexPath]
    ) {
        fixedFilesTableView.performBatchUpdates {
            fixedFilesTableView.deleteRows(at: deleteRowIndexPaths, with: .automatic)
        }

        let lastIndexPath = IndexPath(item: indexOfCell, section: 0)
        if let lastCell = collectionView.cellForItem(at: lastIndexPath) {
            let cell = lastCell as! MemoHomeTableView
            cell.directoryContentTableView.performBatchUpdates {
                cell.directoryContentTableView.insertRows(at: insertRowIndexPaths, with: .automatic)
            }
        }
    }

    private func resortFileTableRows(_ sortingReulst: [(Int, Int)]) {
        let lastItemIndex = collectionView.numberOfItems(inSection: .zero)
        let newIndexPath = IndexPath(item: lastItemIndex - 1, section: .zero)

        guard
            let collectionViewCell = collectionView.cellForItem(at: newIndexPath),
            let cell = collectionViewCell as? MemoHomeTableView
        else { return }

        cell.directoryContentTableView.performBatchUpdates {
            for (before, after) in sortingReulst {
                cell.directoryContentTableView.moveRow(
                    at: IndexPath(row: before, section: .zero),
                    to: IndexPath(row: after, section: .zero)
                )
            }
        }
    }
}

extension MemoHomeViewController: InformationPopupViewDelegate {
    func rename(fileID: UUID, newName: String) {
        input.send(.changeFileName(fileID, newName))
    }
}
