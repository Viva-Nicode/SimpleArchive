import UIKit
import Combine

@MainActor class DormantBoxViewModel: NSObject, ViewModelType {

    typealias Input = DormantBoxViewInput
    typealias Output = DormantBoxViewOutput

    private var output = PassthroughSubject<DormantBoxViewOutput, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private var dormantBoxCoredataRepository: DormantBoxCoreDataRepositoryType
    private var dormantBoxDirectory: MemoDirectoryModel!

    private var restoredPageListSubject: PassthroughSubject<[MemoPageModel], Never>
    private var restoredPageList: [MemoPageModel] = []

    init(
        dormantBoxCoredataRepository: DormantBoxCoreDataRepositoryType,
        restoredPageListSubject: PassthroughSubject<[MemoPageModel], Never>
    ) {
        self.dormantBoxCoredataRepository = dormantBoxCoredataRepository
        self.restoredPageListSubject = restoredPageListSubject
    }

    deinit {
        print("DormantBoxViewModel deinit")
        subscriptions.removeAll()
        restoredPageListSubject.send(restoredPageList)
    }

    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
            case .viewDidLoad:
                fetchDormantBoxDirectory()

            case .showFileInformation(let index):
                let item = dormantBoxDirectory[index]!
                showFileInformation(file: item)

            case .restoreFile(let index):
                let item = dormantBoxDirectory[index]!
                restoreFile(file: item)

            case .moveToPage(let index):
                moveToPage(followingPageIndex: index)
            }
        }.store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func fetchDormantBoxDirectory() {
        dormantBoxCoredataRepository.fetchDormantBoxDirectory()
            .sink(
            receiveCompletion: { _ in },
            receiveValue: { [weak self] value in
                guard let self else { return }
                dormantBoxDirectory = value
                output.send(.didfetchMemoData)
            }
        ).store(in: &subscriptions)
    }

    private func moveToPage(followingPageIndex: Int) {
        guard
            let memoComponentCoreDataRepository = DIContainer.shared.resolve(MemoComponentCoreDataRepository.self),
            let componentFactory = DIContainer.shared.resolve(ComponentFactory.self),
            let followingPage = dormantBoxDirectory[followingPageIndex] as? MemoPageModel
            else { fatalError("can not found Dependency") }

        let memoPageViewModel = MemoPageViewModel(
            componentFactory: componentFactory,
            memoComponentCoredataReposotory: memoComponentCoreDataRepository,
            page: followingPage,
            isReadOnly: true)

        output.send(.getMemoPageViewModel(memoPageViewModel))
    }

    private func showFileInformation(file: any StorageItem) {
        output.send(.showFileInformation(file))
    }

    private func restoreFile(file: any StorageItem) {
        dormantBoxCoredataRepository.restoreFile(restoredFileID: file.id)
        let page = file as! MemoPageModel
        page.parentDirectory?.removeChildItemByID(with: page.id)
        page.parentDirectory = nil
        restoredPageList.append(page)
    }
}

extension DormantBoxViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        dormantBoxDirectory.getChildItemSize()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let storageItem = dormantBoxDirectory[indexPath.row]!
        let cell = tableView.dequeueReusableCell(
            withIdentifier: MemoTableRowView.cellId,
            for: indexPath) as! MemoTableRowView

        cell.configure(with: storageItem)
        return cell
    }
}

