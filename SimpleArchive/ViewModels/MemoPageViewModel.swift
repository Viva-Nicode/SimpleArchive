import AVFAudio
import CSFBAudioEngine
import Combine
import SFBAudioEngine
import UIKit
import ZIPFoundation

@MainActor class MemoPageViewModel: NSObject, ViewModelType {

    typealias Input = MemoPageViewInput
    typealias Output = MemoPageViewOutput

    private var output = PassthroughSubject<Output, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private(set) var memoPage: MemoPageModel!
    private(set) var isReadOnly: Bool = false

    private var memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType
    private var componentFactory: any ComponentFactoryType
    private var audioDownloader: AudioDownloaderType = AudioDownloader()
    private var audioTrackController: AudioTrackControllerType?
    private var nowPlayingAudioComponentID: UUID?
    private var audioComponentDataSources: [UUID: AudioComponentDataSource] = [:]

    init(
        componentFactory: any ComponentFactoryType,
        memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType,
        page: MemoPageModel,
        isReadOnly: Bool = false
    ) {
        self.componentFactory = componentFactory
        self.memoComponentCoredataReposotory = memoComponentCoredataReposotory
        self.memoPage = page
        self.isReadOnly = isReadOnly

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

    deinit { print("MemoPageViewModel deinit") }

    @discardableResult
    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad:
                    output.send(.viewDidLoad(memoPage.name, isReadOnly))

                case .createNewComponent(let componentType):
                    createNewComponent(with: componentType)

                case .removeComponent(let componentID):
                    removeComponent(componentID: componentID)

                case .changeComponentName(let id, let newName):
                    changeComponentName(componentID: id, newName: newName)

                case .minimizeComponent(let componentID):
                    minimizeComponent(componentID: componentID)

                case .maximizeComponent(let componentID):
                    maximizeComponent(componentID: componentID)

                case .changeComponentOrder(let sourceIndex, let destinationIndex):
                    changeComponentOrder(sourceIndex: sourceIndex, destinationIndex: destinationIndex)

                case .tappedCaptureButton(let componentID, let description):
                    captureComponent(componentID: componentID, description: description)

                case .tappedSnapshotButton(let componentID):
                    moveToComponentSnapshotView(componentID: componentID)

                case .viewWillDisappear:
                    saveComponentsChanges()

                // MARK: - Table

                case .appendTableComponentRow(let componentID):
                    appendTableComponentRow(componentID)

                case .removeTableComponentRow(let componentID, let rowID):
                    removeTableComponentRow(componentID, rowID)

                case .appendTableComponentColumn(let componentID):
                    appendTableComponentColumn(componentID)

                case .editTableComponentCellValue(let componentID, let cellID, let newCellValue):
                    changeTableComponentCellValue(componentID, cellID, newCellValue)

                case .presentTableComponentColumnEditPopupView(let componentID, let tappedColumnIndex):
                    presentTableComponentColumnEditPopupView(componentID: componentID, columnIndex: tappedColumnIndex)

                case .editTableComponentColumn(let componentID, let columns):
                    editTableComponentColumn(componentID: componentID, columns: columns)

                // MARK: - Audio

                case .willDownloadMusicWithCode(let componentID, let downloadCode):
                    downloadAudio(componentID: componentID, with: downloadCode)

                case .willPlayAudioTrack(let componentID, let trackIndex):
                    playAudioTrack(componentID: componentID, trackIndex: trackIndex)

                case .willPresentGallery(let imageView):
                    output.send(.didPresentGallery(imageView))

                case .willEditAudioTrackMetadata(let editedMetadata, let componentID, let trackIndex):
                    editAudioMetadata(componentID: componentID, newMetadata: editedMetadata, trackIndex: trackIndex)

                case .willTapPlayPauseButton:
                    tapPlayPauseButton()

                case .willSeekAudioTrack(let seek):
                    seekAudioTrack(seek: seek)

                case .willSortAudioTracks(let componentID, let sortBy):
                    sortAudioTracks(componentID: componentID, sortBy: sortBy)

                case .willDropAudioTrack(let componentID, let src, let des):
                    dropAudioTrack(componentID: componentID, src: src, des: des)

                case .willRemoveAudioTrack(let componentID, let trackIndex):
                    removeAudioTrack(componentID: componentID, trackIndex: trackIndex)

                case .willPlayNextAudioTrack:
                    playNextAudioTrack()

                case .willPlayPreviousAudioTrack:
                    playPreviousAudioTrack()

                case .willStoreAudioComponentDataSource(let componentID, let datasource):
                    audioComponentDataSources[componentID] = datasource
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
        output.send(.insertNewComponentAtLastIndex(memoPage.compnentSize - 1))
    }

    private func removeComponent(componentID: UUID) {
        if let removedComponent = memoPage.removeChildComponentById(componentID) {
            memoComponentCoredataReposotory.removeComponent(
                parentPageID: memoPage.id,
                componentID: removedComponent.item.id)
            output.send(.removeComponentAtIndex(removedComponent.index))
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
                output.send(.didMinimizeComponentHeight(index, component.isMinimumHeight))
            } else {
                output.send(.maximizeComponent(component, index))
            }
        }
    }

    private func minimizeComponent(componentID: UUID) {
        performWithComponentAt(componentID) { index, component in
            component.isMinimumHeight.toggle()
            let pageComponentChangeObject = PageComponentChangeObject(
                componentIdChanged: componentID,
                isMinimumHeight: component.isMinimumHeight)
            memoComponentCoredataReposotory.updateComponentChanges(componentChanges: pageComponentChangeObject)
            output.send(.didMinimizeComponentHeight(index, component.isMinimumHeight))
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
                    desc: description)
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

        output.send(.didTappedSnapshotButton(componentSnapshotViewModel, component.index))
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

    @objc private func saveComponentsChanges() {
        memoPage.getComponents.compactMap { $0 as? AudioComponent }.forEach { $0.datasource = nil }
        let components = memoPage.getComponents.compactMap { $0.currentIfUnsaved() }
        memoComponentCoredataReposotory.saveComponentsDetail(changedComponents: components)
    }
}

extension MemoPageViewModel {

    private func appendTableComponentRow(_ componentID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let newRow = tableComponent.componentDetail.appendNewRow()
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didAppendTableComponentRow(componentIndex, newRow))
        }
    }

    private func removeTableComponentRow(_ componentID: UUID, _ rowID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let removedRowIndex = tableComponent.componentDetail.removeRow(rowID)
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didRemoveTableComponentRow(componentIndex, removedRowIndex))
        }
    }

    private func appendTableComponentColumn(_ componentID: UUID) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let newColumn = tableComponent.componentDetail.appendNewColumn(columnTitle: "column")
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didAppendTableComponentColumn(componentIndex, newColumn))
        }
    }

    private func changeTableComponentCellValue(_ componentID: UUID, _ cellID: UUID, _ newCellValue: String) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            let indices = tableComponent.componentDetail.editCellValeu(cellID, newCellValue)
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didEditTableComponentCellValue(componentIndex, indices.0, indices.1, newCellValue))
        }
    }

    private func presentTableComponentColumnEditPopupView(componentID: UUID, columnIndex: Int) {
        performWithComponentAt(componentID) { (_, tableComponent: TableComponent) in
            output.send(
                .didPresentTableComponentColumnEditPopupView(
                    tableComponent.componentDetail.columns, columnIndex, componentID))
        }
    }

    private func editTableComponentColumn(componentID: UUID, columns: [TableComponentColumn]) {
        performWithComponentAt(componentID) { (componentIndex, tableComponent: TableComponent) in
            tableComponent.componentDetail.setColumn(columns)
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didEditTableComponentColumn(componentIndex, columns))
        }
    }
}

extension MemoPageViewModel: @preconcurrency AVAudioPlayerDelegate {

    private func downloadAudio(componentID: UUID, with code: String) {
        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in

            let currentPlayingAudioTrackID = component.detail[component.datasource?.nowPlayingAudioIndex]?.id

            audioDownloader.handleDownloadedProgressPercent = { [weak self] progress in
                self?.output.send(.updateAudioDownloadProgress(componentIndex, progress))
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
                            // audioComponentDataSources[componentID]?.tracks = component.detail.tracks
                            //audioComponentDataSources[componentID]?.nowPlayingAudioIndex = component.detail.tracks
                            output.send(.didDownloadMusicWithCode(componentIndex, appendedIndices))

                        case .failure(let failure):
                            switch failure {
                                case .invalidCode:
                                    break
                                case .unowned(let msg):
                                    print(msg)
                            }
                            output.send(.presentInvalidDownloadCode(componentIndex))
                    }
                }
                .store(in: &subscriptions)
        }
    }

    private func playAudioTrack(componentID: UUID, trackIndex: Int) {

        let previousComponentIndex = memoPage[nowPlayingAudioComponentID ?? UUID()]?.index

        if let nowPlayingAudioComponentID {
            cleanDataSource(nowPlayingAudioComponentID)
        }

        nowPlayingAudioComponentID = componentID

        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in
            audioComponentDataSources[componentID]?.isPlaying = true
            audioComponentDataSources[componentID]?.nowPlayingAudioIndex = trackIndex
            audioTrackController = AudioTrackController(audioTrackName: component.trackNames[trackIndex])
            audioComponentDataSources[componentID]?.nowPlayingURL = audioTrackController?.audioTrackURL

            audioTrackController?.player?.delegate = self
            audioTrackController?.play()

            let audioSampleData = getAudioSampleData(nowPlayingURL: audioTrackController?.audioTrackURL)
            audioComponentDataSources[componentID]?.audioSampleData = audioSampleData
            audioComponentDataSources[componentID]?.getProgress = { [weak self] in
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

            if var unwrappedCurrentPlayingTrackIndex = audioComponentDataSources[nowPlayingAudioComponentID]?
                .nowPlayingAudioIndex
            {
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

            if var unwrappedCurrentPlayingTrackIndex = audioComponentDataSources[nowPlayingAudioComponentID]?
                .nowPlayingAudioIndex
            {
                unwrappedCurrentPlayingTrackIndex -= 1
                if 0 > unwrappedCurrentPlayingTrackIndex {
                    unwrappedCurrentPlayingTrackIndex = audioComponent.detail.tracks.count - 1
                }
                playAudioTrack(componentID: nowPlayingAudioComponentID, trackIndex: unwrappedCurrentPlayingTrackIndex)
            }
        }
    }

    private func tapPlayPauseButton() {
        audioTrackController?.togglePlaying()

        if let isPlaying = audioTrackController?.isPlaying,
            let nowPlayingAudioComponentID,
            let componentIndex = memoPage[nowPlayingAudioComponentID]?.index,
            let trackIndex = audioComponentDataSources[nowPlayingAudioComponentID]?.nowPlayingAudioIndex
        {
            audioComponentDataSources[nowPlayingAudioComponentID]?.isPlaying = isPlaying
            output.send(
                .didTapPlayPauseButton(
                    componentIndex,
                    trackIndex,
                    isPlaying,
                    audioTrackController?.getCurrentTime()
                )
            )
        }
    }

    private func editAudioMetadata(componentID: UUID, newMetadata: AudioTrackMetadata, trackIndex: Int) {
        performWithComponentAt(componentID) { (componentIndex, component: AudioComponent) in
            let targetAudioTrackID = component.detail[trackIndex]?.id
            let currentPlayingAudioTrackID = component.detail[
                audioComponentDataSources[componentID]?.nowPlayingAudioIndex]?
                .id
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
                    audioComponentDataSources[componentID]?.nowPlayingAudioIndex = component.detail.tracks.firstIndex {
                        $0.id == currentPlayingAudioTrackID
                    }
                }
            }

            audioComponentDataSources[componentID]?.tracks = component.detail.tracks

            output.send(
                .didEditAudioTrackMetadata(
                    componentIndex,
                    trackIndex,
                    newMetadata,
                    audioComponentDataSources[componentID]?.nowPlayingAudioIndex == trackIndex,
                    trackIndexAfterEdit)
            )
        }
    }

    private func seekAudioTrack(seek: TimeInterval) {
        audioTrackController?.seek(interval: seek)

        if let nowPlayingAudioComponentID,
            let componentIndex = memoPage[nowPlayingAudioComponentID]?.index,
            let trackIndex = audioComponentDataSources[nowPlayingAudioComponentID]?.nowPlayingAudioIndex
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

    private func dropAudioTrack(componentID: UUID, src: Int, des: Int) {
        performWithComponentAt(componentID) { (_, audioComponent: AudioComponent) in
            let datasource = audioComponentDataSources[componentID]
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

            let datasource = audioComponentDataSources[componentID]
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

            audioComponentDataSources[componentID]?.nowPlayingAudioIndex = audioComponent.detail.tracks.firstIndex {
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

            let datasource = audioComponentDataSources[componentID]
            let currentPlayingAudioTrackID = component.detail[datasource?.nowPlayingAudioIndex]?.id
            let fileManager = FileManager.default
            let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let targetTrack = component.detail.tracks.remove(at: trackIndex)
            let trackURL = documentsDir.appendingPathComponent(
                "SimpleArchiveMusics/\(targetTrack.id).\(targetTrack.fileExtension)")

            try? fileManager.removeItem(at: trackURL)

            datasource?.tracks = component.detail.tracks

            if datasource?.nowPlayingAudioIndex != nil {
                if component.detail.tracks.isEmpty {
                    audioTrackController = nil
                    nowPlayingAudioComponentID = nil
                    cleanDataSource(componentID)
                    output.send(.didRemoveAudioTrack(componentIndex, trackIndex))
                    output.send(.outOfSongs(componentIndex))
                    return
                }

                if datasource?.nowPlayingAudioIndex == trackIndex {
                    let nextPlayingAudioTrackIndex = min(trackIndex, component.detail.tracks.count - 1)
                    output.send(.didRemoveAudioTrack(componentIndex, trackIndex))
                    playAudioTrack(componentID: componentID, trackIndex: nextPlayingAudioTrackIndex)
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
        let datasource = audioComponentDataSources[id]
        datasource?.nowPlayingAudioIndex = nil
        datasource?.isPlaying = nil
        datasource?.nowPlayingURL = nil
        datasource?.audioSampleData = nil
        datasource?.getProgress = nil
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
                    let datasource = audioComponentDataSources[nowPlayingAudioComponentID],
                    let componentIndex = memoPage[nowPlayingAudioComponentID]?.index,
                    let trackIndex = datasource.nowPlayingAudioIndex
                {
                    audioTrackController?.togglePlaying()

                    datasource.isPlaying = false
                    output.send(
                        .didTapPlayPauseButton(
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
                isReadOnly: isReadOnly,
                subject: subject)
    }
}
