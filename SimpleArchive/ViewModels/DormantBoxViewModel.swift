import Combine
import UIKit

@MainActor final class DormantBoxViewModel: NSObject, ViewModelType {

    typealias Input = DormantBoxViewInput
    typealias Output = DormantBoxViewOutput

    private var output = PassthroughSubject<DormantBoxViewOutput, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private var dormantBoxCoredataRepository: DormantBoxCoreDataRepositoryType
    private var dormantBoxDirectory: MemoDirectoryModel!

    private var restoredPageListSubject: PassthroughSubject<[MemoPageModel], Never>
    private var restoredPageList: [MemoPageModel] = []
    private var audioFileManager: AudioFileManagerType

    init(
        dormantBoxCoredataRepository: DormantBoxCoreDataRepositoryType,
        restoredPageListSubject: PassthroughSubject<[MemoPageModel], Never>,
        audioFileManager: AudioFileManagerType
    ) {
        self.dormantBoxCoredataRepository = dormantBoxCoredataRepository
        self.restoredPageListSubject = restoredPageListSubject
        self.audioFileManager = audioFileManager
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
                    showFileInformation(index: index)

                case .restoreFile(let index):
                    restoreFile(file: dormantBoxDirectory[index]!)

                case .willRemovePageFromDormantBox(let id):
                    dormantBoxCoredataRepository.permanentRemoveFile(pageID: id)

                    if let item = dormantBoxDirectory[id],
                        let page = item.item as? MemoPageModel
                    {
                        page.parentDirectory?.removeChildItemByID(with: page.id)
                        page.parentDirectory = nil

                        let audioComponents = page.getComponents.compactMap { $0 as? AudioComponent }

                        for audioComponent in audioComponents {
                            for audioTrack in audioComponent.componentContents.tracks {
                                audioFileManager.removeAudio(with: audioTrack)
                            }
                        }
                        output.send(.didRemovePageFromDormantBox(item.index))
                    }
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func fetchDormantBoxDirectory() {
        dormantBoxCoredataRepository.fetchDormantBoxDirectory()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] dormantBoxDirectory in
                    guard let self else { return }
                    self.dormantBoxDirectory = dormantBoxDirectory
                    output.send(.didfetchMemoData(dormantBoxDirectory.getChildItemSize()))
                }
            )
            .store(in: &subscriptions)
    }

    private func showFileInformation(index: Int) {
        if let page = dormantBoxDirectory[index],
            let pageInfo = page.getFileInformation() as? PageInformation
        {
            output.send(.showFileInformation(pageInfo))
        }
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

    func numberOfSections(in tableView: UITableView) -> Int {
        dormantBoxDirectory.getChildItemSize()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let storageItem = dormantBoxDirectory[indexPath.section]!
        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: DirectoryFileItemRowView.reuseIdentifier,
                for: indexPath) as! DirectoryFileItemRowView

        cell.configure(with: storageItem)
        return cell
    }
}
