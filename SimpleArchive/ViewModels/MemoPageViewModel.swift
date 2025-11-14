import AVFAudio
import Combine
import SFBAudioEngine
import UIKit

@MainActor class MemoPageViewModel: NSObject, ViewModelType {

    typealias Input = MemoPageViewInput
    typealias Output = MemoPageViewOutput

    private var output = PassthroughSubject<Output, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private(set) var memoPage: MemoPageModel!

    private var memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType
    private var componentFactory: any ComponentFactoryType
    private var audioDownloader: AudioDownloaderType = AudioDownloader()
    private var audioTrackController: AudioTrackControllerType?
    private var nowPlayingAudioComponentID: UUID?

    init(
        componentFactory: any ComponentFactoryType,
        memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType,
        page: MemoPageModel,
    ) {
        self.componentFactory = componentFactory
        self.memoComponentCoredataReposotory = memoComponentCoredataReposotory
        self.memoPage = page

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveComponentsChanges),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pauseAudioOnInterruption),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    deinit { print("deinit MemoPageViewModel") }

    @discardableResult
    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad:
                    output.send(.viewDidLoad(memoPage.name))

                case .willCreateNewComponent(let componentType):
                    createNewComponent(with: componentType)

                case .willRemoveComponent(let componentID):
                    removeComponent(componentID: componentID)

                case .willChangeComponentName(let id, let newName):
                    changeComponentName(componentID: id, newName: newName)

                case .willToggleComponentSize(let componentID):
                    toggleComponentSize(componentID: componentID)

                case .willMaximizeComponent(let componentID):
                    maximizeComponent(componentID: componentID)

                case .willChangeComponentOrder(let sourceIndex, let destinationIndex):
                    changeComponentOrder(sourceIndex: sourceIndex, destinationIndex: destinationIndex)

                case .willCaptureComponent(let componentID, let description):
                    captureComponent(componentID: componentID, description: description)

                case .willNavigateSnapshotView(let componentID):
                    moveToComponentSnapshotView(componentID: componentID)

                case .viewWillDisappear:
                    saveComponentsChanges(isDisappearView: true)

                // MARK: - Table

                case .willAppendRowToTable(let componentID):
                    appendTableComponentRow(componentID)

                case .willRemoveRowToTable(let componentID, let rowID):
                    removeTableComponentRow(componentID, rowID)

                case .willAppendColumnToTable(let componentID):
                    appendTableComponentColumn(componentID)

                case .willApplyTableCellChanges(let componentID, let cellID, let newCellValue):
                    applyTableCellValue(componentID, cellID, newCellValue)

                case .willPresentTableColumnEditingPopupView(let componentID, let tappedColumnIndex):
                    presentTableComponentColumnEditPopupView(componentID: componentID, columnIndex: tappedColumnIndex)

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

        memoPage.appendChildComponent(component: newComponent)
        memoComponentCoredataReposotory.createComponentEntity(
            parentPageID: memoPage.id, component: newComponent)
        output.send(.didAppendComponentAt(memoPage.compnentSize - 1))
    }

    private func removeComponent(componentID: UUID) {
        if let removedComponent = memoPage.removeChildComponentById(componentID) {
            if let audioComponent = removedComponent.item as? AudioComponent {
                audioComponent.removeAudioFilesFromDisk()
            }
            memoComponentCoredataReposotory.removeComponent(
                parentPageID: memoPage.id,
                componentID: removedComponent.item.id)
            output.send(.didRemoveComponentAt(removedComponent.index))
        }
    }

    private func changeComponentName(componentID: UUID, newName: String) {
        performWithComponentAt(componentID) { index, component in
            component.title = newName
            let pageComponentChangeObject = PageComponentChangeObject(
                componentIdChanged: componentID,
                title: newName)
            memoComponentCoredataReposotory.updateComponentChanges(componentChanges: pageComponentChangeObject)
        }
    }

    private func maximizeComponent(componentID: UUID) {
        performWithComponentAt(componentID) { index, component in
            if component.isMinimumHeight {
                component.isMinimumHeight.toggle()
                let pageComponentChangeObject = PageComponentChangeObject(
                    componentIdChanged: componentID,
                    isMinimumHeight: component.isMinimumHeight)
                memoComponentCoredataReposotory.updateComponentChanges(componentChanges: pageComponentChangeObject)
                output.send(.didToggleComponentSize(index, component.isMinimumHeight))
            } else {
                output.send(.didMaximizeComponent(component, index))
            }
        }
    }

    private func toggleComponentSize(componentID: UUID) {
        performWithComponentAt(componentID) { index, component in
            component.isMinimumHeight.toggle()
            let pageComponentChangeObject = PageComponentChangeObject(
                componentIdChanged: componentID,
                isMinimumHeight: component.isMinimumHeight)
            memoComponentCoredataReposotory.updateComponentChanges(componentChanges: pageComponentChangeObject)
            output.send(.didToggleComponentSize(index, component.isMinimumHeight))
        }
    }

    private func changeComponentOrder(sourceIndex: Int, destinationIndex: Int) {
        let id = memoPage.changeComponentRenderingOrder(src: sourceIndex, des: destinationIndex)
        let pageComponentChangeObject = PageComponentChangeObject(
            componentIdChanged: id,
            componentIdListRenderingOrdered: memoPage.getComponents.map { $0.id })
        memoComponentCoredataReposotory.updateComponentChanges(componentChanges: pageComponentChangeObject)
    }

    private func captureComponent(componentID: UUID, description: String) {
        performWithComponentAt(componentID) { index, component in
            if let snapshotRestorableComponent = component as? any SnapshotRestorable {
                memoComponentCoredataReposotory.captureSnapshot(
                    snapshotRestorableComponent: snapshotRestorableComponent,
                    desc: description
                )
                output.send(.didCompleteComponentCapture(index))
            }
        }
    }

    private func moveToComponentSnapshotView(componentID: UUID) {
        guard
            let repository = DIContainer.shared.resolve(ComponentSnapshotCoreDataRepository.self),
            let component = memoPage[componentID],
            let textEditorComponent = component.item as? any SnapshotRestorable
        else { return }

        let componentSnapshotViewModel = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: repository,
            snapshotRestorableComponent: textEditorComponent)

        output.send(.didNavigateSnapshotView(componentSnapshotViewModel, component.index))
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

    @objc private func saveComponentsChanges(isDisappearView: Bool = false) {
        if isDisappearView {
            memoPage.getComponents.compactMap { $0 as? AudioComponent }.forEach { $0.datasource = nil }
        }

        let components = memoPage.getComponents.compactMap { $0.currentIfUnsaved() }
        memoComponentCoredataReposotory.saveComponentsDetail(changedComponents: components)
    }
}

extension MemoPageViewModel {

    private func appendTableComponentRow(_ componentID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let newRow = tableComponent.componentDetail.appendNewRow()
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didAppendRowToTableView(componentIndex, newRow))
        }
    }

    private func removeTableComponentRow(_ componentID: UUID, _ rowID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let removedRowIndex = tableComponent.componentDetail.removeRow(rowID)
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didRemoveRowToTableView(componentIndex, removedRowIndex))
        }
    }

    private func appendTableComponentColumn(_ componentID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let newColumn = tableComponent.componentDetail.appendNewColumn(columnTitle: "column")
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didAppendColumnToTableView(componentIndex, newColumn))
        }
    }

    private func applyTableCellValue(_ componentID: UUID, _ cellID: UUID, _ newCellValue: String) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let indices = tableComponent.componentDetail.editCellValeu(cellID, newCellValue)
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didApplyTableCellValueChanges(componentIndex, indices.0, indices.1, newCellValue))
        }
    }

    private func presentTableComponentColumnEditPopupView(componentID: UUID, columnIndex: Int) {
        performWithComponentAt(componentID) { (_, tableComponent: TableComponent) in
            output.send(
                .didPresentTableColumnEditPopupView(
                    tableComponent.componentDetail.columns, columnIndex, componentID))
        }
    }

    private func applyTableColumnChanges(componentID: UUID, columns: [TableComponentColumn]) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            tableComponent.componentDetail.setColumn(columns)
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didApplyTableColumnChanges(componentIndex, columns))
        }
    }
}

extension MemoPageViewModel: @preconcurrency AVAudioPlayerDelegate {

    private func downloadAudio(componentID: UUID, with code: String) {
        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in

            let currentPlayingAudioTrackID = component.detail[component.datasource?.nowPlayingAudioIndex]?.id

            audioDownloader.handleDownloadedProgressPercent = { [weak self] progress in
                self?.output.send(.didUpdateAudioDownloadProgress(componentIndex, progress))
            }

            audioDownloader.downloadTask(with: code)
                .sinkToResult { [weak self] result in
                    guard let self else { return }
                    switch result {
                        case .success(let audioTracks):
                            let appendedIndices = component.addAudios(audiotracks: audioTracks)
                            component.datasource?.tracks = component.detail.tracks
                            component.datasource?.nowPlayingAudioIndex = component.detail.tracks
                                .firstIndex { $0.id == currentPlayingAudioTrackID }
                            output.send(.didAppendAudioTrackRows(componentIndex, appendedIndices))

                        case .failure(let failure):
                            switch failure {
                                case .invalidCode:
                                    break
                                case .unowned(let msg):
                                    print(msg)
                            }
                            output.send(.didPresentInvalidDownloadCode(componentIndex))
                    }
                }
                .store(in: &subscriptions)
        }
    }

    private func importAudioFromLocalFileSystem(componentID: UUID, didPickDocumentsAt urls: [URL]) {

        let fileManager = FileManager.default
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveDir = documentsDir.appendingPathComponent("SimpleArchiveMusics")
        var audioTracks: [AudioTrack] = []

        do {
            if !fileManager.fileExists(atPath: archiveDir.path) {
                try fileManager.createDirectory(at: archiveDir, withIntermediateDirectories: true)
            }

            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }

                let newID = UUID()
                let newFileName = "\(newID).\(url.pathExtension)"
                let destinationURL = archiveDir.appendingPathComponent(newFileName)

                try fileManager.copyItem(at: url, to: destinationURL)

                var fileTitle = url.deletingPathExtension().lastPathComponent
                var artist: String = "Unknown"
                let defaultAudioThumbnail = UIImage(named: "defaultMusicThumbnail")!
                let defaultThumnnailData = defaultAudioThumbnail.jpegData(compressionQuality: 1.0)!
                var defaultThumbnail = AttachedPicture(imageData: defaultThumnnailData, type: .frontCover)

                if fileTitle.isEmpty { fileTitle = "no title" }

                if let audioFile = try? AudioFile(readingPropertiesAndMetadataFrom: destinationURL) {

                    if let metadataTitle = audioFile.metadata.title, !metadataTitle.isEmpty {
                        print(metadataTitle)
                        fileTitle = metadataTitle
                    }

                    if let metadataArtist = audioFile.metadata.artist, !metadataArtist.isEmpty {
                        artist = metadataArtist
                    }

                    if let metadataThumbnail = audioFile.metadata.attachedPictures(ofType: .frontCover).first {
                        defaultThumbnail = metadataThumbnail
                    } else if let metadataOtherThumbnail = audioFile.metadata.attachedPictures(ofType: .other).first {
                        defaultThumbnail = AttachedPicture(
                            imageData: metadataOtherThumbnail.imageData,
                            type: .frontCover)
                    }

                    let newMetadata = AudioMetadata(dictionaryRepresentation: [
                        .attachedPictures: [defaultThumbnail.dictionaryRepresentation] as NSArray,
                        .title: NSString(string: fileTitle),
                        .artist: NSString(string: artist),
                    ])

                    audioFile.metadata = newMetadata
                    try? audioFile.writeMetadata()
                }

                let track = AudioTrack(
                    id: newID,
                    title: fileTitle,
                    artist: artist,
                    thumbnail: defaultThumbnail.imageData,
                    fileExtension: destinationURL.pathExtension)

                audioTracks.append(track)
            }

            performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in

                let currentPlayingAudioTrackID = component.detail[component.datasource?.nowPlayingAudioIndex]?.id
                let appendedIndices = component.addAudios(audiotracks: audioTracks)

                component.datasource?.tracks = component.detail.tracks
                component.datasource?.nowPlayingAudioIndex = component.detail.tracks
                    .firstIndex {
                        $0.id == currentPlayingAudioTrackID
                    }

                output.send(.didAppendAudioTrackRows(componentIndex, appendedIndices))
            }
        } catch {
            print(error.localizedDescription)
        }
    }

    private func playAudioTrack(componentID: UUID, trackIndex: Int) {

        let previousComponentIndex = memoPage[nowPlayingAudioComponentID ?? UUID()]?.index

        if let nowPlayingAudioComponentID {
            cleanDataSource(nowPlayingAudioComponentID)
        }

        nowPlayingAudioComponentID = componentID

        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in
            component.datasource?.isPlaying = true
            component.datasource?.nowPlayingAudioIndex = trackIndex
            audioTrackController = AudioTrackController(audioTrackName: component.trackNames[trackIndex])
            component.datasource?.nowPlayingURL = audioTrackController?.audioTrackURL

            audioTrackController?.player?.delegate = self
            audioTrackController?.play()

            let audioSampleData = getAudioSampleData(nowPlayingURL: audioTrackController?.audioTrackURL)
            component.datasource?.audioSampleData = audioSampleData
            component.datasource?.getProgress = { [weak self] in
                guard let self else { return .zero }
                return audioTrackController!.getCurrentTime()! / audioTrackController!.getTotalTime()!
            }
            output.send(
                .didPlayAudioTrack(
                    previousComponentIndex,
                    componentIndex,
                    audioTrackController!.audioTrackURL,
                    trackIndex,
                    audioTrackController?.getTotalTime(),
                    component.detail.tracks[trackIndex].metadata,
                    audioSampleData
                )
            )
        }
    }

    private func playNextAudioTrack() {
        guard let nowPlayingAudioComponentID else { return }
        performWithComponentAt(nowPlayingAudioComponentID) { (_, audioComponent: AudioComponent) in
            audioTrackController?.stop()

            if var unwrappedCurrentPlayingTrackIndex = audioComponent.datasource?.nowPlayingAudioIndex {
                unwrappedCurrentPlayingTrackIndex += 1
                if audioComponent.detail.tracks.count <= unwrappedCurrentPlayingTrackIndex {
                    unwrappedCurrentPlayingTrackIndex = 0
                }
                playAudioTrack(componentID: nowPlayingAudioComponentID, trackIndex: unwrappedCurrentPlayingTrackIndex)
            }
        }
    }

    private func playPreviousAudioTrack() {
        guard let nowPlayingAudioComponentID else { return }
        performWithComponentAt(nowPlayingAudioComponentID) { (_, audioComponent: AudioComponent) in
            audioTrackController?.stop()

            if var unwrappedCurrentPlayingTrackIndex = audioComponent.datasource?.nowPlayingAudioIndex {
                unwrappedCurrentPlayingTrackIndex -= 1
                if 0 > unwrappedCurrentPlayingTrackIndex {
                    unwrappedCurrentPlayingTrackIndex = audioComponent.detail.tracks.count - 1
                }
                playAudioTrack(componentID: nowPlayingAudioComponentID, trackIndex: unwrappedCurrentPlayingTrackIndex)
            }
        }
    }

    private func toggleAudioPlayingState() {
        guard let nowPlayingAudioComponentID else { return }
        audioTrackController?.togglePlaying()

        performWithComponentAt(nowPlayingAudioComponentID) { (_, audioComponent: AudioComponent) in
            if let isPlaying = audioTrackController?.isPlaying,
                let componentIndex = memoPage[nowPlayingAudioComponentID]?.index,
                let trackIndex = audioComponent.datasource?.nowPlayingAudioIndex
            {
                audioComponent.datasource?.isPlaying = isPlaying
                output.send(
                    .didToggleAudioPlayingState(
                        componentIndex,
                        trackIndex,
                        isPlaying,
                        audioTrackController?.getCurrentTime()
                    )
                )
            }
        }
    }

    private func applyAudioMetadataChanges(componentID: UUID, newMetadata: AudioTrackMetadata, trackIndex: Int) {
        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in
            let targetAudioTrackID = component.detail[trackIndex]?.id
            let currentPlayingAudioTrackID = component.detail[component.datasource?.nowPlayingAudioIndex]?.id
            var trackIndexAfterEdit: Int?

            if let newTitle = newMetadata.title {
                component.detail.tracks[trackIndex].title = newTitle
            }

            if let newArtist = newMetadata.artist {
                component.detail.tracks[trackIndex].artist = newArtist
            }

            if let newThumbnail = newMetadata.thumbnail {
                component.detail.tracks[trackIndex].thumbnail = newThumbnail
            }

            component.persistenceState = .unsaved(isMustToStoreSnapshot: false)

            if component.detail.sortBy == .name {
                component.detail.tracks.sort(by: { $0.title < $1.title })
                trackIndexAfterEdit = component.detail.tracks.firstIndex(where: { $0.id == targetAudioTrackID })
                if let currentPlayingAudioTrackID {
                    component.datasource?.nowPlayingAudioIndex = component.detail.tracks.firstIndex {
                        $0.id == currentPlayingAudioTrackID
                    }
                }
            }
            component.datasource?.tracks = component.detail.tracks

            output.send(
                .didApplyAudioMetadataChanges(
                    componentIndex,
                    trackIndex,
                    newMetadata,
                    component.datasource?.nowPlayingAudioIndex == trackIndex,
                    trackIndexAfterEdit)
            )
        }
    }

    private func seekAudioTrack(seek: TimeInterval) {
        performWithComponentAt(nowPlayingAudioComponentID!) { (_, audioComponent: AudioComponent) in
            audioTrackController?.seek(interval: seek)
            if let nowPlayingAudioComponentID,
                let componentIndex = memoPage[nowPlayingAudioComponentID]?.index,
                let trackIndex = audioComponent.datasource?.nowPlayingAudioIndex
            {
                output.send(
                    .didSeekAudioTrack(
                        componentIndex,
                        trackIndex,
                        seek,
                        audioTrackController?.getTotalTime()
                    )
                )
            }
        }
    }

    private func moveAudioTrackOrder(componentID: UUID, src: Int, des: Int) {
        performWithComponentAt(componentID) { (_, audioComponent: AudioComponent) in
            let datasource = audioComponent.datasource
            let currentPlayingAudioTrackID = audioComponent.detail[datasource?.nowPlayingAudioIndex]?.id

            audioComponent.detail.tracks.moveElement(src: src, des: des)
            audioComponent.detail.sortBy = .manual

            datasource?.tracks = audioComponent.detail.tracks
            datasource?.sortBy = .manual

            audioComponent.persistenceState = .unsaved(isMustToStoreSnapshot: false)
            datasource?.nowPlayingAudioIndex = audioComponent.detail.tracks.firstIndex {
                $0.id == currentPlayingAudioTrackID
            }
        }
    }

    private func sortAudioTracks(componentID: UUID, sortBy: AudioTrackSortBy) {
        performWithComponentAt(componentID) { (componentIndex, audioComponent: AudioComponent) in
            audioComponent.detail.sortBy = sortBy
            audioComponent.persistenceState = .unsaved(isMustToStoreSnapshot: false)

            let datasource = audioComponent.datasource
            let currentPlayingAudioTrackID = audioComponent.detail[datasource?.nowPlayingAudioIndex]?.id

            let before = audioComponent.trackNames

            switch sortBy {
                case .name:
                    audioComponent.detail.tracks.sort(by: { $0.title < $1.title })

                case .createDate:
                    audioComponent.detail.tracks.sort(by: { $0.createData > $1.createData })

                case .manual:
                    break
            }
            audioComponent.datasource?.nowPlayingAudioIndex = audioComponent.detail.tracks.firstIndex {
                $0.id == currentPlayingAudioTrackID
            }

            let after = audioComponent.trackNames

            datasource?.tracks = audioComponent.detail.tracks
            datasource?.sortBy = sortBy

            output.send(.didSortAudioTracks(componentIndex, before, after))
        }
    }

    private func removeAudioTrack(componentID: UUID, trackIndex: Int) {
        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in

            component.persistenceState = .unsaved(isMustToStoreSnapshot: false)

            let datasource = component.datasource
            let currentPlayingAudioTrackID = component.detail[datasource?.nowPlayingAudioIndex]?.id

            component.removeAudio(with: trackIndex)
            datasource?.tracks = component.detail.tracks

            if datasource?.nowPlayingAudioIndex != nil {
                if component.detail.tracks.isEmpty {
                    audioTrackController = nil
                    nowPlayingAudioComponentID = nil
                    cleanDataSource(componentID)
                    output.send(.didRemoveAudioTrack(componentIndex, trackIndex))
                    output.send(.didSetAudioPlayingStateToStopped(componentIndex))
                    return
                }

                if datasource?.nowPlayingAudioIndex == trackIndex {
                    if audioTrackController?.isPlaying == true {
                        let nextPlayingAudioTrackIndex = min(trackIndex, component.detail.tracks.count - 1)
                        output.send(.didRemoveAudioTrack(componentIndex, trackIndex))
                        playAudioTrack(componentID: componentID, trackIndex: nextPlayingAudioTrackIndex)
                    } else {
                        output.send(.didRemoveAudioTrack(componentIndex, trackIndex))
                        output.send(.didSetAudioPlayingStateToStopped(componentIndex))
                    }
                } else {
                    datasource?.nowPlayingAudioIndex = component.detail.tracks.firstIndex {
                        $0.id == currentPlayingAudioTrackID
                    }
                    output.send(.didRemoveAudioTrack(componentIndex, trackIndex))
                }
            } else {
                output.send(.didRemoveAudioTrack(componentIndex, trackIndex))
            }
        }
    }

    private func getAudioSampleData(nowPlayingURL: URL?) -> AudioSampleData? {
        guard let nowPlayingURL, let file = try? AVAudioFile(forReading: nowPlayingURL) else {
            return nil
        }

        let audioFormat = file.processingFormat
        let audioFrameCount = UInt32(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
        else { return nil }
        do {
            try file.read(into: buffer)
        } catch {
            print(error)
        }

        let floatArray = UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength))

        let sampleRate = file.fileFormat.sampleRate

        let samplesPerBar = Int(sampleRate / Double(7))
        var result: [Float] = []

        for i in 0..<(floatArray.count / samplesPerBar) {
            let segment = floatArray[i * samplesPerBar..<(i + 1) * samplesPerBar]
            let avg = segment.map { abs($0) }.reduce(0, +) / Float(segment.count)
            result.append(avg)
        }

        guard let maxValue = result.max(), maxValue > 0 else {
            return AudioSampleData(
                sampleDataCount: floatArray.count,
                scaledSampleData: result,
                sampleRate: sampleRate)
        }
        let scaled = result.map { ($0 / maxValue) }

        return AudioSampleData(
            sampleDataCount: floatArray.count,
            scaledSampleData: scaled,
            sampleRate: sampleRate)
    }

    private func cleanDataSource(_ id: UUID) {
        performWithComponentAt(id) { (_, component: AudioComponent) in
            let datasource = component.datasource
            datasource?.nowPlayingAudioIndex = nil
            datasource?.isPlaying = nil
            datasource?.nowPlayingURL = nil
            datasource?.audioSampleData = nil
            datasource?.getProgress = nil
        }
    }

    @objc private func pauseAudioOnInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
            case .began:
                if let isPlaying = audioTrackController?.isPlaying,
                    isPlaying == true,
                    let nowPlayingAudioComponentID,
                    let pageComponent = memoPage[nowPlayingAudioComponentID],
                    let audioComponent = pageComponent.item as? AudioComponent,
                    let datasource = audioComponent.datasource,
                    let trackIndex = datasource.nowPlayingAudioIndex
                {
                    let componentIndex = pageComponent.index
                    audioTrackController?.togglePlaying()

                    datasource.isPlaying = false
                    output.send(
                        .didToggleAudioPlayingState(
                            componentIndex,
                            trackIndex,
                            false,
                            audioTrackController?.getCurrentTime()
                        )
                    )
                }

            default:
                break
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playNextAudioTrack()
    }
}

extension MemoPageViewModel: @preconcurrency ComponentsPageCollectionViewLayoutDelegate {
    func collectionView(heightForItemAt indexPath: IndexPath, with cellWidth: CGFloat) -> CGFloat {
        memoPage[indexPath.item].isMinimumHeight ? UIConstants.componentMinimumHeight : UIView.screenWidth - 40
    }
}

extension MemoPageViewModel: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        memoPage.compnentSize
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let subject = PassthroughSubject<MemoPageViewInput, Never>()
        subscribe(input: subject.eraseToAnyPublisher())

        return memoPage[indexPath.item]
            .getCollectionViewComponentCell(
                collectionView,
                indexPath,
                subject: subject
            )
    }
}

//extension MemoPageViewModel: UIDocumentPickerDelegate {
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        downloadAudioFromLocalFileSystem(didPickDocumentsAt: urls)
//    }
//}
