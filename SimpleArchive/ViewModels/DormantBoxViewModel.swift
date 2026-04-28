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
        audioFileManger: AudioFileManagerType
    ) {
        self.dormantBoxCoredataRepository = dormantBoxCoredataRepository
        self.restoredPageListSubject = restoredPageListSubject
        self.audioFileManager = audioFileManger
    }

    deinit {
        myLog(String(describing: Swift.type(of: self)), c: .purple)
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
                    restoreFile(file: dormantBoxDirectory.items[index])

                case .willRemovePageFromDormantBox(let id):
                    dormantBoxCoredataRepository.permanentRemoveFile(pageID: id)

                    if let item = dormantBoxDirectory[id],
                        let page = item.item as? MemoPageModel
                    {
                        if let idx = page.parentDirectory?.items.firstIndex(where: { $0.id == id }) {
                            page.parentDirectory?.items.remove(at: idx)
                        }

                        page.parentDirectory = nil

                        let audioComponents = page.components.compactMap { $0 as? AudioComponent }

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
                    Task.detached {
                        var size: Int64 = dormantBoxDirectory.getItemSize()

                        for page in dormantBoxDirectory.items.compactMap({ $0 as? MemoPageModel }) {
                            for ac in page.components.compactMap({ $0 as? AudioComponent }) {
                                for track in ac.componentContents.tracks {
                                    let url = await self.audioFileManager.makeAudioTrackAppSandBoxURL(audioTrack: track)
                                    let s = await self.audioFileManager.readAudioFileSize(audioURL: url)
                                    size += s
                                }
                            }
                        }
                        await MainActor.run { [size] in
                            self.output.send(.didCalcDormantBoxDirectoryInfo(size))
                        }
                    }
                    output.send(.didfetchMemoData(dormantBox: dormantBoxDirectory))
                }
            )
            .store(in: &subscriptions)
    }

    private func showFileInformation(index: Int) {
        if let page = dormantBoxDirectory.items[index] as? MemoPageModel {
            if page.isSingleComponentPage {
                if page.components.first as? TextEditorComponent != nil {
                    output.send(
                        .showSingleTextPageInformation(page.id, page.name, page.creationDate, page.getItemSize()))
                } else if let tc = page.components.first as? TableComponent {
                    output.send(
                        .showSingleTablePageInformation(
                            page.id, page.name, page.creationDate, page.getItemSize(),
                            tc.componentContents.columns.map { $0.title }, tc.componentContents.cellValues.count)
                    )
                } else if let ac = page.components.first as? AudioComponent {
                    let totalSize = ac.componentContents.tracks
                        .map { audioFileManager.makeAudioTrackAppSandBoxURL(audioTrack: $0) }
                        .map { audioFileManager.readAudioFileSize(audioURL: $0) }
                        .reduce(0, +)
                    output.send(
                        .showSingleAudioPageInformation(
                            page.id, page.name, page.creationDate, totalSize, ac.componentContents.tracks.count)
                    )
                }
            } else {
                let info = page.getFileInformation() as! PageInformation
                var size: Int64 = 0
                for ac in page.components.compactMap({ $0 as? AudioComponent }) {
                    let totalSize = ac.componentContents.tracks
                        .map { audioFileManager.makeAudioTrackAppSandBoxURL(audioTrack: $0) }
                        .map { audioFileManager.readAudioFileSize(audioURL: $0) }
                        .reduce(0, +)
                    size += totalSize
                }
                output.send(
                    .showFileInformation(
                        page.id, page.name, page.creationDate,
                        info.pageComponentCounts, page.getItemSize() + size)
                )
            }
        }
    }

    private func restoreFile(file: any StorageItem) {
        dormantBoxCoredataRepository.restoreFile(restoredFileID: file.id)
        let page = file as! MemoPageModel
        if let idx = page.parentDirectory?.items.firstIndex(where: { $0.id == page.id }) {
            page.parentDirectory?.items.remove(at: idx)
        }
        page.parentDirectory = nil
        restoredPageList.append(page)
    }
}

enum DormantBoxViewInput {
    case viewDidLoad
    case showFileInformation(Int)
    case restoreFile(Int)
    case willRemovePageFromDormantBox(UUID)
}

enum DormantBoxViewOutput {
    case didfetchMemoData(dormantBox: MemoDirectoryModel)
    case showFileInformation(UUID, String, Date, [ComponentType: Int], Int64)
    case showSingleAudioPageInformation(UUID, String, Date, Int64, Int)
    case showSingleTextPageInformation(UUID, String, Date, Int64)
    case showSingleTablePageInformation(UUID, String, Date, Int64, [String], Int)
    case didRemovePageFromDormantBox(Int)
    case didCalcDormantBoxDirectoryInfo(Int64)
}
