import AVFAudio
import Combine
import SFBAudioEngine
import UIKit

@MainActor
final class MemoPageViewModel: NSObject, ViewModelType {

    typealias Input = MemoPageViewInput
    typealias Output = MemoPageViewOutput

    private var output = PassthroughSubject<Output, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private(set) var memoPage: MemoPageModel

    private var memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType
    private var componentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType
    private var componentFactory: any ComponentFactoryType

    private var audioDownloader: AudioDownloaderType
    private var audioTrackController: AudioTrackControllerType
    private var audioFileManager: AudioFileManagerType

    private let captureDispatchSemaphore = DispatchSemaphore(value: 1)
    private var audioContentsDataContainer: AudioContentsDataContainer

    private let tableComponentService = TableComponentService()

    init(
        componentFactory: any ComponentFactoryType,
        memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType,
        componentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType,
        audioDownloader: AudioDownloaderType,
        audioFileManager: AudioFileManagerType,
        audioTrackController: AudioTrackControllerType,
        memoPage: MemoPageModel
    ) {
        self.componentFactory = componentFactory
        self.memoComponentCoredataReposotory = memoComponentCoredataReposotory
        self.componentSnapshotCoreDataRepository = componentSnapshotCoreDataRepository
        self.audioTrackController = audioTrackController
        self.audioDownloader = audioDownloader
        self.audioFileManager = audioFileManager
        self.memoPage = memoPage

        let audioContentsDatas = memoPage
            .getComponents
            .compactMap { $0 as? AudioComponent }
            .map { AudioContentsData(audioComponent: $0) }
            .map { ($0.audioComponent.id, $0) }

        self.audioContentsDataContainer = AudioContentsDataContainer(
            audioContentsDataTable: Dictionary(uniqueKeysWithValues: audioContentsDatas))

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pauseAudioOnInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }

    @discardableResult
    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad:
                    output.send(.viewDidLoad(memoPage, audioContentsDataContainer))

                case .willCreateNewComponent(let componentType):
                    createNewComponent(with: componentType)

                case .willChangeComponentOrder(let sourceIndex, let destinationIndex):
                    changeComponentOrder(sourceIndex: sourceIndex, destinationIndex: destinationIndex)

                // MARK: - Snapshot
                case .willAutoCaptureWhenPopedFromNavigationStack:
                    captureComponentsWhenPopedFromNavigationStack()

                case .willAutoCaptureOnSceneBackgroundOrDisconnect:
                    captureComponentsWhenAppStateBecomeInactive()

                // MARK: - Table
                case .willAppendRowToTable(let componentID):
                    appendTableComponentRow(componentID)

                case .willRemoveRowToTable(let componentID, let rowID):
                    removeTableComponentRow(componentID, rowID)

                case .willAppendColumnToTable(let componentID):
                    appendTableComponentColumn(componentID)

                case .willApplyTableCellChanges(let componentID, let colID, let rowID, let newCellValue):
                    applyTableCellValue(
                        componentID: componentID, colID: colID, rowID: rowID, newCellValue: newCellValue)

                case .willPresentTableColumnEditingPopupView(let componentID, let tappedColumnID):
                    presentTableComponentColumnEditPopupView(componentID: componentID, columnID: tappedColumnID)

                case .willApplyTableColumnChanges(let componentID, let columns):
                    applyTableColumnChanges(componentID: componentID, columns: columns)

                // MARK: - Audio
                case .willDownloadMusicWithCode(let componentID, let downloadCode):
                    downloadAudio(componentID: componentID, with: downloadCode)

                case .willPlayAudioTrack(let componentID, let trackIndex):
                    playAudioTrack(componentID: componentID, trackIndex: trackIndex)

                case .willApplyAudioMetadataChanges(let editedMetadata, let componentID, let trackIndex):
                    applyAudioMetadataChanges(
                        componentID: componentID, newMetadata: editedMetadata, trackIndex: trackIndex)

                case .willToggleAudioPlayingState:
                    toggleAudioPlayingState()

                case .willSeekAudioTrack(let seek):
                    seekAudioTrack(seek: seek)

                case .willSortAudioTracks(let componentID, let sortBy):
                    sortAudioTracks(componentID: componentID, sortBy: sortBy)

                case .willMoveAudioTrackOrder(let componentID, let src, let des):
                    moveAudioTrackOrder(componentID: componentID, src: src, des: des)

                case .willRemoveAudioTrack(let componentID, let trackIndex):
                    removeAudioTrack(componentID: componentID, trackIndex: trackIndex)

                case .willPlayNextAudioTrack:
                    playNextAudioTrack()

                case .willPlayPreviousAudioTrack:
                    playPreviousAudioTrack()

                case .willImportAudioFileFromFileSystem(let componentID, let tempURLs):
                    importAudioFromLocalFileSystem(componentID: componentID, didPickDocumentsAt: tempURLs)
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func createNewComponent(with: ComponentType) {
        componentFactory.setCreator(creator: with.getComponentCreator())
        let newComponent = componentFactory.createComponent()

        if let audioComponent = newComponent as? AudioComponent {
            audioContentsDataContainer[audioComponent.id] = AudioContentsData(audioComponent: audioComponent)
        }

        memoPage.appendChildComponent(component: newComponent)
        memoComponentCoredataReposotory.createComponentEntity(parentPageID: memoPage.id, component: newComponent)
        output.send(.didAppendComponentAt(memoPage.compnentSize - 1))
    }

//    private func removeComponent(componentID: UUID) {
//        if let removedComponent = memoPage.removeChildComponentById(componentID) {
//            if let audioComponent = removedComponent.item as? AudioComponent {
//                for audioTrack in audioComponent.componentContents.tracks {
//                    audioFileManager.removeAudio(with: audioTrack)
//                }
//            }
//            memoComponentCoredataReposotory.removeComponentEntity(componentID: removedComponent.item.id)
//            output.send(.didRemoveComponentAt(removedComponent.index))
//        }
//    }


//    private func maximizeComponent(componentID: UUID) {
//        performWithComponentAt(componentID) { index, component in
//            if component.isMinimumHeight {
//                component.isMinimumHeight.toggle()
//                memoComponentCoredataReposotory.updateComponentFolding(
//                    componentID: componentID, isFolding: component.isMinimumHeight)
//                output.send(.didToggleComponentSize(index, component.isMinimumHeight))
//            } else {
//                output.send(.didMaximizeComponent(component, index))
//            }
//        }
//    }

//    private func toggleComponentSize(componentID: UUID) {
//        performWithComponentAt(componentID) { index, component in
//            component.isMinimumHeight.toggle()
//            memoComponentCoredataReposotory.updateComponentFolding(
//                componentID: componentID, isFolding: component.isMinimumHeight)
//            output.send(.didToggleComponentSize(index, component.isMinimumHeight))
//        }
//    }

    private func changeComponentOrder(sourceIndex: Int, destinationIndex: Int) {
        let componentID = memoPage.changeComponentRenderingOrder(src: sourceIndex, des: destinationIndex)
        memoComponentCoredataReposotory.updateComponentOrdered(
            componentID: componentID,
            renderingOrdered: memoPage.getComponents.map { $0.id })
    }

    private func captureComponentsWhenPopedFromNavigationStack() {
        let snapshotCreatingInfo = memoPage.getComponents
            .compactMap { $0 as? any SnapshotRestorablePageComponent }
            .compactMap { $0.currentIfUnsaved() }
            .map { componentNeedingCapture -> (UUID, any ComponentSnapshotType) in
                let snapshot = componentNeedingCapture.makeSnapshot(desc: "", saveMode: .automatic)
                componentNeedingCapture.setCaptureState(to: .captured)
                return (componentNeedingCapture.id, snapshot)
            }

        if snapshotCreatingInfo.isEmpty {
            myLog("No components need capturing")
        } else {
            componentSnapshotCoreDataRepository.createComponentSnapshot(snapshots: snapshotCreatingInfo)
        }
    }

    private func captureComponentsWhenAppStateBecomeInactive() {
        var taskID: UIBackgroundTaskIdentifier = .invalid

        taskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(taskID)
            taskID = .invalid
        }

        captureDispatchSemaphore.wait()

        let start = CACurrentMediaTime()

        let snapshotCreatingInfo = memoPage.getComponents
            .compactMap { $0 as? any SnapshotRestorablePageComponent }
            .compactMap { $0.currentIfUnsaved() }
            .map { componentNeedingCapture -> (UUID, any ComponentSnapshotType) in
                let snapshot = componentNeedingCapture.makeSnapshot(desc: "", saveMode: .automatic)
                componentNeedingCapture.setCaptureState(to: .captured)
                return (componentNeedingCapture.id, snapshot)
            }

        if snapshotCreatingInfo.isEmpty {
            myLog("No components need capturing")
            UIApplication.shared.endBackgroundTask(taskID)
            captureDispatchSemaphore.signal()
        } else {
            componentSnapshotCoreDataRepository.createComponentSnapshot(snapshots: snapshotCreatingInfo)
                .sinkToResult { result in
                    switch result {
                        case .success:
                            myLog("capture successfully : \(CACurrentMediaTime() - start)")

                        case .failure(let failure):
                            myLog("capture fail reason : \(failure.localizedDescription)")

                    }
                    UIApplication.shared.endBackgroundTask(taskID)
                    self.captureDispatchSemaphore.signal()
                }
                .store(in: &subscriptions)
        }
    }

    private func performWithComponentAt<ComponentType: PageComponent>(_ id: UUID, task: (Int, ComponentType) -> Void) {
        if let pageComponent = memoPage[id],
            let audioComponent = pageComponent.item as? ComponentType
        {
            task(pageComponent.index, audioComponent)
        }
    }

    private func performWithComponentAt(_ componentID: UUID, task: (Int, any PageComponent) -> Void) {
        if let pageComponent = memoPage[componentID] {
            task(pageComponent.index, pageComponent.item)
        }
    }
}

extension MemoPageViewModel {
    private func appendTableComponentRow(_ componentID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let newRow = tableComponentService.appendTableComponentRow(tableComponent: tableComponent)
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
            output.send(.didAppendRowToTableView(componentIndex, newRow))
        }
    }

    private func removeTableComponentRow(_ componentID: UUID, _ rowID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let removedRowIndex = tableComponentService.removeTableComponentRow(
                tableComponent: tableComponent, rowID: rowID)
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
            output.send(.didRemoveRowToTableView(componentIndex, removedRowIndex))
        }
    }

    private func appendTableComponentColumn(_ componentID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let newColumn = tableComponentService.appendTableComponentColumn(tableComponent: tableComponent)
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
            output.send(.didAppendColumnToTableView(componentIndex, newColumn))
        }
    }

    private func applyTableCellValue(componentID: UUID, colID: UUID, rowID: UUID, newCellValue: String) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let indices = tableComponentService.applyTableCellValue(
                tableComponent: tableComponent, colID: colID, rowID: rowID, newCellValue: newCellValue)
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
            output.send(
                .didApplyTableCellValueChanges(componentIndex, indices.rowIndex, indices.columnIndex, newCellValue)
            )
        }
    }

    private func presentTableComponentColumnEditPopupView(componentID: UUID, columnID: UUID) {
        performWithComponentAt(componentID) { (_, tableComponent: TableComponent) in
            let columnIndex =
                tableComponentService
                .presentTableComponentColumnEditPopupView(tableComponent: tableComponent, columnID: columnID)
            output.send(
                .didPresentTableColumnEditPopupView(
                    tableComponent.componentContents.columns, columnIndex, componentID)
            )
        }
    }

    private func applyTableColumnChanges(componentID: UUID, columns: [TableComponentColumn]) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            tableComponentService.applyTableColumnChanges(tableComponent: tableComponent, columns: columns)
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
            output.send(.didApplyTableColumnChanges(componentIndex, columns))
        }
    }
}

extension MemoPageViewModel: @preconcurrency AVAudioPlayerDelegate {

    private func downloadAudio(componentID: UUID, with code: String) {
        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in

            audioDownloader.handleDownloadedProgressPercent = { [weak self] progress in
                self?.output.send(.didUpdateAudioDownloadProgress(componentIndex, progress))
            }

            audioDownloader.downloadTask(with: code)
                .tryMap { [weak self] url in
                    guard let self else { return [URL]() }
                    return try audioFileManager.extractAudioFileURLs(zipURL: url)
                }
                .tryMapEnumerated { [weak self] _, audioURL in
                    guard let self else { throw AudioDownloadError.invalidCode }
                    let audioMetadata = audioFileManager.readAudioMetadata(audioURL: audioURL)

                    var fileTitle = audioURL.deletingPathExtension().lastPathComponent
                    if fileTitle.isEmpty { fileTitle = .emptyAudioTitle }
                    if let metadataTitle = audioMetadata.title, !metadataTitle.isEmpty { fileTitle = metadataTitle }

                    let artist = audioMetadata.artist ?? .emptyAudioArtist
                    let lyrics = audioMetadata.lyrics ?? ""

                    let defaultAudioThumbnailImage = UIImage(named: "defaultMusicThumbnail")!
                    let thumnnailImageData =
                        audioMetadata.thumbnail ?? defaultAudioThumbnailImage.jpegData(compressionQuality: 1.0)!

                    let audioFileID = UUID()
                    let audioFileName = "\(audioFileID).\(audioURL.pathExtension)"
                    try audioFileManager.moveItem(src: audioURL, fileName: audioFileName)

                    let track = AudioTrack(
                        id: audioFileID,
                        title: fileTitle,
                        artist: artist,
                        thumbnail: thumnnailImageData,
                        lyrics: lyrics,
                        fileExtension: .init(rawValue: audioURL.pathExtension)!)

                    audioFileManager.writeAudioMetadata(audioTrack: track)
                    return track
                }
                .sinkToResult { [weak self] result in
                    guard let self else { return }
                    switch result {
                        case .success(let audioTracks):
                            let appendedIndices = component.addAudios(audiotracks: audioTracks)

                            component.actions.append(
                                .appendAudio(appendedIndices: appendedIndices, tracks: audioTracks)
                            )
                            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: component)
                            output.send(.didAppendAudioTrackRows(componentIndex, appendedIndices))

                        case .failure(let failure):
                            if let error = failure as? AudioDownloadError {
                                switch error {
                                    case .invalidCode:
                                        break
                                    case .unowned(let error):
                                        print(error.localizedDescription)
                                    case .fileManagingError(let error):
                                        print(error.localizedDescription)
                                }
                            }
                            output.send(.didPresentInvalidDownloadCode(componentIndex))
                    }
                }
                .store(in: &subscriptions)
        }
    }

    private func importAudioFromLocalFileSystem(componentID: UUID, didPickDocumentsAt urls: [URL]) {
        var audioTracks: [AudioTrack] = []

        for audioFileUrl in urls {

            let audioID = UUID()
            let audioFileName = "\(audioID).\(audioFileUrl.pathExtension)"
            let storedFileURL = audioFileManager.copyFilesToAppDirectory(src: audioFileUrl, des: audioFileName)
            let audioMetadata = audioFileManager.readAudioMetadata(audioURL: storedFileURL)

            var fileTitle = audioFileUrl.deletingPathExtension().lastPathComponent
            if fileTitle.isEmpty { fileTitle = .emptyAudioTitle }
            if let metadataTitle = audioMetadata.title, !metadataTitle.isEmpty { fileTitle = metadataTitle }

            let artist = audioMetadata.artist ?? .emptyAudioArtist
            let lyrics = audioMetadata.lyrics ?? ""

            let defaultAudioThumbnail = UIImage(named: "defaultMusicThumbnail")!
            let thumnnailImageData = audioMetadata.thumbnail ?? defaultAudioThumbnail.jpegData(compressionQuality: 1.0)!

            let track = AudioTrack(
                id: audioID,
                title: fileTitle,
                artist: artist,
                thumbnail: thumnnailImageData,
                lyrics: lyrics,
                fileExtension: .init(rawValue: storedFileURL.pathExtension)!)

            audioFileManager.writeAudioMetadata(audioTrack: track)
            audioTracks.append(track)
        }

        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in
            let appendedIndices = component.addAudios(audiotracks: audioTracks)

            component.actions.append(.appendAudio(appendedIndices: appendedIndices, tracks: audioTracks))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: component)
            output.send(.didAppendAudioTrackRows(componentIndex, appendedIndices))
        }
    }

    private func playAudioTrack(componentID: UUID, trackIndex: Int) {
        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in

            let audioTrack = component.componentContents.tracks[trackIndex]
            let audioTrackURL = audioFileManager.createAudioFileURL(fileName: component.trackNames[trackIndex])
            let audioPCMData = audioFileManager.readAudioPCMData(audioURL: audioTrackURL)
            let waveformData = scalingPCMDataToWaveformData(pcmData: audioPCMData)

            if let previousAudioContentsData = audioContentsDataContainer.activeAudioContentsData {
                previousAudioContentsData.clean()
            }

            audioTrackController.setAudioURL(audioURL: audioTrackURL)
            audioTrackController.player?.delegate = self
            audioTrackController.play()

            let audioTotalDuration = audioTrackController.totalTime

            if let nextAudioContentsData = audioContentsDataContainer[componentID] {
                let activeAudioTrackData = ActiveAudioTrackData()

                activeAudioTrackData.isPlaying = true
                activeAudioTrackData.nowPlayingAudioTrackID = audioTrack.id
                activeAudioTrackData.audioVisualizerData = waveformData
                activeAudioTrackData.totalTime = audioTotalDuration
                activeAudioTrackData.startTime = CACurrentMediaTime()

                nextAudioContentsData.activeAudioTrackData = activeAudioTrackData
            }

            let audioMetadata = AudioTrackMetadata(
                title: audioTrack.title,
                artist: audioTrack.artist,
                lyrics: audioTrack.lyrics,
                thumbnail: audioTrack.thumbnail)

            output.send(
                .didPlayAudioTrack(
                    componentIndex,
                    trackIndex,
                    audioTotalDuration,
                    audioMetadata,
                    waveformData
                )
            )
        }
    }

    private func playNextAudioTrack() {
        if let audioContentsData = audioContentsDataContainer.activeAudioContentsData {
            if let activeTrackID = audioContentsData.activeAudioTrackData?.nowPlayingAudioTrackID {
                if var nextTrackIndex =
                    audioContentsData.audioComponent.componentContents.tracks.firstIndex(where: {
                        $0.id == activeTrackID
                    })
                {
                    nextTrackIndex += 1
                    if audioContentsData.audioComponent.componentContents.tracks.count <= nextTrackIndex {
                        nextTrackIndex = 0
                    }
                    playAudioTrack(componentID: audioContentsData.audioComponent.id, trackIndex: nextTrackIndex)
                }
            }
        }
    }

    private func playPreviousAudioTrack() {
        if let audioContentsData = audioContentsDataContainer.activeAudioContentsData {
            if let activeTrackID = audioContentsData.activeAudioTrackData?.nowPlayingAudioTrackID {
                if var nextTrackIndex =
                    audioContentsData.audioComponent.componentContents.tracks.firstIndex(where: {
                        $0.id == activeTrackID
                    })
                {
                    nextTrackIndex -= 1
                    if 0 > nextTrackIndex {
                        nextTrackIndex = audioContentsData.audioComponent.componentContents.tracks.count - 1
                    }
                    playAudioTrack(componentID: audioContentsData.audioComponent.id, trackIndex: nextTrackIndex)
                }
            }
        }
    }

    private func toggleAudioPlayingState() {
        audioTrackController.togglePlaying()

        if let audioContentsData = audioContentsDataContainer.activeAudioContentsData {
            audioContentsData.activeAudioTrackData?.isPlaying = audioTrackController.isPlaying
            audioContentsData.activeAudioTrackData?.hasChangePlayingState()

            let activeAudioComponentID = audioContentsData.audioComponent.id
            if let componentIndex = memoPage[activeAudioComponentID]?.index {
                let nowPlayingAudioTrackID = audioContentsData.activeAudioTrackData?.nowPlayingAudioTrackID
                if let nowPlayingAudioTrackIndex = audioContentsData
                    .audioComponent.componentContents.tracks.firstIndex(where: { $0.id == nowPlayingAudioTrackID })
                {
                    output.send(
                        .didToggleAudioPlayingState(
                            componentIndex,
                            nowPlayingAudioTrackIndex,
                            audioTrackController.isPlaying
                        )
                    )
                }
            }
        }
    }

    private func applyAudioMetadataChanges(componentID: UUID, newMetadata: AudioTrackMetadata, trackIndex: Int) {
        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in
            let willChangeTrackID = component.componentContents.tracks[trackIndex].id
            let nowActiveTrackID = audioContentsDataContainer
                .activeAudioContentsData?
                .activeAudioTrackData?
                .nowPlayingAudioTrackID
            let isEditCurrentlyPlayingAudio = nowActiveTrackID == willChangeTrackID
            var trackIndexAfterApply: Int?

            if let newTitle = newMetadata.title {
                component.componentContents.tracks[trackIndex].title = newTitle
            }
            if let newArtist = newMetadata.artist {
                component.componentContents.tracks[trackIndex].artist = newArtist
            }
            if let newLyrics = newMetadata.lyrics {
                component.componentContents.tracks[trackIndex].lyrics = newLyrics
            }
            if let newThumbnail = newMetadata.thumbnail {
                component.componentContents.tracks[trackIndex].thumbnail = newThumbnail
            }

            component.actions.append(.applyAudioMetadata(audioID: willChangeTrackID, metadata: newMetadata))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: component)
            audioFileManager.writeAudioMetadata(audioTrack: component.componentContents.tracks[trackIndex])

            if component.componentContents.sortBy == .name {
                component.componentContents.tracks.sort(by: { $0.title < $1.title })

                trackIndexAfterApply = component.componentContents.tracks.firstIndex {
                    $0.id == willChangeTrackID
                }
            }

            output.send(
                .didApplyAudioMetadataChanges(
                    componentIndex,
                    trackIndex,
                    newMetadata,
                    isEditCurrentlyPlayingAudio,
                    trackIndexAfterApply
                )
            )
        }
    }

    private func seekAudioTrack(seek: TimeInterval) {
        if let audioContentsData = audioContentsDataContainer.activeAudioContentsData {
            audioTrackController.seek(interval: seek)
            audioContentsData.seek(seek: seek)

            if let componentIndex = memoPage[audioContentsData.audioComponent.id]?.index {
                let nowPlayingAudioTrackID = audioContentsData.activeAudioTrackData?.nowPlayingAudioTrackID
                if let nowPlayingAudioTrackIndex =
                    audioContentsData.audioComponent
                    .componentContents.tracks.firstIndex(where: { $0.id == nowPlayingAudioTrackID })
                {
                    output.send(
                        .didSeekAudioTrack(
                            componentIndex,
                            nowPlayingAudioTrackIndex,
                            seek,
                            audioTrackController.totalTime!
                        )
                    )
                }
            }
        }
    }

    private func moveAudioTrackOrder(componentID: UUID, src: Int, des: Int) {
        performWithComponentAt(componentID) { (_, audioComponent: AudioComponent) in
            audioComponent.componentContents.tracks.moveElement(src: src, des: des)
            audioComponent.componentContents.sortBy = .manual

            audioComponent.actions.append(.moveAudioOrder(src: src, des: des))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: audioComponent)
        }
    }

    private func sortAudioTracks(componentID: UUID, sortBy: AudioTrackSortBy) {
        performWithComponentAt(componentID) { (componentIndex, audioComponent: AudioComponent) in
            audioComponent.componentContents.sortBy = sortBy

            let before = audioComponent.trackNames

            switch sortBy {
                case .name:
                    audioComponent.componentContents.tracks.sort(by: { $0.title < $1.title })

                case .createDate:
                    audioComponent.componentContents.tracks.sort(by: { $0.createData > $1.createData })

                case .manual:
                    break
            }

            let after = audioComponent.trackNames

            audioComponent.actions.append(.sortAudioTracks(sortBy: sortBy))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: audioComponent)

            output.send(.didSortAudioTracks(componentIndex, before, after))
        }
    }

    private func removeAudioTrack(componentID: UUID, trackIndex: Int) {

        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in

            guard let audioContentsData = audioContentsDataContainer.activeAudioContentsData
            else { return }

            let removedAudioTrack = component.componentContents.tracks.remove(at: trackIndex)

            audioFileManager.removeAudio(with: removedAudioTrack)
            component.actions.append(.removeAudio(removedAudioID: removedAudioTrack.id))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: component)

            // 활성화된 오디오 컴포넌트에서 삭제가 발생했다면
            if audioContentsData.audioComponent.id == componentID {

                // 재생중인데 마지막 한 곡을 삭제했을 때
                if component.componentContents.tracks.isEmpty {
                    audioTrackController.reset()
                    audioContentsData.clean()
                    output.send(.didRemoveAudioTrackAndStopPlaying(componentIndex, trackIndex))
                    return
                }

                // 재생중인 곡을 삭제했을 때
                if audioContentsData.activeAudioTrackData?.nowPlayingAudioTrackID == removedAudioTrack.id {
                    if audioTrackController.isPlaying == true {

                        let nextPlayingAudioTrackIndex = min(trackIndex, component.componentContents.tracks.count - 1)
                        let nextPlayingAudioTrack = component.componentContents.tracks[nextPlayingAudioTrackIndex]
                        let audioTrackURL = audioFileManager.createAudioFileURL(
                            fileName: component.trackNames[nextPlayingAudioTrackIndex])
                        let audioPCMData = audioFileManager.readAudioPCMData(audioURL: audioTrackURL)
                        let waveformData = scalingPCMDataToWaveformData(pcmData: audioPCMData)

                        audioTrackController.setAudioURL(audioURL: audioTrackURL)
                        audioTrackController.player?.delegate = self
                        audioTrackController.play()

                        let audioTotalDuration = audioTrackController.totalTime

                        audioContentsData.activeAudioTrackData?.isPlaying = true
                        audioContentsData.activeAudioTrackData?.nowPlayingAudioTrackID = nextPlayingAudioTrack.id
                        audioContentsData.activeAudioTrackData?.audioVisualizerData = waveformData
                        audioContentsData.activeAudioTrackData?.startTime = CACurrentMediaTime()
                        audioContentsData.activeAudioTrackData?.totalTime = audioTotalDuration

                        let audioMetadata = AudioTrackMetadata(
                            title: nextPlayingAudioTrack.title,
                            artist: nextPlayingAudioTrack.artist,
                            lyrics: nextPlayingAudioTrack.lyrics,
                            thumbnail: nextPlayingAudioTrack.thumbnail)

                        output.send(
                            .didRemoveAudioTrackAndPlayNextAudio(
                                componentIndex,
                                trackIndex,
                                nextPlayingAudioTrackIndex,
                                audioTotalDuration,
                                audioMetadata,
                                waveformData
                            )
                        )
                    } else {
                        audioTrackController.reset()
                        audioContentsData.clean()
                        output.send(.didRemoveAudioTrackAndStopPlaying(componentIndex, trackIndex))
                    }
                } else {
                    output.send(.didRemoveAudioTrack(componentIndex, trackIndex))
                }
            } else {
                output.send(.didRemoveAudioTrack(componentIndex, trackIndex))
            }
        }
    }

    private func scalingPCMDataToWaveformData(pcmData: AudioPCMData?) -> AudioWaveformData? {
        guard let pcmData else { return nil }
        let visualizerBarCount = 7
        let timerIntervalDivisor = 6.0
        let samplesPerBar = Int(pcmData.sampleRate / timerIntervalDivisor)
        var averagedPCMData: [Float] = []

        for i in 0..<(pcmData.PCMData.count / samplesPerBar) {
            let PCMDataSegment = pcmData.PCMData[i * samplesPerBar..<(i + 1) * samplesPerBar]
            let avg = PCMDataSegment.map { abs($0) }.reduce(0, +) / Float(PCMDataSegment.count)
            averagedPCMData.append(avg)
        }

        let maximumData = averagedPCMData.max()!
        let scaledPCMData =
            averagedPCMData
            .map { ($0 / maximumData) }
            .map { baseBarHeight in
                (0..<visualizerBarCount)
                    .map { _ in
                        max(0.1, min(1.0, baseBarHeight + Float.random(in: -0.25...0.25)))
                    }
            }

        return AudioWaveformData(
            sampleDataCount: pcmData.PCMData.count,
            sampleRate: pcmData.sampleRate,
            waveformData: scaledPCMData)
    }

    @objc private func pauseAudioOnInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
            case .began:
                if audioTrackController.isPlaying { toggleAudioPlayingState() }

            case .ended:
                if !audioTrackController.isPlaying { toggleAudioPlayingState() }

            @unknown default:
                print("unknown interrupt")
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNextAudioTrack()
    }
}

extension MemoPageViewModel: @preconcurrency ComponentsPageCollectionViewLayoutDelegate {
    func collectionView(heightForItemAt indexPath: IndexPath) -> CGFloat {
        memoPage[indexPath.item].isMinimumHeight ? UIConstants.componentMinimumHeight : UIView.screenWidth - 40
    }
}
