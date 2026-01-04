import AVFAudio
import Combine
import SFBAudioEngine
import UIKit

@MainActor final class MemoPageViewModel: NSObject, ViewModelType {

    typealias Input = MemoPageViewInput
    typealias Output = MemoPageViewOutput

    private var output = PassthroughSubject<Output, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private(set) var memoPage: MemoPageModel!

    private var memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType
    private var componentFactory: any ComponentFactoryType

    private var audioDownloader: AudioDownloaderType
    private var audioTrackController: AudioTrackControllerType
    private var audioFileManager: AudioFileManagerType
    private(set) var nowPlayingAudioComponentID: UUID?
    private(set) var audioComponentDataSources: [UUID: AudioComponentDataSource] = [:]

    private let captureDispatchSemaphore = DispatchSemaphore(value: 1)

    init(
        componentFactory: any ComponentFactoryType,
        memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType,
        audioDownloader: AudioDownloaderType,
        audioFileManager: AudioFileManagerType,
        audioTrackController: AudioTrackControllerType,
        page: MemoPageModel,
    ) {
        self.componentFactory = componentFactory
        self.memoComponentCoredataReposotory = memoComponentCoredataReposotory
        self.memoPage = page
        self.audioTrackController = audioTrackController
        self.audioDownloader = audioDownloader
        self.audioFileManager = audioFileManager

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(captureComponentsChanges),
            name: UIScene.didEnterBackgroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(captureComponentsChanges),
            name: UIScene.didDisconnectNotification,
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
                    captureComponentsChangesOnDisappear()

                // MARK: - Text

                case .willEditTextComponent(let componentID, let detail):
                    saveTextEditorComponentChanged(componentID: componentID, contents: detail)

                case .willUndoTextComponentContents(let componentID):
                    undoTextEditorComponentContents(componentID: componentID)

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

        memoPage.appendChildComponent(component: newComponent)
        memoComponentCoredataReposotory.createComponentEntity(parentPageID: memoPage.id, component: newComponent)
        output.send(.didAppendComponentAt(memoPage.compnentSize - 1))
    }

    private func removeComponent(componentID: UUID) {
        if let removedComponent = memoPage.removeChildComponentById(componentID) {
            if let audioComponent = removedComponent.item as? AudioComponent {
                for audioTrack in audioComponent.componentContents.tracks {
                    audioFileManager.removeAudio(with: audioTrack)
                }
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
            if let snapshotRestorableComponent = component as? any SnapshotRestorablePageComponent {
                memoComponentCoredataReposotory.captureSnapshot(
                    snapshotRestorableComponent: snapshotRestorableComponent,
                    snapShotDescription: description)
                output.send(.didCompleteComponentCapture(index))
            }
        }
    }

    private func moveToComponentSnapshotView(componentID: UUID) {
        guard
            let repository = DIContainer.shared.resolve(ComponentSnapshotCoreDataRepository.self),
            let component = memoPage[componentID],
            let snapshotRestorableComponent = component.item as? any SnapshotRestorablePageComponent
        else { return }

        let componentSnapshotViewModel = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: repository,
            snapshotRestorableComponent: snapshotRestorableComponent)

        output.send(.didNavigateSnapshotView(componentSnapshotViewModel, component.index))
    }

    private func captureComponentsChangesOnDisappear() {
        let components = memoPage.getComponents
            .compactMap { $0 as? any SnapshotRestorablePageComponent }
            .compactMap { $0.currentIfUnsaved() }

        if components.isEmpty {
            print("no components to capture")
        } else {
            memoComponentCoredataReposotory.captureSnapshot(snapshotRestorableComponents: components)
        }
    }

    @objc private func captureComponentsChanges() {

        var taskID: UIBackgroundTaskIdentifier = .invalid

        taskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(taskID)
            taskID = .invalid
        }

        captureDispatchSemaphore.wait()

        let start = CACurrentMediaTime()

        let components = memoPage.getComponents
            .compactMap { $0 as? any SnapshotRestorablePageComponent }
            .compactMap { $0.currentIfUnsaved() }

        if components.isEmpty {
            print("no components to capture")
            UIApplication.shared.endBackgroundTask(taskID)
            captureDispatchSemaphore.signal()
        } else {
            memoComponentCoredataReposotory.captureSnapshot(snapshotRestorableComponents: components)
                .sinkToResult { result in
                    print(CACurrentMediaTime() - start)
                    switch result {
                        case .success:
                            print("capture successfully")
                        case .failure(let failure):
                            print("capture fail reason : \(failure.localizedDescription)")
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
    private func saveTextEditorComponentChanged(componentID: UUID, contents: String) {
        performWithComponentAt(componentID) { (componentIndex, textEditorComponent: TextEditorComponent) in
            let action = makeTextEditActionFromContentsDiff(
                originContents: textEditorComponent.componentContents,
                editedContents: contents)
            textEditorComponent.componentContents = contents
            textEditorComponent.setCaptureState(to: .needsCapture)
            textEditorComponent.actions.append(action)
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: textEditorComponent)
        }
    }

    private func undoTextEditorComponentContents(componentID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, textEditorComponent: TextEditorComponent) in
            guard let action = textEditorComponent.actions.popLast() else { return }
            let currentContents = textEditorComponent.componentContents
            let undidText = undoingText(action: action, contents: currentContents)

            textEditorComponent.componentContents = undidText
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: textEditorComponent)
            output.send(.didUndoTextComponentContents(componentIndex, undidText))
        }
    }

    private func makeTextEditActionFromContentsDiff(originContents: String, editedContents: String)
        -> TextEditorComponentAction
    {
        let originChars = Array(originContents)
        let editedChars = Array(editedContents)

        var prefix = 0
        while prefix < min(originChars.count, editedChars.count),
            originChars[prefix] == editedChars[prefix]
        {
            prefix += 1
        }

        var suffix = 0
        while suffix < min(originChars.count - prefix, editedChars.count - prefix),
            originChars[originChars.count - 1 - suffix] == editedChars[editedChars.count - 1 - suffix]
        {
            suffix += 1
        }

        let oldRange = prefix..<(originChars.count - suffix)
        let newRange = prefix..<(editedChars.count - suffix)

        let removedText = String(originChars[oldRange])
        let insertedText = String(editedChars[newRange])

        if removedText.isEmpty, !insertedText.isEmpty {
            return .insert(range: prefix..<prefix, text: insertedText)
        } else {
            return .replace(range: oldRange, from: removedText, to: insertedText)
        }
    }

    private func undoingText(action: TextEditorComponentAction, contents: String) -> String {
        switch action {
            case let .insert(range, insertedText):
                let start = contents.index(contents.startIndex, offsetBy: range.lowerBound)
                let end = contents.index(start, offsetBy: insertedText.count)

                return contents.replacingCharacters(in: start..<end, with: "")

            case let .replace(range, fromText, toText):
                let start = contents.index(contents.startIndex, offsetBy: range.lowerBound)
                let end = contents.index(start, offsetBy: toText.count)

                return contents.replacingCharacters(in: start..<end, with: fromText)
        }
    }
}

extension MemoPageViewModel {
    private func appendTableComponentRow(_ componentID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let newRow = tableComponent.componentContents.appendNewRow()
            tableComponent.setCaptureState(to: .needsCapture)
            tableComponent.actions.append(.appendRow(row: newRow))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
            output.send(.didAppendRowToTableView(componentIndex, newRow))
        }
    }

    private func removeTableComponentRow(_ componentID: UUID, _ rowID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let removedRowIndex = tableComponent.componentContents.removeRow(rowID)
            tableComponent.setCaptureState(to: .needsCapture)
            tableComponent.actions.append(.removeRow(rowID: rowID))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
            output.send(.didRemoveRowToTableView(componentIndex, removedRowIndex))
        }
    }

    private func appendTableComponentColumn(_ componentID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let newColumn = tableComponent.componentContents.appendNewColumn(title: "column")
            tableComponent.setCaptureState(to: .needsCapture)
            tableComponent.actions.append(.appendColumn(column: newColumn))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
            output.send(.didAppendColumnToTableView(componentIndex, newColumn))
        }
    }

    private func applyTableCellValue(componentID: UUID, colID: UUID, rowID: UUID, newCellValue: String) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let indices = tableComponent
                .componentContents
                .editCellValeu(rowID: rowID, colID: colID, newValue: newCellValue)
            tableComponent.setCaptureState(to: .needsCapture)
            tableComponent.actions.append(.editCellValue(rowID: rowID, columnID: colID, value: newCellValue))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
            output.send(
                .didApplyTableCellValueChanges(componentIndex, indices.rowIndex, indices.columnIndex, newCellValue)
            )
        }
    }

    private func presentTableComponentColumnEditPopupView(componentID: UUID, columnID: UUID) {
        performWithComponentAt(componentID) { (_, tableComponent: TableComponent) in
            let columnIndex = tableComponent.componentContents.columns.firstIndex(where: { $0.id == columnID })!
            output.send(
                .didPresentTableColumnEditPopupView(
                    tableComponent.componentContents.columns, columnIndex, componentID)
            )
        }
    }

    private func applyTableColumnChanges(componentID: UUID, columns: [TableComponentColumn]) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            tableComponent.componentContents.setColumn(columns: columns)
            tableComponent.setCaptureState(to: .needsCapture)
            tableComponent.actions.append(.editColumn(columns: columns))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
            output.send(.didApplyTableColumnChanges(componentIndex, columns))
        }
    }
}

extension MemoPageViewModel: @preconcurrency AVAudioPlayerDelegate {

    private func downloadAudio(componentID: UUID, with code: String) {
        guard let audioComponentDataSource = audioComponentDataSources[componentID] else { return }

        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in
            let currentPlayingAudioTrackID = audioComponentDataSource.nowPlayingAudioIndex
                .flatMap { component.componentContents.tracks[$0].id }

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

                            audioComponentDataSource.tracks = component.componentContents.tracks
                            audioComponentDataSource.nowPlayingAudioIndex = component.componentContents.tracks
                                .firstIndex { $0.id == currentPlayingAudioTrackID }

                            component.actions.append(
                                .appendAudio(appendedIndices: appendedIndices, tracks: audioTracks))
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

        guard let audioComponentDataSource = audioComponentDataSources[componentID] else { return }
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

            let currentPlayingAudioTrackID = audioComponentDataSource.nowPlayingAudioIndex
                .flatMap { component.componentContents.tracks[$0].id }
            let appendedIndices = component.addAudios(audiotracks: audioTracks)

            audioComponentDataSource.tracks = component.componentContents.tracks
            audioComponentDataSource.nowPlayingAudioIndex = component.componentContents.tracks
                .firstIndex { $0.id == currentPlayingAudioTrackID }

            component.actions.append(
                .appendAudio(appendedIndices: appendedIndices, tracks: audioTracks))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: component)

            output.send(.didAppendAudioTrackRows(componentIndex, appendedIndices))
        }
    }

    private func playAudioTrack(componentID: UUID, trackIndex: Int) {

        let previousComponentIndex = memoPage[nowPlayingAudioComponentID]?.index

        if let nowPlayingAudioComponentID {
            cleanDataSource(nowPlayingAudioComponentID)
        }

        nowPlayingAudioComponentID = componentID

        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in

            let audioTrack = component.componentContents.tracks[trackIndex]
            let audioTrackURL = audioFileManager.createAudioFileURL(fileName: component.trackNames[trackIndex])
            let audioPCMData = audioFileManager.readAudioPCMData(audioURL: audioTrackURL)
            let waveformData = scalingPCMDataToWaveformData(pcmData: audioPCMData)

            audioTrackController.setAudioURL(audioURL: audioTrackURL)
            audioTrackController.player?.delegate = self
            audioTrackController.play()

            let audioComponentDataSource = audioComponentDataSources[componentID]

            audioComponentDataSource?.isPlaying = true
            audioComponentDataSource?.nowPlayingAudioIndex = trackIndex
            audioComponentDataSource?.nowPlayingURL = audioTrackURL
            audioComponentDataSource?.audioVisualizerData = waveformData
            audioComponentDataSource?.getProgress = { [weak self] in
                guard let self else { return .zero }
                return audioTrackController.currentTime! / audioTrackController.totalTime!
            }

            let audioTotalDuration = audioTrackController.totalTime
            let audioMetadata = AudioTrackMetadata(
                title: audioTrack.title,
                artist: audioTrack.artist,
                lyrics: audioTrack.lyrics,
                thumbnail: audioTrack.thumbnail)

            output.send(
                .didPlayAudioTrack(
                    previousComponentIndex,
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
        guard let nowPlayingAudioComponentID else { return }
        performWithComponentAt(nowPlayingAudioComponentID) { (_, audioComponent: AudioComponent) in
            let audioComponentDataSource = audioComponentDataSources[nowPlayingAudioComponentID]

            if var unwrappedCurrentPlayingTrackIndex = audioComponentDataSource?.nowPlayingAudioIndex {
                unwrappedCurrentPlayingTrackIndex += 1
                if audioComponent.componentContents.tracks.count <= unwrappedCurrentPlayingTrackIndex {
                    unwrappedCurrentPlayingTrackIndex = 0
                }
                playAudioTrack(componentID: nowPlayingAudioComponentID, trackIndex: unwrappedCurrentPlayingTrackIndex)
            }
        }
    }

    private func playPreviousAudioTrack() {
        guard let nowPlayingAudioComponentID else { return }
        performWithComponentAt(nowPlayingAudioComponentID) { (_, audioComponent: AudioComponent) in
            let audioComponentDataSource = audioComponentDataSources[nowPlayingAudioComponentID]

            if var unwrappedCurrentPlayingTrackIndex = audioComponentDataSource?.nowPlayingAudioIndex {
                unwrappedCurrentPlayingTrackIndex -= 1
                if 0 > unwrappedCurrentPlayingTrackIndex {
                    unwrappedCurrentPlayingTrackIndex = audioComponent.componentContents.tracks.count - 1
                }
                playAudioTrack(componentID: nowPlayingAudioComponentID, trackIndex: unwrappedCurrentPlayingTrackIndex)
            }
        }
    }

    private func toggleAudioPlayingState() {
        guard let nowPlayingAudioComponentID else { return }
        audioTrackController.togglePlaying()

        performWithComponentAt(nowPlayingAudioComponentID) { (_, audioComponent: AudioComponent) in
            if let componentIndex = memoPage[nowPlayingAudioComponentID]?.index,
                let audioComponentDataSource = audioComponentDataSources[nowPlayingAudioComponentID],
                let trackIndex = audioComponentDataSource.nowPlayingAudioIndex
            {
                let isPlaying = audioTrackController.isPlaying
                audioComponentDataSource.isPlaying = isPlaying
                output.send(
                    .didToggleAudioPlayingState(
                        componentIndex,
                        trackIndex,
                        isPlaying
                    )
                )
            }
        }
    }

    private func applyAudioMetadataChanges(componentID: UUID, newMetadata: AudioTrackMetadata, trackIndex: Int) {
        guard let audioComponentDataSource = audioComponentDataSources[componentID] else { return }

        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in
            let trackID = component.componentContents.tracks[trackIndex].id
            let nowPlayingAudioIndex = audioComponentDataSource.nowPlayingAudioIndex
            let currentPlayingAudioTrackID = nowPlayingAudioIndex.flatMap { component.componentContents.tracks[$0].id }

            let isEditCurrentlyPlayingAudio = nowPlayingAudioIndex == trackIndex
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

            component.actions.append(.applyAudioMetadata(audioID: trackID, metadata: newMetadata))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: component)
            audioFileManager.writeAudioMetadata(audioTrack: component.componentContents.tracks[trackIndex])

            if component.componentContents.sortBy == .name {
                component.componentContents.tracks.sort(by: { $0.title < $1.title })
                trackIndexAfterApply = component.componentContents.tracks.firstIndex {
                    $0.id == trackID
                }

                if let currentPlayingAudioTrackID {
                    audioComponentDataSource.nowPlayingAudioIndex = component.componentContents.tracks.firstIndex {
                        $0.id == currentPlayingAudioTrackID
                    }
                }
            }

            audioComponentDataSource.tracks = component.componentContents.tracks

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
        performWithComponentAt(nowPlayingAudioComponentID!) { (_, audioComponent: AudioComponent) in
            audioTrackController.seek(interval: seek)
            if let nowPlayingAudioComponentID,
                let componentIndex = memoPage[nowPlayingAudioComponentID]?.index,
                let audioComponentDataSource = audioComponentDataSources[nowPlayingAudioComponentID],
                let trackIndex = audioComponentDataSource.nowPlayingAudioIndex
            {
                output.send(
                    .didSeekAudioTrack(
                        componentIndex,
                        trackIndex,
                        seek,
                        audioTrackController.totalTime
                    )
                )
            }
        }
    }

    private func moveAudioTrackOrder(componentID: UUID, src: Int, des: Int) {
        performWithComponentAt(componentID) { (_, audioComponent: AudioComponent) in
            guard let datasource = audioComponentDataSources[componentID] else { return }
            let currentPlayingAudioTrackID = datasource.nowPlayingAudioIndex
                .flatMap { audioComponent.componentContents.tracks[$0].id }

            audioComponent.componentContents.tracks.moveElement(src: src, des: des)
            audioComponent.componentContents.sortBy = .manual

            datasource.tracks = audioComponent.componentContents.tracks
            datasource.sortBy = .manual

            audioComponent.actions.append(.moveAudioOrder(src: src, des: des))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: audioComponent)

            datasource.nowPlayingAudioIndex = audioComponent.componentContents.tracks.firstIndex {
                $0.id == currentPlayingAudioTrackID
            }
        }
    }

    private func sortAudioTracks(componentID: UUID, sortBy: AudioTrackSortBy) {
        guard let audioComponentDataSource = audioComponentDataSources[componentID] else { return }

        performWithComponentAt(componentID) { (componentIndex, audioComponent: AudioComponent) in
            audioComponent.componentContents.sortBy = sortBy

            let currentPlayingAudioTrackID = audioComponentDataSource.nowPlayingAudioIndex
                .flatMap { audioComponent.componentContents.tracks[$0].id }

            let before = audioComponent.trackNames

            switch sortBy {
                case .name:
                    audioComponent.componentContents.tracks.sort(by: { $0.title < $1.title })

                case .createDate:
                    audioComponent.componentContents.tracks.sort(by: { $0.createData > $1.createData })

                case .manual:
                    break
            }
            audioComponentDataSource.nowPlayingAudioIndex = audioComponent.componentContents.tracks.firstIndex {
                $0.id == currentPlayingAudioTrackID
            }

            let after = audioComponent.trackNames

            audioComponentDataSource.tracks = audioComponent.componentContents.tracks
            audioComponentDataSource.sortBy = sortBy

            audioComponent.actions.append(.sortAudioTracks(sortBy: sortBy))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: audioComponent)

            output.send(.didSortAudioTracks(componentIndex, before, after))
        }
    }

    private func removeAudioTrack(componentID: UUID, trackIndex: Int) {
        guard let audioComponentDataSource = audioComponentDataSources[componentID] else { return }

        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in

            let currentPlayingAudioTrackID = audioComponentDataSource.nowPlayingAudioIndex
                .flatMap { component.componentContents.tracks[$0].id }

            let removedAudioTrack = component.componentContents.tracks.remove(at: trackIndex)

            audioFileManager.removeAudio(with: removedAudioTrack)
            audioComponentDataSource.tracks = component.componentContents.tracks
            component.actions.append(.removeAudio(removedAudioID: removedAudioTrack.id))
            memoComponentCoredataReposotory.updateComponentContentChanges(modifiedComponent: component)

            if audioComponentDataSource.nowPlayingAudioIndex != nil {
                if component.componentContents.tracks.isEmpty {
                    audioTrackController.reset()
                    nowPlayingAudioComponentID = nil
                    cleanDataSource(componentID)
                    output.send(.didRemoveAudioTrackAndStopPlaying(componentIndex, trackIndex))
                    return
                }

                if audioComponentDataSource.nowPlayingAudioIndex == trackIndex {
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

                        audioComponentDataSource.nowPlayingAudioIndex = nextPlayingAudioTrackIndex
                        audioComponentDataSource.nowPlayingURL = audioTrackURL
                        audioComponentDataSource.audioVisualizerData = waveformData
                        audioComponentDataSource.getProgress = { [weak self] in
                            guard let self else { return .zero }
                            return audioTrackController.currentTime! / audioTrackController.totalTime!
                        }

                        let audioTotalDuration = audioTrackController.totalTime
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
                        nowPlayingAudioComponentID = nil
                        cleanDataSource(componentID)
                        output.send(.didRemoveAudioTrackAndStopPlaying(componentIndex, trackIndex))
                    }
                } else {
                    audioComponentDataSource.nowPlayingAudioIndex = component.componentContents.tracks.firstIndex {
                        $0.id == currentPlayingAudioTrackID
                    }
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
        let samplesPerBar = Int(pcmData.sampleRate / timerIntervalDivisor)  // 0.1666초 마다 애니메이팅
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

    private func cleanDataSource(_ componentID: UUID) {
        let datasource = audioComponentDataSources[componentID]
        datasource?.nowPlayingAudioIndex = nil
        datasource?.isPlaying = nil
        datasource?.nowPlayingURL = nil
        datasource?.audioVisualizerData = nil
        datasource?.getProgress = nil
    }

    @objc private func pauseAudioOnInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        switch type {
            case .began:
                if audioTrackController.isPlaying == true,
                    let nowPlayingAudioComponentID,
                    let pageComponent = memoPage[nowPlayingAudioComponentID],
                    let datasource = audioComponentDataSources[nowPlayingAudioComponentID],
                    let trackIndex = datasource.nowPlayingAudioIndex
                {
                    let componentIndex = pageComponent.index
                    audioTrackController.togglePlaying()

                    datasource.isPlaying = false
                    output.send(
                        .didToggleAudioPlayingState(
                            componentIndex,
                            trackIndex,
                            false
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

        let componentModel = memoPage[indexPath.item]

        let cell = componentModel.getCollectionViewComponentCell(
            collectionView,
            indexPath,
            subject: subject
        )

        if let audioComponentView = cell as? AudioComponentView,
            let audioComponent = componentModel as? AudioComponent
        {
            if let datasource = self.audioComponentDataSources[audioComponent.id] {
                audioComponentView.componentContentView.audioTrackTableView.dataSource = datasource
            } else {
                let datasource = AudioComponentDataSource(
                    tracks: audioComponent.componentContents.tracks,
                    sortBy: audioComponent.componentContents.sortBy
                )
                self.audioComponentDataSources[audioComponent.id] = datasource
                audioComponentView.componentContentView.audioTrackTableView.dataSource = datasource
            }
        }

        return cell
    }
}

#if DEBUG
    extension MemoPageViewModel {
        func setNowPlayingAudioComponentID(_ id: UUID) {
            self.nowPlayingAudioComponentID = id
        }

        func setAudioTrackDataSource(id: UUID, datasource: AudioComponentDataSource) {
            self.audioComponentDataSources[id] = datasource
        }
    }
#endif
