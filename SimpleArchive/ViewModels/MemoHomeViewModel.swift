import Combine
import UIKit

@MainActor
final class MemoHomeViewModel: NSObject, ViewModelType {

    typealias Input = MemoHomeViewInput
    typealias Output = MemoHomeViewOutput

    private var output = PassthroughSubject<MemoHomeViewOutput, Never>()
    private var errorOutput = PassthroughSubject<MemoHomeViewModelError, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private(set) var directoryStack: [MemoDirectoryModel] = []
    private(set) var fixedFileDirectory: MemoDirectoryModel!

    private var memoDirectoryCoredataReposotory: MemoDirectoryCoreDataRepositoryType
    private var memoPageCoredataReposotory: MemoPageCoreDataRepositoryType

    private let directoryCreator: any FileCreatorType
    private let pageCreator: any PageCreatorType

    private var restoredPageListSubject = PassthroughSubject<[MemoPageModel], Never>()
    private var restoredPageListSubjectSubscription: AnyCancellable?

    private var selectedTableindexToCheckFileInformation: Int?
    private var fixedFileCollectionViewDataSource: FixedFileCollectionViewDataSource!
    private var memoHomeDirectoryContentCellDataSources: [UUID: MemoHomeDirectoryContentCellDataSource] = [:]

    init(
        memoDirectoryCoredataReposotory: MemoDirectoryCoreDataRepositoryType,
        memoPageCoredataReposotory: MemoPageCoreDataRepositoryType,
        directoryCreator: any FileCreatorType,
        pageCreator: any PageCreatorType
    ) {
        self.memoDirectoryCoredataReposotory = memoDirectoryCoredataReposotory
        self.memoPageCoredataReposotory = memoPageCoredataReposotory
        self.directoryCreator = directoryCreator
        self.pageCreator = pageCreator
        super.init()
    }

    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad:
                    fetchMemoData()

                case .willMovePreviousDirectoryPath(let targetDirId):
                    moveToPreviousDirectory(destinationDirectoryID: targetDirId)

                case .willNavigateDormantBoxView:
                    getDormantBoxViewModel()

                case .willAppendPageToFixedTable(let dropedPages):
                    fixPage(with: dropedPages)

                case .willChangeFileName(let fileID, let newName):
                    changeFileName(fileID: fileID, newName: newName)

                case .willNavigateFixedPageView(let pageIndex):
                    let followingPage = fixedFileDirectory[pageIndex] as! MemoPageModel
                    moveToPage(followingPage: followingPage)

                case .willSortDirectoryItems(let sortBy):
                    changeSortCriteria(sortBy: sortBy)

                case .willToggleAscendingOrder:
                    toggleAscendingOrder()
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    func subscribe(input: AnyPublisher<MemoHomeSubViewInput, Never>) {
        input.sink { [weak self] subViewEvent in
            guard let self else { return }

            switch subViewEvent {
                case .willCreatedNewDirectory(let newDirectoryName):
                    createdNewDirectory(newDirectoryName)

                case .willCreatedNewPage(let newPageName, let type):
                    createdNewPage(newPageName, singleComponentType: type)

                case .willMoveToFollowingDirectory(let index):
                    moveToFollowingDirectory(index: index)

                case .willNavigatePageView(let pageIndex):
                    let followingPage = directoryStack.last![pageIndex] as! MemoPageModel
                    moveToPage(followingPage: followingPage)

                case .willPresentFileInformationPopupView(let fileIndex):
                    showFileInformation(fileIndexToShowInformation: fileIndex)

                case .willMoveFileToDormantBox(let fileIndexToDelete):
                    moveFileToDormantBox(idx: fileIndexToDelete)

                case .willAppendPageToHomeTable(let dropedPages):
                    unfixPage(with: dropedPages)
            }
        }
        .store(in: &subscriptions)
    }

    func errorSubscribe() -> AnyPublisher<MemoHomeViewModelError, Never> {
        errorOutput.eraseToAnyPublisher()
    }

    private func fetchMemoData() {
        memoDirectoryCoredataReposotory.fetchSystemDirectoryEntities(fileCreator: directoryCreator)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        self.errorOutput.send(.canNotLoadMemoData)
                    }
                },
                receiveValue: { systemDirectories in
                    self.directoryStack = [systemDirectories[.mainDirectory]!]
                    self.fixedFileDirectory = systemDirectories[.fixedFileDirectory]
                    self.fixedFileCollectionViewDataSource =
                        FixedFileCollectionViewDataSource(fixedFileDirectory: self.fixedFileDirectory)
                    self.output.send(
                        .didFetchMemoData(
                            self.directoryStack.first!.id,
                            self.directoryStack.first!.getSortBy(),
                            self.fixedFileCollectionViewDataSource,
                            systemDirectories[.mainDirectory]!.getChildItemSize()
                        )
                    )
                }
            )
            .store(in: &subscriptions)
    }

    private func createdNewDirectory(_ newDirectoryName: String) {
        let newDirectory = directoryCreator.createFile(
            itemName: newDirectoryName,
            parentDirectory: directoryStack.last!)
        let insertedIndex = directoryStack.last![newDirectory.id]!.index

        memoDirectoryCoredataReposotory.createStorageItem(storageItem: newDirectory)
        output.send(.didInsertRowToHomeTable(directoryStack.count - 1, [insertedIndex]))
    }

    private func createdNewPage(_ newPageName: String, singleComponentType: ComponentType? = nil) {
        if let singleComponentType {
            pageCreator.setFirstComponentType(type: singleComponentType)
            let newPage = pageCreator.createFile(
                itemName: newPageName,
                parentDirectory: directoryStack.last!,
                singleComponentType: singleComponentType)
            let insertedIndex = directoryStack.last![newPage.id]!.index

            memoDirectoryCoredataReposotory.createStorageItem(storageItem: newPage)
            output.send(.didInsertRowToHomeTable(directoryStack.count - 1, [insertedIndex]))
        } else {
            pageCreator.setFirstComponentType(type: .text)
            let newPage = pageCreator.createFile(itemName: newPageName, parentDirectory: directoryStack.last!)
            let insertedIndex = directoryStack.last![newPage.id]!.index

            memoDirectoryCoredataReposotory.createStorageItem(storageItem: newPage)
            output.send(.didInsertRowToHomeTable(directoryStack.count - 1, [insertedIndex]))
        }
    }

    private func moveToFollowingDirectory(index: Int) {
        let followingDirectory = directoryStack.last![index] as! MemoDirectoryModel
        directoryStack.append(followingDirectory)
        output.send(
            .didMoveToFollowingDirectory(
                followingDirectory.name,
                followingDirectory.id,
                followingDirectory.getSortBy(),
                followingDirectory.getChildItemSize()
            )
        )
    }

    private func moveToPreviousDirectory(destinationDirectoryID: UUID) {
        let destinationDirectoryIndex = directoryStack.firstIndex(where: { $0.id == destinationDirectoryID })!
        guard destinationDirectoryIndex < directoryStack.count - 1 else { return }

        let directoryStackLastIndex = directoryStack.count - 1
        directoryStack.removeLast(directoryStackLastIndex - destinationDirectoryIndex)

        output.send(
            .didMovePreviousDirectoryPath(
                Array(((destinationDirectoryIndex + 1)...directoryStackLastIndex)),
                directoryStack.last!.getSortBy(),
                directoryStack.last!.getChildItemSize()
            )
        )
    }

    private func moveToPage(followingPage: MemoPageModel) {
        if followingPage.isSingleComponentPage {
            if let textEditorComponent = followingPage.getComponents.first as? TextEditorComponent {
                DIContainer.shared.setArgument(TextEditorComponentViewModel.self, textEditorComponent)
                let viewModel = DIContainer.shared.resolve(TextEditorComponentViewModel.self)
                output.send(.didNavigateSingleTextEditorComponentPageView(viewModel))
            } else if let singleTableComponent = followingPage.getComponents.first as? TableComponent {
                DIContainer.shared.setArgument(SingleTablePageViewModel.self, singleTableComponent)
                DIContainer.shared.setArgument(SingleTablePageViewModel.self, followingPage.name)
                let singleTablePageViewModel = DIContainer.shared.resolve(SingleTablePageViewModel.self)
                output.send(.didNavigateSingleTableComponentPageView(singleTablePageViewModel))
            } else if let singleAudioComponent = followingPage.getComponents.first as? AudioComponent {
                DIContainer.shared.setArgument(SingleAudioPageViewModel.self, singleAudioComponent)
                DIContainer.shared.setArgument(SingleAudioPageViewModel.self, followingPage.name)
                let singleAudioPageViewModel = DIContainer.shared.resolve(SingleAudioPageViewModel.self)
                output.send(.didNavigateSingleAudioComponentPageView(singleAudioPageViewModel))
            }
        } else {
            DIContainer.shared.setArgument(MemoPageViewModel.self, followingPage)
            let memoPageViewModel = DIContainer.shared.resolve(MemoPageViewModel.self)
			
            output.send(.didNavigatePageView(memoPageViewModel))
        }
    }

    private func showFileInformation(fileIndexToShowInformation: Int) {
        let file = directoryStack.last![fileIndexToShowInformation]!
        selectedTableindexToCheckFileInformation = fileIndexToShowInformation
        output.send(.didPresentFileInformationPopupView(file.getFileInformation()))
    }

    private func moveFileToDormantBox(idx fileIndexToDelete: Int) {
        let targetItem = directoryStack.last![fileIndexToDelete]!
        targetItem.removeStorageItem()
        memoDirectoryCoredataReposotory.moveFileToDormantBox(fileID: targetItem.id)
        output.send(.didMoveFileToDormantBox(fileIndexToDelete))
    }

    private func getDormantBoxViewModel() {
        restoredPageListSubjectSubscription =
            restoredPageListSubject
            .sink { [weak self] restoredPageList in
                guard let self else { return }

                for page in restoredPageList {
                    page.parentDirectory = directoryStack.first!
                    page.parentDirectory?.insertChildItem(item: page)
                }

                let insertedIndices = restoredPageList.map { self.directoryStack.first![$0.id]!.index }
                output.send(.didInsertRowToHomeTable(.zero, insertedIndices))
            }

        DIContainer.shared.setArgument(DormantBoxViewModel.self, restoredPageListSubjectSubscription)
        let dormantBoxViewModel = DIContainer.shared.resolve(DormantBoxViewModel.self)

        output.send(.didNavigateDormantBoxView(dormantBoxViewModel))
    }

    private func fixPage(with dropedPageIdsInFixedTable: [UUID]) {
        memoPageCoredataReposotory.fixPages(pageIds: dropedPageIdsInFixedTable)

        var insertRowIndexPaths = [IndexPath]()
        var deleteRowIndexPaths = [IndexPath]()

        for pageId in dropedPageIdsInFixedTable {
            if let page = directoryStack.last![pageId] {

                deleteRowIndexPaths.append(IndexPath(row: 0, section: page.index))
                let deletedPage = directoryStack.last!.removeChildItemByID(with: pageId)

                if let deletedPage {
                    deletedPage.parentDirectory = nil
                    deletedPage.parentDirectory = fixedFileDirectory
                    deletedPage.parentDirectory?.insertChildItem(item: deletedPage)
                }
            }

            if let item = fixedFileDirectory[pageId] {
                insertRowIndexPaths.append(IndexPath(item: item.index, section: 0))
            }
        }
        output.send(
            .didAppendPageToFixedTable(
                directoryStack.count - 1,
                insertRowIndexPaths,
                deleteRowIndexPaths
            )
        )
    }

    private func unfixPage(with dropedpagesInHomeTable: [UUID]) {
        memoPageCoredataReposotory.unfixPages(
            parentDirectoryId: directoryStack.last!.id,
            pageIds: dropedpagesInHomeTable)

        var insertRowIndexPaths = [IndexPath]()
        var deleteRowIndexPaths = [IndexPath]()

        for pageId in dropedpagesInHomeTable {
            if let item = fixedFileDirectory[pageId] {
                deleteRowIndexPaths.append(IndexPath(item: item.index, section: .zero))
                let removedPage = fixedFileDirectory.removeChildItemByID(with: item.item.id)

                if let removedPage {
                    removedPage.parentDirectory = nil
                    removedPage.parentDirectory = directoryStack.last!
                    removedPage.parentDirectory?.insertChildItem(item: removedPage)
                }
            }

            if let item = directoryStack.last?[pageId] {
                insertRowIndexPaths.append(IndexPath(row: 0, section: item.index))
            }
        }
        output.send(
            .didAppendPageToHomeTable(
                directoryStack.count - 1,
                insertRowIndexPaths,
                deleteRowIndexPaths
            )
        )
    }

    private func changeFileName(fileID: UUID, newName: String) {
        guard
            let directory = directoryStack.last,
            let fileIndexBeforeRename = selectedTableindexToCheckFileInformation
        else { return }

        memoDirectoryCoredataReposotory.saveFileNameChange(fileID: fileID, newName: newName)
        let fileIndexAfterRename = directory.renameChildFile(fileID: fileID, newName: newName)!
        output.send(.didChangedFileName(newName, fileIndexBeforeRename, fileIndexAfterRename))
    }

    private func changeSortCriteria(sortBy: DirectoryContentsSortCriterias) {
        let sortingResult = directoryStack.last!.setSortCriteria(sortBy)

        memoDirectoryCoredataReposotory.saveFileSortCriteria(
            fileID: directoryStack.last!.id, newSortCriteria: sortBy)
        output.send(.didSortDirectoryItems(sortingResult))
    }

    private func toggleAscendingOrder() {
        let sortingResult = directoryStack.last!.toggleAscending()
        output.send(.didSortDirectoryItems(sortingResult))
    }
}

extension MemoHomeViewModel: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        directoryStack.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell =
            collectionView.dequeueReusableCell(
                withReuseIdentifier: MemoHomeDirectoryContentCell.reuseIdentifier,
                for: indexPath) as! MemoHomeDirectoryContentCell
        let subject = PassthroughSubject<MemoHomeSubViewInput, Never>()

        subscribe(input: subject.eraseToAnyPublisher())

        let datasourceContent = directoryStack[indexPath.item]
        let datasource = MemoHomeDirectoryContentCellDataSource(
            directoryContents: datasourceContent,
            input: subject)
        memoHomeDirectoryContentCellDataSources[datasourceContent.id] = datasource
        cell.configure(datasource: datasource)
        return cell
    }
}

#if DEBUG
    extension MemoHomeViewModel {
        func setDirectoryStack(with directoryStack: [MemoDirectoryModel]) {
            self.directoryStack = directoryStack
        }

        func setFixedFileDirectory(with fixedDirectory: MemoDirectoryModel) {
            self.fixedFileDirectory = fixedDirectory
        }
    }
#endif
