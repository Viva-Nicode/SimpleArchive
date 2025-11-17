import Combine
import UIKit

class MemoHomeViewController: UIViewController, ViewControllerType {

    typealias Input = MemoHomeViewInput
    typealias ViewModelType = MemoHomeViewModel

    var input = PassthroughSubject<MemoHomeViewInput, Never>()
    var viewModel: MemoHomeViewModel
    var subscriptions = Set<AnyCancellable>()
    private(set) var isActiveFileCreatePlusButton: Bool = false
    private(set) var directoryFileCount: Int = 0 {
        didSet {
            self.totalFileCountLabel.text = "\(directoryFileCount) files in total"
        }
    }

    private(set) var backgroundView: UIStackView = {
        let backgroundView = UIStackView()
        backgroundView.axis = .vertical
        backgroundView.spacing = 10
        backgroundView.backgroundColor = .systemBackground
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        return backgroundView
    }()

    // MARK: - Header Views
    private(set) var headerStackView: UIStackView = {
        let headerStackView = UIStackView()
        headerStackView.axis = .horizontal
        headerStackView.alignment = .center
        headerStackView.spacing = 21
        headerStackView.distribution = .fill
        headerStackView.isLayoutMarginsRelativeArrangement = true
        headerStackView.layoutMargins = .init(top: 10, left: 15, bottom: 10, right: 15)
        return headerStackView
    }()
    private(set) var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "Memo"
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textColor = .label
        return titleLabel
    }()
    private(set) var trashBoxButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "trash")
        config.baseForegroundColor = .systemBlue
        config.preferredSymbolConfigurationForImage = .init(pointSize: 20, weight: .regular)

        let button = UIButton(configuration: config)
        return button
    }()

    // MARK: - Fixed File Views
    private(set) var fixedFilesLable: BasePaddingLabel = {
        let fixedFilesLable = BasePaddingLabel(padding: .init(top: 0, left: 15, bottom: 0, right: 15))
        fixedFilesLable.text = "📌 Fixed Pages"
        fixedFilesLable.font = .boldSystemFont(ofSize: 21)
        fixedFilesLable.textColor = .label
        return fixedFilesLable
    }()
    private(set) var fixedFilesCollectionViewContainer: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIView())
    private(set) var fixedFilesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 90, height: 80)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 25

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInset = .init(top: 10, left: 10, bottom: 10, right: 10)
        collectionView.register(
            FixedFileItemView.self,
            forCellWithReuseIdentifier: FixedFileItemView.reuseIdentifier)
        collectionView.isPrefetchingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    // MARK: - Directory Path Views
    private(set) var rootDirectoryLable: UIStackView = {
        let directoryPathLabel = MemoHomeDirectoryNameLabel(name: "Home")
        directoryPathLabel.setHomePathLabel()
        return directoryPathLabel
    }()
    private(set) var directoryPathView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    private(set) var directoryPathStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 5
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = .init(top: 10, left: 15, bottom: 0, right: 15)
        stackView.axis = .horizontal
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // MARK: - FileSorting PullDown Button View
    private(set) var totalFileCountLabel: UILabel = {
        let totalFileCountLabel = UILabel()
        return totalFileCountLabel
    }()
    private(set) var sortingButtonView: UIStackView = {
        let sortingButtonView = UIStackView()
        sortingButtonView.axis = .horizontal
        sortingButtonView.alignment = .center
        sortingButtonView.spacing = 8
        sortingButtonView.isLayoutMarginsRelativeArrangement = true
        sortingButtonView.layoutMargins = .init(top: 0, left: 20, bottom: 0, right: 20)
        return sortingButtonView
    }()
    private(set) var separator: UILabel = {
        $0.text = "|"
        $0.textColor = .systemGray4
        return $0
    }(UILabel())
    private(set) var sortByNameLabel: UILabel = {
        $0.text = "name"
        $0.textColor = .systemGray4
        $0.isUserInteractionEnabled = true
        $0.font = .systemFont(ofSize: 16, weight: .regular)
        return $0
    }(UILabel())
    private(set) var sortByCreatedateLabel: UILabel = {
        $0.text = "create date"
        $0.textColor = .systemGray4
        $0.isUserInteractionEnabled = true
        $0.font = .systemFont(ofSize: 16, weight: .regular)
        return $0
    }(UILabel())

    // MARK: - Home File Views
    private(set) var directoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.accessibilityIdentifier = "memoHomeCollectionView"
        collectionView.register(
            MemoHomeDirectoryContentCell.self,
            forCellWithReuseIdentifier: MemoHomeDirectoryContentCell.reuseIdentifier)
        collectionView.isPrefetchingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        return collectionView
    }()

    // MARK: - Create Item Button
    private(set) var fileCreatePlusButton: UIView = {
        let image = UIImage(systemName: "plus")
        let buttonImageView = UIImageView(image: image)

        buttonImageView.translatesAutoresizingMaskIntoConstraints = false
        buttonImageView.tintColor = .white
        $0.addSubview(buttonImageView)

        buttonImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        buttonImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        buttonImageView.centerYAnchor.constraint(equalTo: $0.centerYAnchor).isActive = true
        buttonImageView.centerXAnchor.constraint(equalTo: $0.centerXAnchor).isActive = true

        $0.layer.cornerRadius = 27.5
        $0.backgroundColor = .systemBlue
        $0.layer.masksToBounds = false
        $0.translatesAutoresizingMaskIntoConstraints = false

        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = .init(width: -1.5, height: 1.5)
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowRadius = 4

        return $0
    }(UIView())
    private(set) var createFolderButton: UIView = {
        let image = UIImage(named: "folder-plus")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        let buttonImageView = UIImageView(image: image)

        buttonImageView.translatesAutoresizingMaskIntoConstraints = false
        buttonImageView.tintColor = .systemBlue
        $0.addSubview(buttonImageView)

        buttonImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        buttonImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        buttonImageView.centerYAnchor.constraint(equalTo: $0.centerYAnchor).isActive = true
        buttonImageView.centerXAnchor.constraint(equalTo: $0.centerXAnchor).isActive = true

        $0.alpha = 0
        $0.layer.cornerRadius = 27.5
        $0.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1)
        $0.layer.masksToBounds = false
        $0.translatesAutoresizingMaskIntoConstraints = false

        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = .init(width: -1.5, height: 1.5)
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowRadius = 4

        return $0
    }(UIView())
    private(set) var createPageButton: UIView = {
        let image = UIImage(named: "file-plus")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
        let buttonImageView = UIImageView(image: image)
        buttonImageView.translatesAutoresizingMaskIntoConstraints = false
        buttonImageView.tintColor = .systemBlue
        $0.addSubview(buttonImageView)

        buttonImageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        buttonImageView.heightAnchor.constraint(equalToConstant: 20).isActive = true
        buttonImageView.centerYAnchor.constraint(equalTo: $0.centerYAnchor).isActive = true
        buttonImageView.centerXAnchor.constraint(equalTo: $0.centerXAnchor).isActive = true

        $0.alpha = 0
        $0.layer.cornerRadius = 27.5
        $0.backgroundColor = UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1)
        $0.layer.masksToBounds = false
        $0.translatesAutoresizingMaskIntoConstraints = false

        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = .init(width: -1.5, height: 1.5)
        $0.layer.shadowOpacity = 0.2
        $0.layer.shadowRadius = 4
        return $0
    }(UIView())

    init(memoHomeViewModel: MemoHomeViewModel) {
        self.viewModel = memoHomeViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
                case let .didFetchMemoData(rootDirectoryID, sortCriteria, datasource, fileCount):
                    setupUI(fixedFileCollectionViewDataSource: datasource)
                    setupConstraints()
                    updateDirectoryInfo(fileCount: fileCount, sortCriteria: sortCriteria)
                    setupActions(rootDirectoryID)

                case .didInsertRowToHomeTable(let collectionCellIndex, let tableCellIndices):
                    insertRowToTable(collectionCellIndex: collectionCellIndex, tableCellIndices: tableCellIndices)

                case .didMoveFileToDormantBox(let removedFileIndex):
                    removeRowToTable(removedFileIndex: removedFileIndex)

                case let .didAppendPageToHomeTable(indexOfCell, insertRowIndexPaths, deleteRowIndexPaths):
                    didPerformDropOperationInHomeTable(
                        indexOfCell: indexOfCell,
                        insertRowIndexPaths: insertRowIndexPaths,
                        deleteRowIndexPaths: deleteRowIndexPaths)

                case let .didAppendPageToFixedTable(indexOfCell, insertRowIndexPaths, deleteRowIndexPaths):
                    didPerformDropOperationInFixedTable(
                        indexOfCell: indexOfCell,
                        insertRowIndexPaths: insertRowIndexPaths,
                        deleteRowIndexPaths: deleteRowIndexPaths)

                case let .didMovePreviousDirectoryPath(removedIndexList, sortCriteria, fileCount):
                    updateDirectoryInfo(fileCount: fileCount, sortCriteria: sortCriteria)
                    movePreviousDirectoryTappedLabel(removedIndexList: removedIndexList)

                case let .didMoveToFollowingDirectory(directoryName, directoryID, sortCriteria, fileCount):
                    updateDirectoryInfo(fileCount: fileCount, sortCriteria: sortCriteria)
                    moveToNextDirectory(directoryName: directoryName, directoryID: directoryID)

                case .didPresentFileInformationPopupView(let fileInformation):
                    showFileInformation(for: fileInformation)

                case .didNavigateDormantBoxView(let vm):
                    navigationController?.pushViewController(DormantBoxViewController(viewModel: vm), animated: true)

                case .didNavigatePageView(let vm):
                    navigationController?.pushViewController(MemoPageViewController(viewModel: vm), animated: true)

                case .didChangedFileName(let newName, let before, let after):
                    changeRowFile(newName: newName, before: before, after: after)

                case .didSortDirectoryItems(let sortingResult):
                    sortFileTableRows(sortingResult)

                case .didNavigateSingleTextEditorComponentPageView(let vm):
                    let singleTextEditorPageViewController = SingleTextEditorPageViewController(viewModel: vm)
                    navigationController?.pushViewController(singleTextEditorPageViewController, animated: true)

                case .didNavigateSingleTableComponentPageView(let vm):
                    let singleTablePageViewController = SingleTablePageViewController(viewModel: vm)
                    navigationController?.pushViewController(singleTablePageViewController, animated: true)

                case .didNavigateSingleAudioComponentPageView(let vm):
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
                        setupUI(fixedFileCollectionViewDataSource: nil)
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

    private func setupUI(fixedFileCollectionViewDataSource: FixedFileCollectionViewDataSource?) {
        view.backgroundColor = .systemBackground
        view.addSubview(backgroundView)

        backgroundView.addArrangedSubview(headerStackView)

        backgroundView.addArrangedSubview(fixedFilesLable)
        fixedFilesCollectionViewContainer.addSubview(fixedFilesCollectionView)
        backgroundView.addArrangedSubview(fixedFilesCollectionViewContainer)
        backgroundView.addArrangedSubview(directoryPathView)
        backgroundView.addArrangedSubview(sortingButtonView)
        backgroundView.addArrangedSubview(directoryCollectionView)

        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(trashBoxButton)

        sortingButtonView.addArrangedSubview(totalFileCountLabel)
        sortingButtonView.addArrangedSubview(UIView.spacerView)
        sortingButtonView.addArrangedSubview(sortByNameLabel)
        sortingButtonView.addArrangedSubview(separator)
        sortingButtonView.addArrangedSubview(sortByCreatedateLabel)

        directoryPathView.addSubview(directoryPathStackView)
        directoryPathStackView.addArrangedSubview(rootDirectoryLable)

        fixedFileCollectionViewDataSource?.input = input
        fixedFilesCollectionView.dataSource = fixedFileCollectionViewDataSource
        fixedFilesCollectionView.delegate = fixedFileCollectionViewDataSource
        fixedFilesCollectionView.dragDelegate = fixedFileCollectionViewDataSource
        fixedFilesCollectionView.dropDelegate = fixedFileCollectionViewDataSource

        directoryCollectionView.delegate = self
        directoryCollectionView.dataSource = viewModel
        directoryCollectionView.layoutIfNeeded()

        backgroundView.addSubview(createFolderButton)
        backgroundView.addSubview(createPageButton)
        backgroundView.addSubview(fileCreatePlusButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            fixedFilesCollectionViewContainer.heightAnchor.constraint(equalToConstant: 90),
            fixedFilesCollectionView.heightAnchor.constraint(equalToConstant: 100),
            fixedFilesCollectionView.centerXAnchor.constraint(equalTo: fixedFilesCollectionViewContainer.centerXAnchor),
            fixedFilesCollectionView.widthAnchor.constraint(equalToConstant: UIView.screenWidth - 30),

            directoryPathView.heightAnchor.constraint(equalToConstant: 40),

            directoryPathStackView.topAnchor.constraint(equalTo: directoryPathView.topAnchor),
            directoryPathStackView.bottomAnchor.constraint(equalTo: directoryPathView.bottomAnchor),
            directoryPathStackView.leadingAnchor.constraint(equalTo: directoryPathView.leadingAnchor),
            directoryPathStackView.trailingAnchor.constraint(equalTo: directoryPathView.trailingAnchor),

            fileCreatePlusButton.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -22),
            fileCreatePlusButton.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -70),
            fileCreatePlusButton.widthAnchor.constraint(equalToConstant: 55),
            fileCreatePlusButton.heightAnchor.constraint(equalToConstant: 55),

            createFolderButton.widthAnchor.constraint(equalToConstant: 55),
            createFolderButton.heightAnchor.constraint(equalToConstant: 55),
            createFolderButton.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -22),
            createFolderButton.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -70),

            createPageButton.widthAnchor.constraint(equalToConstant: 55),
            createPageButton.heightAnchor.constraint(equalToConstant: 55),
            createPageButton.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -22),
            createPageButton.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -70),
        ])
    }

    private func setupActions(_ rootDirectoryID: UUID) {

        fileCreatePlusButton.throttleUIViewTapGesturePublisher(interval: 0)
            .sink { [weak self] _ in
                guard let self else { return }
                tappedFileCreatePlusButton()
            }
            .store(in: &subscriptions)

        trashBoxButton.throttleTapPublisher()
            .sink { _ in self.input.send(.willNavigateDormantBoxView) }
            .store(in: &subscriptions)

        createFolderButton.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                tappedFileCreatePlusButton()

                let subject = PassthroughSubject<MemoHomeSubViewInput, Never>()
                viewModel.subscribe(input: subject.eraseToAnyPublisher())

                let popupView = NewDirectoryPopupView(subject: subject)
                popupView.show()
            }
            .store(in: &subscriptions)

        createPageButton.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                tappedFileCreatePlusButton()

                let subject = PassthroughSubject<MemoHomeSubViewInput, Never>()
                viewModel.subscribe(input: subject.eraseToAnyPublisher())

                let popupView = NewPagePopupView(subject: subject)
                popupView.show()
            }
            .store(in: &subscriptions)

        rootDirectoryLable.throttleUIViewTapGesturePublisher(interval: 0.5)
            .sink { [weak self] _ in
                guard let self else { return }
                input.send(.willMovePreviousDirectoryPath(rootDirectoryID))
            }
            .store(in: &subscriptions)

        sortByNameLabel.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                if sortByNameLabel.textColor == .label {
                    input.send(.willToggleAscendingOrder)
                } else {
                    sortByNameLabel.textColor = .label
                    sortByCreatedateLabel.textColor = .systemGray4
                    input.send(.willSortDirectoryItems(.name))
                }
            }
            .store(in: &subscriptions)

        sortByCreatedateLabel.throttleUIViewTapGesturePublisher()
            .sink { [weak self] _ in
                guard let self else { return }
                if sortByCreatedateLabel.textColor == .label {
                    input.send(.willToggleAscendingOrder)
                } else {
                    sortByCreatedateLabel.textColor = .label
                    sortByNameLabel.textColor = .systemGray4
                    input.send(.willSortDirectoryItems(.creationDate))
                }
            }
            .store(in: &subscriptions)
    }

    private func moveToNextDirectory(directoryName: String, directoryID: UUID) {

        let lastItemIndex = directoryCollectionView.numberOfItems(inSection: .zero)
        let newIndexPath = IndexPath(item: lastItemIndex, section: .zero)
        let directoryPathLable = MemoHomeDirectoryNameLabel(name: directoryName)
        directoryPathLable.setCurrentPathLabel()

        directoryPathLable.throttleUIViewTapGesturePublisher(interval: 0.5)
            .sink { [weak self] _ in
                guard let self else { return }
                input.send(.willMovePreviousDirectoryPath(directoryID))
            }
            .store(in: &subscriptions)

        if let last = directoryPathStackView.arrangedSubviews.last,
            let directoryPathLabel = last as? MemoHomeDirectoryNameLabel
        {
            directoryPathLabel.setmiddlePathLabel()
        }

        directoryPathStackView.addArrangedSubview(directoryPathLable)
        DispatchQueue.main.async {
            self.directoryPathView.scrollToTrailing(animated: true)
        }
        directoryCollectionView.insertItems(at: [newIndexPath])
        directoryCollectionView.scrollToItem(at: newIndexPath, at: .right, animated: true)
    }

    private func updateDirectoryInfo(fileCount: Int, sortCriteria: SortCriterias) {
        directoryFileCount = fileCount
        switch sortCriteria {
            case .name:
                sortByNameLabel.textColor = .label
                sortByCreatedateLabel.textColor = .systemGray4
            case .creationDate:
                sortByCreatedateLabel.textColor = .label
                sortByNameLabel.textColor = .systemGray4
        }
    }

    private func movePreviousDirectoryTappedLabel(removedIndexList: [Int]) {
        removedIndexList.forEach { _ in
            directoryPathStackView.arrangedSubviews.last.map {
                directoryPathStackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
        }

        if let last = directoryPathStackView.arrangedSubviews.last,
            let directoryPathLabel = last as? MemoHomeDirectoryNameLabel
        {
            directoryPathLabel.setCurrentPathLabel()
        }

        let removeIndexPathList = removedIndexList.map { IndexPath(item: $0, section: 0) }
        directoryCollectionView.deleteItems(at: removeIndexPathList)
    }

    private func showFileInformation(for fileInformation: StorageItemInformationType) {

        switch fileInformation {
            case let info as DirectoryInformation:
                let directoryInformationPopupView = DirectoryInformationPopupView(directoryInformation: info)
                directoryInformationPopupView.confirmButtonPublisher
                    .sink { [weak self] directoryID, newName in
                        if let directoryID, let newName {
                            self?.input.send(.willChangeFileName(directoryID, newName))
                        }
                    }
                    .store(in: &subscriptions)

                directoryInformationPopupView.show()

            case let info as PageInformation:
                let pageInformationPopupView = PageInformationPopupView(pageInformation: info)
                pageInformationPopupView.confirmButtonPublisher
                    .sink { [weak self] pageID, newName in
                        if let pageID, let newName {
                            self?.input.send(.willChangeFileName(pageID, newName))
                        }
                    }
                    .store(in: &subscriptions)

                pageInformationPopupView.show()

            default:
                break
        }
    }

    private func changeRowFile(newName: String, before: Int, after: Int) {
        let lastItemIndex = directoryCollectionView.numberOfItems(inSection: .zero)
        let newIndexPath = IndexPath(item: lastItemIndex - 1, section: .zero)
        let beforeRowIndexPath = IndexPath(row: 0, section: before)

        guard
            let collectionViewCell = directoryCollectionView.cellForItem(at: newIndexPath),
            let cell = collectionViewCell as? MemoHomeDirectoryContentCell,
            let tableCell = cell.directoryContentTableView.cellForRow(at: beforeRowIndexPath),
            let memoTableRow = tableCell as? DirectoryFileItemRowView
        else { return }

        memoTableRow.setFileNameLabelText(newName)
        cell.directoryContentTableView.moveSection(before, toSection: after)
    }

    private func insertRowToTable(collectionCellIndex: Int, tableCellIndices: [Int]) {
        directoryFileCount += tableCellIndices.count
        if let collectionViewCell =
            directoryCollectionView
            .cellForItem(at: IndexPath(item: collectionCellIndex, section: 0)) as? MemoHomeDirectoryContentCell
        {
            collectionViewCell.insertItem(indices: tableCellIndices)
        }
    }

    private func removeRowToTable(removedFileIndex: Int) {
        directoryFileCount -= 1
        let lastItemIndex = directoryCollectionView.numberOfItems(inSection: .zero)
        let newIndexPath = IndexPath(item: lastItemIndex - 1, section: .zero)

        guard
            let collectionViewCell = directoryCollectionView.cellForItem(at: newIndexPath),
            let cell = collectionViewCell as? MemoHomeDirectoryContentCell
        else { return }
        cell.deleteItem(with: removedFileIndex)
    }

    private func didPerformDropOperationInFixedTable(
        indexOfCell: Int,
        insertRowIndexPaths: [IndexPath],
        deleteRowIndexPaths: [IndexPath]
    ) {
        directoryFileCount -= 1
        let lastIndexPath = IndexPath(item: indexOfCell, section: 0)
        if let lastCell = directoryCollectionView.cellForItem(at: lastIndexPath),
            let cell = lastCell as? MemoHomeDirectoryContentCell
        {
            cell.directoryContentTableView.performBatchUpdates {
                for path in deleteRowIndexPaths {
                    cell.directoryContentTableView.deleteSections(.init(integer: path.section), with: .fade)
                }
            }
            cell.showEmptyFolderView()
        }

        fixedFilesCollectionView.performBatchUpdates {
            fixedFilesCollectionView.insertItems(at: insertRowIndexPaths)
        }
    }

    private func didPerformDropOperationInHomeTable(
        indexOfCell: Int,
        insertRowIndexPaths: [IndexPath],
        deleteRowIndexPaths: [IndexPath]
    ) {
        directoryFileCount += 1
        fixedFilesCollectionView.performBatchUpdates {
            fixedFilesCollectionView.deleteItems(at: deleteRowIndexPaths)
        }

        let lastIndexPath = IndexPath(item: indexOfCell, section: 0)

        if let lastCell = directoryCollectionView.cellForItem(at: lastIndexPath) {
            let cell = lastCell as! MemoHomeDirectoryContentCell
            cell.removeEmptyFolderView()
            cell.directoryContentTableView.performBatchUpdates {
                for path in insertRowIndexPaths {
                    cell.directoryContentTableView.insertSections(.init(integer: path.section), with: .automatic)
                }
            }
        }
    }

    private func sortFileTableRows(_ sortingReulst: [(Int, Int)]) {
        let lastItemIndex = directoryCollectionView.numberOfItems(inSection: .zero)
        let newIndexPath = IndexPath(item: lastItemIndex - 1, section: .zero)

        guard
            let collectionViewCell = directoryCollectionView.cellForItem(at: newIndexPath),
            let cell = collectionViewCell as? MemoHomeDirectoryContentCell
        else { return }

        cell.directoryContentTableView.performBatchUpdates {
            for (before, after) in sortingReulst {
                cell.directoryContentTableView.moveSection(before, toSection: after)
            }
        }
    }

    private func tappedFileCreatePlusButton() {
        isActiveFileCreatePlusButton.toggle()

        let angle: CGFloat = isActiveFileCreatePlusButton ? .pi / 4 : 0

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.8,
            options: [.curveEaseInOut]
        ) { [weak self] in
            guard let self else { return }

            fileCreatePlusButton.transform = CGAffineTransform(rotationAngle: angle)
            createFolderButton.alpha = isActiveFileCreatePlusButton ? 1 : 0
            createPageButton.alpha = isActiveFileCreatePlusButton ? 1 : 0

            if isActiveFileCreatePlusButton {
                createFolderButton.frame.origin.y -= 70
                createPageButton.frame.origin.y -= 140
            } else {
                createFolderButton.frame.origin.y += 70
                createPageButton.frame.origin.y += 140
            }
        }
    }
}

extension MemoHomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize { collectionView.bounds.size }
}
