import Combine
import UIKit

@MainActor class MemoHomeViewModel: NSObject, ViewModelType {

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
    private let pageCreator: PageCreator

    private var restoredPageListSubject = PassthroughSubject<[MemoPageModel], Never>()
    private var restoredPageListSubjectSubscription: AnyCancellable?

    private var selectedTableindexToCheckFileInformation: Int?

    init(
        memoDirectoryCoredataReposotory: MemoDirectoryCoreDataRepositoryType,
        memoPageCoredataReposotory: MemoPageCoreDataRepositoryType,
        directoryCreator: any FileCreatorType,
        pageCreator: PageCreator
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

                case .didTappedDirectoryPath(let targetDirId):
                    moveToPreviousDirectory(destinationDirectoryID: targetDirId)

                case .getDormantBoxViewModel:
                    getDormantBoxViewModel()

                case .didPerformDropOperationInFixedTable(let dropedPages):
                    fixPage(with: dropedPages)

                case .changeFileName(let fileID, let newName):
                    changeFileName(fileID: fileID, newName: newName)

                case .didTappedFixedPageRow(let pageIndex):
                    moveToFixedPage(followingPageIndex: pageIndex)

                case .changeFileSortBy(let sortBy):
                    changeSortCriteria(sortBy: sortBy)

                case .toggleAscendingOrder:
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
                case .didCreatedNewDirectory(let newDirectoryName):
                    createdNewDirectory(newDirectoryName)

                case .didCreatedNewPage(let newPageName, let type):
                    createdNewPage(newPageName, singleComponentType: type)

                case .didTappedDirectoryRow(let index):
                    moveToFollowingDirectory(index: index)

                case .didTappedPageRow(let index):
                    moveToPage(followingPageIndex: index)

                case .showFileInformation(let fileIndex):
                    showFileInformation(fileIndexToShowInformation: fileIndex)

                case .removeFile(let fileIndexToDelete):
                    moveFileToDormantBox(idx: fileIndexToDelete)

                case .didPerformDropOperationInHomeTable(let dropedPages):
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
                    self.output.send(
                        .didfetchMemoData(self.directoryStack.first!.id, self.directoryStack.first!.getSortBy())
                    )
                }
            )
            .store(in: &subscriptions)
    }

    private func createdNewDirectory(_ newDirectoryName: String) {
        let newDirectory = directoryCreator.createFile(
            itemName: newDirectoryName, parentDirectory: directoryStack.last!)
        let insertedIndex = directoryStack.last![newDirectory.id]!.index

        memoDirectoryCoredataReposotory.createStorageItem(storageItem: newDirectory)
        output.send(.insertRowToTable(directoryStack.count - 1, [insertedIndex]))
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
            output.send(.insertRowToTable(directoryStack.count - 1, [insertedIndex]))
        } else {
            pageCreator.setFirstComponentType(type: .text)
            let newPage = pageCreator.createFile(itemName: newPageName, parentDirectory: directoryStack.last!)
            let insertedIndex = directoryStack.last![newPage.id]!.index

            memoDirectoryCoredataReposotory.createStorageItem(storageItem: newPage)
            output.send(.insertRowToTable(directoryStack.count - 1, [insertedIndex]))
        }
    }

    private func moveToFollowingDirectory(index: Int) {
        let followingDirectory = directoryStack.last![index] as! MemoDirectoryModel
        directoryStack.append(followingDirectory)
        output.send(
            .didTappedDirectoryRow(
                followingDirectory.name,
                followingDirectory.id,
                followingDirectory.getSortBy())
        )
    }

    private func moveToPage(followingPageIndex: Int) {
        guard
            let memoComponentCoreDataRepository = DIContainer.shared.resolve(MemoComponentCoreDataRepository.self),
            let componentFactory = DIContainer.shared.resolve(ComponentFactory.self)
        else { return }

        let followingPage = directoryStack.last![followingPageIndex] as! MemoPageModel

        if followingPage.isSingleComponentPage {
            if let singleTextEditorComponent = followingPage.getComponents.first as? TextEditorComponent {
                let vm = SingleTextEditorPageViewModel(
                    coredataReposotory: memoComponentCoreDataRepository,
                    textEditorComponent: singleTextEditorComponent,
                    pageTitle: followingPage.name)
                output.send(.presentSingleTextEditorComponentPage(vm))
            } else if let singleTableComponent = followingPage.getComponents.first as? TableComponent {
                let vm = SingleTablePageViewModel(
                    coredataReposotory: memoComponentCoreDataRepository,
                    tableComponent: singleTableComponent,
                    pageTitle: followingPage.name)
                output.send(.presentSingleTableComponentPage(vm))
            } else if let singleAudioComponent = followingPage.getComponents.first as? AudioComponent {
                let vm = SingleAudioPageViewModel(
                    coredataReposotory: memoComponentCoreDataRepository,
                    audioComponent: singleAudioComponent,
                    pageTitle: followingPage.name)
                output.send(.presentSingleAudioComponentPage(vm))
            }
        } else {
            let memoPageViewModel = MemoPageViewModel(
                componentFactory: componentFactory,
                memoComponentCoredataReposotory: memoComponentCoreDataRepository,
                page: followingPage)

            output.send(.getMemoPageViewModel(memoPageViewModel))
        }
    }

    private func moveToPreviousDirectory(destinationDirectoryID: UUID) {
        let destinationDirectoryIndex = directoryStack.firstIndex(where: { $0.id == destinationDirectoryID })!
        guard destinationDirectoryIndex < directoryStack.count - 1 else { return }

        let directoryStackLastIndex = directoryStack.count - 1
        directoryStack.removeLast(directoryStackLastIndex - destinationDirectoryIndex)

        output.send(
            .didTappedDirectoryPath(
                Array(((destinationDirectoryIndex + 1)...directoryStackLastIndex)),
                directoryStack.last!.getSortBy())
        )
    }

    private func moveToFixedPage(followingPageIndex: Int) {
        guard
            let memoComponentCoreDataRepository = DIContainer.shared.resolve(MemoComponentCoreDataRepository.self),
            let componentFactory = DIContainer.shared.resolve(ComponentFactory.self)
        else { return }

        let followingPage = fixedFileDirectory[followingPageIndex] as! MemoPageModel
        let memoPageViewModel = MemoPageViewModel(
            componentFactory: componentFactory,
            memoComponentCoredataReposotory: memoComponentCoreDataRepository,
            page: followingPage)

        output.send(.getMemoPageViewModel(memoPageViewModel))
    }

    private func showFileInformation(fileIndexToShowInformation: Int) {
        let file = directoryStack.last![fileIndexToShowInformation]!
        selectedTableindexToCheckFileInformation = fileIndexToShowInformation
        output.send(.showFileInformation(file.getFileInformation()))
    }

    private func moveFileToDormantBox(idx fileIndexToDelete: Int) {
        let targetItem = directoryStack.last![fileIndexToDelete]!
        targetItem.removeStorageItem()
        memoDirectoryCoredataReposotory.moveFileToDormantBox(fileID: targetItem.id)
    }

    private func getDormantBoxViewModel() {
        guard let dormantBoxCoreDataRepository = DIContainer.shared.resolve(DormantBoxCoreDataRepository.self)
        else { return }

        let dormantBoxViewModel = DormantBoxViewModel(
            dormantBoxCoredataRepository: dormantBoxCoreDataRepository,
            restoredPageListSubject: restoredPageListSubject)

        restoredPageListSubjectSubscription =
            restoredPageListSubject
            .sink { [weak self] restoredPageList in
                guard let self else { return }

                for page in restoredPageList {
                    page.parentDirectory = directoryStack.first!
                    page.parentDirectory?.insertChildItem(item: page)
                }

                let insertedIndices = restoredPageList.map { self.directoryStack.first![$0.id]!.index }
                output.send(.insertRowToTable(.zero, insertedIndices))
            }
        output.send(.moveDoramntBoxView(dormantBoxViewModel))
    }

    private func fixPage(with dropedPagesInFixedTable: [MemoPageModel]) {

        memoPageCoredataReposotory.fixPages(pageIds: dropedPagesInFixedTable.map { $0.id })

        var insertRowIndexPaths = [IndexPath]()
        var deleteRowIndexPaths = [IndexPath]()

        for page in dropedPagesInFixedTable {

            if let item = directoryStack.last![page.id] {
                deleteRowIndexPaths.append(IndexPath(row: item.index, section: .zero))
                let deletedPage = directoryStack.last!.removeChildItemByID(with: item.item.id)
                deletedPage?.parentDirectory = nil
            }

            page.parentDirectory = fixedFileDirectory
            page.parentDirectory?.insertChildItem(item: page)

            if let item = fixedFileDirectory[page.id] {
                insertRowIndexPaths.append(IndexPath(row: item.index, section: .zero))
            }
        }
        output.send(
            .didPerformDropOperationInFixedTable(directoryStack.count - 1, insertRowIndexPaths, deleteRowIndexPaths))
    }

    private func unfixPage(with dropedpagesInHomeTable: [MemoPageModel]) {
        memoPageCoredataReposotory.unfixPages(
            parentDirectoryId: directoryStack.last!.id,
            pageIds: dropedpagesInHomeTable.map { $0.id })

        var insertRowIndexPaths = [IndexPath]()
        var deleteRowIndexPaths = [IndexPath]()

        for page in dropedpagesInHomeTable {
            if let item = fixedFileDirectory[page.id] {
                deleteRowIndexPaths.append(IndexPath(row: item.index, section: .zero))
                let removedPage = fixedFileDirectory.removeChildItemByID(with: item.item.id)
                removedPage?.parentDirectory = nil
            }

            page.parentDirectory = directoryStack.last!
            page.parentDirectory?.insertChildItem(item: page)

            if let item = page.parentDirectory?[page.id] {
                insertRowIndexPaths.append(IndexPath(row: item.index, section: .zero))
            }
        }
        output.send(
            .didPerformDropOperationInHomeTable(directoryStack.count - 1, insertRowIndexPaths, deleteRowIndexPaths))
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

    private func changeSortCriteria(sortBy: SortCriterias) {
        let sortingResult = directoryStack.last!.setSortCriteria(sortBy)

        memoDirectoryCoredataReposotory.saveFileSortCriteria(
            fileID: directoryStack.last!.id, newSortCriteria: sortBy)
        output.send(.didChangeSortCriteria(sortingResult))
    }

    private func toggleAscendingOrder() {
        let sortingResult = directoryStack.last!.toggleAscending()
        output.send(.didChangeSortCriteria(sortingResult))
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
