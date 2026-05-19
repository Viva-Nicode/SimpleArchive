import Combine
import UIKit

@MainActor final class MemoHomeViewModel: NSObject {
    typealias Input = MemoHomeViewInput
    typealias Output = MemoHomeViewOutput

    private var currentTab: CurrentTap = .mainDirectory

    private var currentDirectory: MemoDirectoryModel! {
        currentTab == .mainDirectory ? directoryStack.stack.last : privateDirectoryStack.stack.last
    }

    private var currentRootDirectory: MemoDirectoryModel! {
        currentTab == .mainDirectory ? directoryStack.stack.first : privateDirectoryStack.stack.first
    }

    private var output = PassthroughSubject<MemoHomeViewOutput, Never>()
    private var errorOutput = PassthroughSubject<MemoHomeViewModelError, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private var directoryStack = DirectoryStack()
    private var privateDirectoryStack = DirectoryStack()

    private var memoDirectoryCoredataReposotory: MemoDirectoryCoreDataRepositoryType

    private let directoryCreator: any FileCreatorType
    private let pageCreator: any PageCreatorType

    private var restoredPageListSubject = PassthroughSubject<[MemoPageModel], Never>()
    private var restoredPageListSubjectSubscription: AnyCancellable?

    private var memoHomeDirectoryContentCellDataSources: [UUID: DirectoryContentDataSource] = [:]
    private var audioFileManager: AudioFileManagerType

    private let spacing = UIConstants.fileItemSpacing
    private var info = DirectoryContentsRenderInfo()

    private var selectedItem: [any StorageItem] = []
    private let signatureManager: PrivateDirectorySignatureManagerType
    private let contentsConfigurationManager: UserContentsConfigurationManagerType
    private var isUnlockedPrivateDirectory = false

    init(
        memoDirectoryCoredataReposotory: MemoDirectoryCoreDataRepositoryType,
        directoryCreator: any FileCreatorType,
        pageCreator: any PageCreatorType,
        audioFileManager: AudioFileManagerType,
        signatureManager: PrivateDirectorySignatureManagerType,
        userContentConfigurationManager: UserContentsConfigurationManagerType
    ) {
        self.memoDirectoryCoredataReposotory = memoDirectoryCoredataReposotory
        self.directoryCreator = directoryCreator
        self.pageCreator = pageCreator
        self.audioFileManager = audioFileManager
        self.signatureManager = signatureManager
        self.contentsConfigurationManager = userContentConfigurationManager
        super.init()
    }

    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }
            switch event {
                case .viewDidLoad: fetchMemoData()
                case .willNavigateDormantBoxView: getDormantBoxViewModel()
                case .willChangeFileName(let fileID, let newName): changeFileName(fileID: fileID, newName: newName)
                case .willSortDirectoryItems(let sortBy): changeSortCriteria(sortBy: sortBy)
                case .willCreatedNewDirectory(let newDirectoryName): createdNewDirectory(newDirectoryName)
                case .willMoveToFollowingDirectory(let index): moveToFollowingDirectory(index: index)
                case .willNavigatePageView(let pageIndex): moveToPage(followingPageIndex: pageIndex)
                case .willMoveFileToDormantBox(let itemID): moveFileToDormantBox(itemID: itemID)
                case .willManualAutoGrid: gridSortItems()
                case .willSortManualOrder(let id, let frame): manualOrder(id, frame)
                case .willCreatedNewPage(let newPageName, let type): createdNewPage(newPageName, type)
                case .willMovePreviousDirectoryPath(let targetDirId): moveToPreviousDirectory(targetDirId)
                case .willChangeFileItemColor(let id, let color): changeFileItemColor(id, color)
                case .willPresentFileItemInfoView(let id): getFileItemInfo(itemID: id)
                case .willUpdateCurrentRootDirectoryInfo: updateCurrentRootDirectoryInfo()
                case .willMoveSelectedItems: moveSelectedItems()
                case .willSelectFileItem(let itemID):
                    if let idx = currentDirectory.items.firstIndex(where: { $0.id == itemID }) {
                        selectedItem.append(currentDirectory.items[idx])
                        output.send(.didSelectFileItem(currentDirectory.items[idx].name, itemID))
                    }

                case .willRemoveFromSelectedItems(let itemId):
                    if let index = selectedItem.firstIndex(where: { $0.id == itemId }) {
                        let idx = currentDirectory.items.firstIndex(where: { $0.id == itemId })
                        selectedItem.remove(at: index)
                        output.send(.didRemoveFromSelectedItems(index, idx, itemId))
                    }

                case .willCancelAllSelection:
                    if !selectedItem.isEmpty {
                        selectedItem = []
                        output.send(.didCancelAllSelection)
                    }

                case .willHidingItem(let itemID):
                    if let index = currentDirectory.items.firstIndex(where: { $0.id == itemID }) {
                        let item = currentDirectory.items[index]
                        if let idx = info[item.parentDirectory!.id].firstIndex(where: { $0.id == item.id }) {
                            info[item.parentDirectory!.id].remove(at: idx)
                        }

                        item.removeStorageItem()

                        guard
                            let targetDir = currentTab == .mainDirectory
                                ? privateDirectoryStack.stack.first : directoryStack.stack.first
                        else { return }

                        targetDir.items.append(item)
                        item.parentDirectory = targetDir

                        let i = info[targetDir.id].count
                        let z = Double((info[targetDir.id].map { $0.frame.z }.max() ?? 0) + 1)
                        let ro = makeItemRenderInfo(itemID, i, z, targetDir.sortBy)

                        info[targetDir.id].append(ro)

                        if currentTab == .mainDirectory {
                            memoDirectoryCoredataReposotory.hideItem(item: item, infos: info)
                        } else {
                            memoDirectoryCoredataReposotory.unhideItem(item: item, infos: info)
                        }

                        output.send(.didHidingItem(index))
                    }

                case .willMoveTab(let tab):
                    currentTab = tab
                    selectedItem = []
                    output.send(.didCancelAllSelection)

                    switch tab {
                        case .mainDirectory:
                            directoryStack.stack = Array(directoryStack.stack.prefix(1))
                            output.send(.didMoveTab(directoryStack.stack.first!))
                            if !signatureManager.isRegisteredSignature { signatureManager.clearSignature() }
                            updateCurrentRootDirectoryInfo()

                        case .privateDirectory:
                            if signatureManager.isRegisteredSignature {
                                output.send(
                                    .didPresentReleaseLockView(
                                        signatureManager.benchmarkVisibility ? signatureManager.centerPoints : [],
                                        signatureManager.drawingDisplayOption))
                            } else {
                                output.send(.didPresentSignatureRegisterView)
                            }
                            privateDirectoryStack.stack = Array(privateDirectoryStack.stack.prefix(1))
                            if isUnlockedPrivateDirectory {
                                updateCurrentRootDirectoryInfo()
                                output.send(.didMoveTab(privateDirectoryStack.stack.first!))
                            }

                        case .setting:
                            output.send(
                                .didLoadSettings(
                                    signatureManager.coordinateSimilarityPassScore,
                                    signatureManager.patternSimilarityPassScore,
                                    signatureManager.benchmarkVisibility,
                                    signatureManager.drawingDisplayOption,
                                    signatureManager.isUnlocked,
                                    contentsConfigurationManager.isEnableTextMemoSummarization
                                )
                            )
                    }

                case .willTryToUnlockPrivateDirectoryAccess(let signature):
                    isUnlockedPrivateDirectory = signatureManager.verifySignature(sign: signature)
                    if isUnlockedPrivateDirectory {
                        updateCurrentRootDirectoryInfo()
                        output.send(.didMoveTab(privateDirectoryStack.stack.first!))
                    }
                    output.send(.didTryToUnlockPrivateDirectory(isUnlockedPrivateDirectory))

                case .willRegisterSignature(let signature):
                    let centerPoint = signatureManager.registerSignature(sign: signature)
                    output.send(.didRegisterSignature(centerPoint))

                case .willRemoveSignatureHistory(let index):
                    signatureManager.removeSignature(index: index)

                case .willSuccessRegisterSignature:
                    signatureManager.completeRegister()
                    output.send(.didSuccessRegisterSignature)

                case .willAdjustSignaturePassScore(let cs, let ps):
                    signatureManager.setCoordinateSimilarityPassScore(cs)
                    signatureManager.setPatternSimilarityPassScore(ps)

                case .willSetBenchmarkVisibility(let visibility):
                    signatureManager.setBenchMarkVisibility(visibility)

                case .willSetSignatureDrawingDisplay(let opt):
                    signatureManager.setDrawingDisplayOption(opt)

                case .willResetSignature:
                    signatureManager.clearSignature()

                case .willSetTextMemoSermmerizationEnable:
                    contentsConfigurationManager.isEnableTextMemoSummarization.toggle()
            }
        }
        .store(in: &subscriptions)
        return output.eraseToAnyPublisher()
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
                receiveValue: { [self] (systemDirectories, itemRenderInfoData) in
                    let mainDirectory = systemDirectories[.mainDirectory]!
                    let privateDirectory = systemDirectories[.privateDirectory]!

                    directoryStack.stack = [mainDirectory]
                    privateDirectoryStack.stack = [privateDirectory]
                    currentTab = .mainDirectory

                    updateCurrentRootDirectoryInfo()

                    info = itemRenderInfoData
                    output.send(.didFetchMemoData(directoryStack, privateDirectoryStack, info))
                }
            )
            .store(in: &subscriptions)
    }

    private func syncFileItemAsLocationInfo() {
        var q: [MemoDirectoryModel] = [directoryStack.stack.first!, privateDirectoryStack.stack.first!]

        while !q.isEmpty {
            let dir = q.popLast()!
            for (i, item) in dir.items.enumerated() {
                if let subDir = item as? MemoDirectoryModel { q.append(subDir) }
                if !info[dir.id].map({ $0.id }).contains(item.id) {
                    let z = Double((info[dir.id].map { $0.frame.z }.max() ?? 0) + 1)
                    let ro = makeItemRenderInfo(item.id, i, z, dir.sortBy)
                    info[dir.id].append(ro)
                }
            }
        }
    }

    private func createdNewDirectory(_ newDirectoryName: String) {
        let newDirectory = directoryCreator.createFile(
            itemName: newDirectoryName,
            parentDirectory: currentDirectory)

        let i = info[currentDirectory.id].count
        let z = Double((info[currentDirectory.id].map { $0.frame.z }.max() ?? 0) + 1)
        let ro = makeItemRenderInfo(newDirectory.id, i, z, currentDirectory.sortBy)

        info[currentDirectory.id].append(ro)
        info[newDirectory.id] = []

        if let insertedIndex = currentDirectory.items.firstIndex(where: { $0.id == newDirectory.id }) {
            memoDirectoryCoredataReposotory.createStorageItem(storageItem: newDirectory, infos: info)
            output.send(
                .didInsertRowToHomeTable(
                    currentTab == .mainDirectory
                        ? directoryStack.stack.count - 1 : privateDirectoryStack.stack.count - 1, [insertedIndex]))
        }
    }

    private func createdNewPage(_ newPageName: String, _ singleComponentType: ComponentType? = nil) {
        pageCreator.setFirstComponentType(type: singleComponentType ?? .text)

        let newPage =
            singleComponentType != nil
            ? pageCreator.createFile(
                itemName: newPageName,
                parentDirectory: currentDirectory,
                singleComponentType: singleComponentType!)
            : pageCreator.createFile(itemName: newPageName, parentDirectory: currentDirectory)

        let i = info[currentDirectory.id].count
        let z = Double((info[currentDirectory.id].map { $0.frame.z }.max() ?? 0) + 1)
        let ro = makeItemRenderInfo(newPage.id, i, z, currentDirectory.sortBy)

        info[currentDirectory.id].append(ro)

        if let insertedIndex = currentDirectory[newPage.id]?.index {
            memoDirectoryCoredataReposotory.createStorageItem(storageItem: newPage, infos: info)
            output.send(
                .didInsertRowToHomeTable(
                    currentTab == .mainDirectory
                        ? directoryStack.stack.count - 1 : privateDirectoryStack.stack.count - 1, [insertedIndex]))
        }
    }

    private func moveToFollowingDirectory(index: Int) {
        let followingDirectory = currentDirectory.items[index] as! MemoDirectoryModel

        if currentTab == .mainDirectory {
            directoryStack.stack.append(followingDirectory)
        } else {
            privateDirectoryStack.stack.append(followingDirectory)
        }

        output.send(
            .didMoveToFollowingDirectory(
                followingDirectory.name,
                followingDirectory.id,
                followingDirectory.sortBy,
            )
        )
    }

    private func moveToPreviousDirectory(_ destinationDirectoryID: UUID) {
        let stack = currentTab == .mainDirectory ? directoryStack : privateDirectoryStack
        let destinationDirectoryIndex = stack.stack.firstIndex(where: { $0.id == destinationDirectoryID })!
        guard destinationDirectoryIndex < stack.stack.count - 1 else { return }

        let directoryStackLastIndex = stack.stack.count - 1
        stack.stack.removeLast(directoryStackLastIndex - destinationDirectoryIndex)

        output.send(
            .didMovePreviousDirectoryPath(
                Array(((destinationDirectoryIndex + 1)...directoryStackLastIndex)),
                stack.stack.last!.sortBy
            )
        )
    }

    private func moveToPage(followingPageIndex: Int) {
        let followingPage = currentDirectory.items[followingPageIndex] as! MemoPageModel

        if followingPage.isSingleComponentPage {
            let pageName = followingPage.name
            if let textEditorComponent = followingPage.components.first as? TextEditorComponent {
                DIContainer.shared.setArgument(TextEditorComponentViewModel.self, textEditorComponent)
                let viewModel = DIContainer.shared.resolve(TextEditorComponentViewModel.self)
                output.send(.didNavigateSingleTextEditorComponentPageView(viewModel, textEditorComponent, pageName))
            } else if let tableComponent = followingPage.components.first as? TableComponent {
                DIContainer.shared.setArgument(TableComponentViewModel.self, tableComponent)
                let viewModel = DIContainer.shared.resolve(TableComponentViewModel.self)
                output.send(.didNavigateSingleTableComponentPageView(viewModel, tableComponent, pageName))
            } else if let audioComponent = followingPage.components.first as? AudioComponent {
                DIContainer.shared.setArgument(AudioComponentViewModel.self, audioComponent)
                let viewModel = DIContainer.shared.resolve(AudioComponentViewModel.self)
                output.send(.didNavigateSingleAudioComponentPageView(viewModel, audioComponent, pageName))
            }
        } else {
            DIContainer.shared.setArgument(MemoPageViewModel.self, followingPage)
            let memoPageViewModel = DIContainer.shared.resolve(MemoPageViewModel.self)
            output.send(.didNavigatePageView(memoPageViewModel))
        }
    }

    private func getSizeDirectory(directory: MemoDirectoryModel) -> Int64 {
        var q: [MemoDirectoryModel] = [directory]
        var size: Int64 = directory.getItemSize()

        while !q.isEmpty {
            let dir = q.popLast()!
            for item in dir.items {
                if let subDir = item as? MemoDirectoryModel {
                    q.append(subDir)
                    continue
                } else if let page = item as? MemoPageModel {
                    size += getAudioComponentSize(page: page)
                }
            }
        }
        return size
    }

    private func updateCurrentRootDirectoryInfo() {
        Task.detached { [self] in
            let size = await getSizeDirectory(directory: currentRootDirectory)
            let info = await currentRootDirectory.getFileInformation() as! DirectoryInformation
            DispatchQueue.main.async {
                self.output.send(
                    .didUpdateCurrentRootDirectoryInfo(size, info.containedDirectoryCount, info.containedPageCount))
            }
        }
    }

    private func getAudioComponentSize(page: MemoPageModel) -> Int64 {
        page.components.compactMap { $0 as? AudioComponent }
            .map {
                $0.componentContents.tracks
                    .map { audioFileManager.makeAudioTrackAppSandBoxURL(audioTrack: $0) }
                    .map { audioFileManager.readAudioFileSize(audioURL: $0) }
                    .reduce(0, +)
            }
            .reduce(0, +)
    }

    private func getFileItemSize(itemID: UUID) -> (Int, Int64)? {
        if let itemIndex = currentDirectory.items.firstIndex(where: { $0.id == itemID }) {
            if let page = currentDirectory.items[itemIndex] as? MemoPageModel {
                let size: Int64 = page.getItemSize() + getAudioComponentSize(page: page)
                return (itemIndex, size)
            } else if let directory = currentDirectory.items[itemIndex] as? MemoDirectoryModel {
                return (itemIndex, getSizeDirectory(directory: directory))
            }
        }
        return nil
    }

    private func getAudioTotalDuration(itemID: UUID) -> Double {
        if let itemIndex = currentDirectory.items.firstIndex(where: { $0.id == itemID }) {
            if let page = currentDirectory.items[itemIndex] as? MemoPageModel {
                if let ac = page.components.first as? AudioComponent {
                    return ac.componentContents.tracks
                        .map { audioFileManager.makeAudioTrackAppSandBoxURL(audioTrack: $0) }
                        .compactMap { audioFileManager.readAudioMetadata(audioURL: $0).duration }
                        .reduce(0, +)
                }
            }
        }
        return 0
    }

    private func getFileItemInfo(itemID: UUID) {
        Task.detached {
            if let (index, size) = await self.getFileItemSize(itemID: itemID) {
                await MainActor.run {
                    self.output.send(.didCalcFileItemSize(index, size))
                }
            }
        }

        if let itemIndex = currentDirectory.items.firstIndex(where: { $0.id == itemID }) {
            if let page = currentDirectory.items[itemIndex] as? MemoPageModel {
                if page.isSingleComponentPage == true {
                    if let ac = page.components.first as? AudioComponent {
                        let totalAudioCount = ac.componentContents.tracks.count
                        output.send(
                            .didPresentSingleAudioPageInfoView(
                                itemIndex, totalAudioCount, getAudioTotalDuration(itemID: page.id)
                            )
                        )
                    } else if let tec = page.components.first as? TextEditorComponent {
                        if #available(iOS 26.0, *) {
                            if contentsConfigurationManager.isEnableTextMemoSummarization {
                                let m = TextMemoContentsSummaryGeneratingModel()
                                Task.detached {
                                    let summary = await m.summation(input: tec.componentContents)
                                    await MainActor.run {
                                        self.output.send(.didGenertingTextComponentSummary(itemIndex, summary))
                                    }
                                }
                            } else {
                                self.output.send(.didGenertingTextComponentSummary(itemIndex, "disabled summerization"))
                            }
                        }
                        if let mrsd = tec.snapshots.sorted(by: { $0.makingDate > $1.makingDate }).first?.makingDate {
                            output.send(.didGetMostRecentSnapshotDate(itemIndex, mrsd.formattedDate))
                        }
                    } else if let tc = page.components.first as? TableComponent {
                        output.send(
                            .didPresentTableInfo(
                                itemIndex,
                                tc.componentContents.columns.map { $0.title },
                                tc.componentContents.cellValues.count
                            )
                        )
                        if let mrsd = tc.snapshots.sorted(by: { $0.makingDate > $1.makingDate }).first?.makingDate {
                            output.send(.didGetMostRecentSnapshotDate(itemIndex, mrsd.formattedDate))
                        }
                    }
                } else {
                    let info = page.getFileInformation() as! PageInformation
                    output.send(.didPresentPageInfoView(itemIndex, info.pageComponentCounts))
                }
            } else if let directory = currentDirectory.items[itemIndex] as? MemoDirectoryModel {
                let info = directory.getFileInformation() as! DirectoryInformation
                output.send(
                    .didPresentDirectoryInfoView(
                        itemIndex, info.containedDirectoryCount, info.containedPageCount
                    )
                )
            }
        }
    }

    private func manualOrder(_ id: UUID, _ frame: CGRect) {
        if let ii = info[currentDirectory.id].firstIndex(where: { $0.id == id }) {
            currentDirectory.sortBy = .manual

            for (i, v) in info[currentDirectory.id].enumerated() {
                if v.frame == .origin {
                    if let index = currentDirectory.items.firstIndex(where: { $0.id == v.id }) {
                        let size = UIConstants.ItemSize.small.size
                        let xOffset = size.width * CGFloat(index % 4) + spacing * Double(index % 4 + 1)
                        let yOffset = size.height * CGFloat(index / 4) + spacing * Double(index / 4 + 1)
                        let r = CodableCGRect(
                            x: xOffset, y: yOffset, z: Double(index),
                            w: UIConstants.ItemSize.small.size.width,
                            h: UIConstants.ItemSize.small.size.height)
                        info[currentDirectory.id][i].frame = .manual(r)
                    }
                }
            }

            info[currentDirectory.id][ii].frame = .manual(
                CodableCGRect(
                    x: frame.minX, y: frame.minY, z: info[currentDirectory.id].map { $0.frame.z }.max()! + 1,
                    w: frame.width, h: frame.height)
            )

            memoDirectoryCoredataReposotory.moveItemOrder(directoryID: currentDirectory.id, infos: info)
            output.send(.didSortManualOrder)
        }
    }

    private func gridSortItems() {
        guard let cd = currentDirectory, cd.sortBy == .manual else { return }

        func checkIsEmptyDP(baseX: Int, baseY: Int, c: Int, r: Int) -> Bool {
            guard 12 > baseX + r - 1 else { return false }
            for y in baseY..<baseY + c {
                for x in baseX..<baseX + r {
                    if dp[y][x] != -1 { return false }
                }
            }
            return true
        }

        func markDP(baseX: Int, baseY: Int, c: Int, r: Int, markNum: Int) {
            for y in baseY..<baseY + c {
                for x in baseX..<baseX + r {
                    dp[y][x] = markNum
                }
            }
        }

        var currentInfos = info[cd.id]
        var dp = Array(repeating: Array(repeating: -1, count: 12), count: currentInfos.count * 6)
        var dp2: [(UUID, Double, Double, Double)] = []
        var dp3: [(Int, Int, Int, Int)] = []

        for i in 0..<currentInfos.count {
            if case .manual(let frame) = currentInfos[i].frame {
                let x = frame.x
                let nearX = Double(Int(x / 30)) * 30
                let nearX2 = Double(Int(x / 30 + 1)) * 30
                let expectedX = abs(x - nearX) > abs(x - nearX2) ? nearX2 : nearX

                let y = frame.y
                let nearY = Double(Int(y / 30)) * 30
                let nearY2 = Double(Int(y / 30) + 1) * 30
                let expectedY = abs(y - nearY) > abs(y - nearY2) ? nearY2 : nearY

                let distance = abs(expectedX - x) + abs(expectedY - y)
                dp2.append((currentInfos[i].id, expectedX, expectedY, distance))
            }
        }

        dp2.sort { $0.2 != $1.2 ? $0.2 < $1.2 : $0.1 != $1.1 ? $0.1 < $1.1 : $0.3 < $1.3 }

        currentInfos.sort { l, r in
            dp2.firstIndex(where: { $0.0 == l.id })! < dp2.firstIndex(where: { $0.0 == r.id })!
        }

        for i in 0..<currentInfos.count {
            if case .manual(let frame) = currentInfos[i].frame {
                let sizes: [UIConstants.ItemSize] = [.small, .medium, .large, .bar]
                let difs = sizes.map { abs($0.size.width - frame.w) + abs($0.size.height - frame.h) }
                let closestSize = sizes[difs.indices.min(by: { difs[$0] < difs[$1] })!]

                loop: for ii in 0..<dp.count {
                    for iii in 0..<dp[ii].count {
                        if closestSize == .small, checkIsEmptyDP(baseX: iii, baseY: ii, c: 3, r: 3) {
                            markDP(baseX: iii, baseY: ii, c: 3, r: 3, markNum: i)
                            dp3.append((ii, iii, 3, 3))
                        } else if closestSize == .medium, checkIsEmptyDP(baseX: iii, baseY: ii, c: 4, r: 4) {
                            markDP(baseX: iii, baseY: ii, c: 4, r: 4, markNum: i)
                            dp3.append((ii, iii, 4, 4))
                        } else if closestSize == .bar, checkIsEmptyDP(baseX: iii, baseY: ii, c: 3, r: 5) {
                            markDP(baseX: iii, baseY: ii, c: 3, r: 5, markNum: i)
                            dp3.append((ii, iii, 5, 3))
                        } else if closestSize == .large, checkIsEmptyDP(baseX: iii, baseY: ii, c: 5, r: 5) {
                            markDP(baseX: iii, baseY: ii, c: 5, r: 5, markNum: i)
                            dp3.append((ii, iii, 5, 5))
                        } else {
                            continue
                        }
                        break loop
                    }
                }
            }
        }

        for i in 0..<dp.count {
            if dp[i].allSatisfy({ $0 == -1 }) { break }
            for ii in 0..<dp[i].count {
                if dp[i][ii] == -1 { dp[i][ii] = -2 }
            }
        }

        for i in 0..<currentInfos.count {
            let (c, r, w, h) = dp3[i]
            var xOffset: Double = 0
            var yOffset: Double = 0

            if let mx = dp[c..<c + h].map({ $0[0..<r].filter { $0 != -1 }.count }).max() {
                xOffset = Double(mx * 30)
            }
            if let msx = dp[0..<c + h].map({ Set($0[0...r].filter { $0 != -1 && $0 != -2 }).count }).max() {
                xOffset += Double(msx) * spacing
            }

            var mys = 0
            var my = 0
            for ii in r..<r + w {
                var temp = 0
                var temps: [Int] = []
                for iii in 0..<c {
                    if dp[iii][ii] != -1 {
                        temp += 1
                    }
                    if dp[iii][ii] != -1 && dp[iii][ii] != -2 {
                        temps.append(dp[iii][ii])
                    }
                }

                my = max(my, temp)
                mys = max(mys, Set(temps).count + 1)
            }

            yOffset = Double(my * 30)
            yOffset += Double(mys) * spacing

            let rect = CodableCGRect(x: xOffset, y: yOffset, z: 1, w: Double(w * 30), h: Double(h * 30))
            currentInfos[i].frame = .manual(rect)
        }

        info[cd.id] = currentInfos
        memoDirectoryCoredataReposotory.moveItemOrder(directoryID: cd.id, infos: info)
        output.send(.didManualAutoGrid)
    }

    private func moveSelectedItems() {
        guard let movingTargetDir = currentDirectory else { return }

        let movingTargetItems = selectedItem.filter { !movingTargetDir.items.map { $0.id }.contains($0.id) }

        for item in movingTargetItems {
            if let idx = info[item.parentDirectory!.id].firstIndex(where: { $0.id == item.id }) {
                info[item.parentDirectory!.id].remove(at: idx)
                let i = info[movingTargetDir.id].count
                let z = Double((info[movingTargetDir.id].map { $0.frame.z }.max() ?? 0) + 1)
                let ro = makeItemRenderInfo(item.id, i, z, movingTargetDir.sortBy)
                info[movingTargetDir.id].append(ro)
            }

            item.moveToAnyDirectory(direcotry: movingTargetDir)

            memoDirectoryCoredataReposotory
                .moveItemLocation(targetDir: movingTargetDir, item: item, infos: info)
        }

        let insertIndices =
            movingTargetItems
            .map { item in movingTargetDir.items.firstIndex(where: { $0.id == item.id })! }

        selectedItem = []
        output.send(.didMoveSelectedItems(insertIndices))
    }

    private func moveFileToDormantBox(itemID: UUID) {
        if let itemIndex = currentDirectory.items.firstIndex(where: { $0.id == itemID }) {
            let item = currentDirectory.items[itemIndex]
            item.removeStorageItem()
            memoDirectoryCoredataReposotory.moveFileToDormantBox(fileID: item.id)
            if let idx = info[currentDirectory.id].firstIndex(where: { $0.id == item.id }) {
                var newInfo = info[currentDirectory.id]
                newInfo.remove(at: idx)
                info[currentDirectory.id] = newInfo
            }
            output.send(.didMoveFileToDormantBox(itemIndex))
        }
    }

    private func getDormantBoxViewModel() {
        restoredPageListSubjectSubscription =
            restoredPageListSubject
            .sink { [weak self] restoredPageList in
                guard let self else { return }

                for page in restoredPageList {
                    page.parentDirectory = directoryStack.stack.first!
                    page.parentDirectory?.items.append(page)

                    let i = info[directoryStack.stack.first!.id].count
                    let z = Double((info[directoryStack.stack.first!.id].map { $0.frame.z }.max() ?? 0) + 1)
                    let ro = makeItemRenderInfo(page.id, i, z, directoryStack.stack.last!.sortBy)

                    info[directoryStack.stack.last!.id].append(ro)
                }

                let insertedIndices = restoredPageList.map { restoredPage in
                    self.directoryStack.stack.first!.items.firstIndex(where: { $0.id == restoredPage.id })!
                }

                output.send(.didInsertRowToHomeTable(.zero, insertedIndices))
            }

        DIContainer.shared.setArgument(DormantBoxViewModel.self, restoredPageListSubject)
        let dormantBoxViewModel = DIContainer.shared.resolve(DormantBoxViewModel.self)

        output.send(.didNavigateDormantBoxView(dormantBoxViewModel))
    }

    private func changeFileName(fileID: UUID, newName: String) {
        if let index = currentDirectory.items.firstIndex(where: { $0.id == fileID }) {
            currentDirectory.items[index].name = newName
            memoDirectoryCoredataReposotory.saveFileNameChange(fileID: fileID, newName: newName)
        }
    }

    private func changeFileItemColor(_ id: UUID, _ color: FileItemColor) {
        if let index = currentDirectory.items.firstIndex(where: { $0.id == id }) {
            currentDirectory.items[index].itemColor = color
            memoDirectoryCoredataReposotory.saveFileItemColor(fileID: id, color: color)
        }
    }

    private func changeSortCriteria(sortBy: DirectoryContentsSortCriterias) {
        let before = currentDirectory.items.map { $0.id }

        currentDirectory.sortBy = sortBy
        currentDirectory.sortItems()

        var sortedInfos: [ItemRenderInfo] = []

        for item in currentDirectory.items {
            if var first = info[currentDirectory.id].first(where: { $0.id == item.id }) {
                first.frame = .origin
                sortedInfos.append(first)
            }
        }

        info[currentDirectory.id] = sortedInfos

        let aftre = currentDirectory.items.map { $0.id }
        let sortingResult = before.map { aftre.firstIndex(of: $0)! }.map { Int($0) }

        memoDirectoryCoredataReposotory.saveFileSortCriteria(
            fileID: currentDirectory.id,
            newSortCriteria: sortBy,
            infos: info)

        output.send(.didSortDirectoryItems(sortingResult))
    }

    private func makeItemRenderInfo(
        _ id: UUID, _ i: Int, _ z: Double, _ sortBy: DirectoryContentsSortCriterias
    ) -> ItemRenderInfo {
        let xOffset = Double((UIConstants.ItemSize.small.size.width + spacing) * Double(i % 4))
        let yOffset = Double((UIConstants.ItemSize.small.size.width + spacing) * Double(i / 4))
        let r = CodableCGRect(
            x: xOffset, y: yOffset, z: z,
            w: UIConstants.ItemSize.small.size.width, h: UIConstants.ItemSize.small.size.height)

        return ItemRenderInfo(id: id, frame: sortBy == .manual ? .manual(r) : .origin)
    }
}

final class DirectoryStack: AnyObject {
    var stack: [MemoDirectoryModel] = []
}

final class DirectoryContentsRenderInfo: AnyObject, Codable {
    private var info: [UUID: [ItemRenderInfo]] = [:]

    init(info: [UUID: [ItemRenderInfo]] = [:]) {
        self.info = info
    }

    subscript(_ id: UUID) -> [ItemRenderInfo] {
        get { info[id, default: []] }
        set(newValue) { info[id] = newValue }
    }
}

enum CurrentTap {
    case mainDirectory
    case privateDirectory
    case setting
}

enum MemoHomeViewInput {
    case viewDidLoad
    case willUpdateCurrentRootDirectoryInfo
    case willMovePreviousDirectoryPath(UUID)
    case willNavigateDormantBoxView
    case willChangeFileName(UUID, String)
    case willSortDirectoryItems(DirectoryContentsSortCriterias)
    case willCreatedNewDirectory(String)
    case willCreatedNewPage(String, ComponentType?)
    case willMoveToFollowingDirectory(Int)
    case willNavigatePageView(Int)
    case willMoveFileToDormantBox(UUID)
    case willSortManualOrder(UUID, CGRect)
    case willManualAutoGrid
    case willChangeFileItemColor(UUID, FileItemColor)
    case willPresentFileItemInfoView(UUID)
    case willSelectFileItem(UUID)
    case willMoveSelectedItems
    case willRemoveFromSelectedItems(UUID)
    case willCancelAllSelection
    case willHidingItem(UUID)
    case willMoveTab(CurrentTap)
    case willTryToUnlockPrivateDirectoryAccess([[Double]])
    case willRegisterSignature([[Double]])
    case willRemoveSignatureHistory(Int)
    case willSuccessRegisterSignature
    case willAdjustSignaturePassScore(Double, Double)
    case willSetBenchmarkVisibility(Bool)
    case willSetSignatureDrawingDisplay(DrawingDisplayOption)
    case willResetSignature
    case willSetTextMemoSermmerizationEnable
}

enum MemoHomeViewOutput {
    case didFetchMemoData(DirectoryStack, DirectoryStack, DirectoryContentsRenderInfo)
    case didUpdateCurrentRootDirectoryInfo(Int64, Int, Int)
    case didInsertRowToHomeTable(Int, [Int])
    case didMovePreviousDirectoryPath([Int], DirectoryContentsSortCriterias)
    case didMoveToFollowingDirectory(String, UUID, DirectoryContentsSortCriterias)
    case didMoveFileToDormantBox(Int)
    case didNavigateDormantBoxView(DormantBoxViewModel)
    case didNavigatePageView(MemoPageViewModel)
    case didNavigateSingleTextEditorComponentPageView(TextEditorComponentViewModel, TextEditorComponent, String)
    case didNavigateSingleTableComponentPageView(TableComponentViewModel, TableComponent, String)
    case didNavigateSingleAudioComponentPageView(AudioComponentViewModel, AudioComponent, String)
    case didSortDirectoryItems([Int])
    case didSortManualOrder
    case didManualAutoGrid
    case didPresentSingleAudioPageInfoView(Int, Int, Double)
    case didPresentDirectoryInfoView(Int, Int, Int)
    case didPresentPageInfoView(Int, [ComponentType: Int])
    case didCalcFileItemSize(Int, Int64)
    case didGenertingTextComponentSummary(Int, String)
    case didGetMostRecentSnapshotDate(Int, String)
    case didPresentTableInfo(Int, [String], Int)
    case didSelectFileItem(String, UUID)
    case didMoveSelectedItems([Int])
    case didRemoveFromSelectedItems(Int, Int?, UUID)
    case didCancelAllSelection
    case didHidingItem(Int)
    case didPresentSignatureRegisterView
    case didPresentReleaseLockView([[Double]], DrawingDisplayOption)
    case didTryToUnlockPrivateDirectory(Bool)
    case didRegisterSignature([Double])
    case didSuccessRegisterSignature
    case didMoveTab(MemoDirectoryModel)
    case didLoadSettings(Double, Double, Bool, DrawingDisplayOption, Bool, Bool)
}

protocol MessageErrorType: Error {
    var errorMessage: String { get }
}

enum MemoHomeViewModelError: MessageErrorType {
    case canNotLoadMemoData

    var errorMessage: String {
        switch self {
            case .canNotLoadMemoData:
                "An error occurred while loading the memo data."
        }
    }
}
