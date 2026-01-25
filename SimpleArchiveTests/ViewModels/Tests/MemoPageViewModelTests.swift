import Combine
import XCTest

@testable import SimpleArchive

@MainActor
final class MemoPageViewModelTests: XCTestCase, @preconcurrency FixtureProvidingTestCase {
    var sut: MemoPageViewModel!
    var input: PassthroughSubject<MemoPageViewModel.Input, Never>!
    var subscriptions: Set<AnyCancellable>!
    var mockMemoComponentCoredataReposotory: MockMemoComponentCoreDataRepository!
    var mockComponentFactory: MockComponentFactory!
    var mockAudioDownloader: MockAudioDownloader!
    var mockAudioFileManager: MockAudioFileManager!
    var mockAudioTrackController: MockAudioTrackController!
    var fixtureProvider = MemoPageViewModelTestFixtureProvider()

    override func setUpWithError() throws {
        mockMemoComponentCoredataReposotory = MockMemoComponentCoreDataRepository()
        mockComponentFactory = MockComponentFactory()
        mockAudioDownloader = MockAudioDownloader()
        mockAudioFileManager = MockAudioFileManager()
        mockAudioTrackController = MockAudioTrackController()
        input = PassthroughSubject<MemoPageViewModel.Input, Never>()
        subscriptions = []
    }

    override func tearDownWithError() throws {
        fixtureProvider.removeUsedFixtureData()
        mockMemoComponentCoredataReposotory = nil
        mockComponentFactory = nil
        mockAudioFileManager = nil
        mockAudioTrackController = nil
        subscriptions = nil
        mockAudioDownloader = nil
        input = nil
        sut = nil
    }

    func test_createNewComponent_successfully() throws {
        typealias FixtureType = CreateNewComponentSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let (page, createdNewComponent) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: page)

        mockComponentFactory.actions = .init(expected: [.setCreator, .createComponent])
        mockMemoComponentCoredataReposotory.actions = .init(expected: [.createComponentEntity])
        mockComponentFactory.createComponentResult = createdNewComponent

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let testTargetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willCreateNewComponent(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let factual = try factualOutput.getOutput()
        let expectedComponentCount = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        guard case let .didAppendComponentAt(factualComponentCount) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentCount, factualComponentCount)

        mockComponentFactory.verify()
        mockMemoComponentCoredataReposotory.verify()
    }

    func test_captureComponent_successfully() throws {
        typealias FixtureType = CaptureComponentSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()
        let page = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: page)

        mockMemoComponentCoredataReposotory.actions = .init(expected: [.captureManualSnapshot])

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (id, desc) = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willCaptureComponent(id, desc))
        wait(for: [expectation], timeout: 1)

        let factual = try factualOutput.getOutput()
        let expectedIndex = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        guard case .didCompleteComponentCapture(let factualIndex) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedIndex, factualIndex)
        mockMemoComponentCoredataReposotory.verify()
    }

    func test_removeComponent_successfullly() throws {
        typealias FixtureType = RemoveComponentSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let page = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: page)

        mockMemoComponentCoredataReposotory.actions = .init(expected: [.removeComponent])

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let id = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willRemoveComponent(id))
        wait(for: [expectation], timeout: 1)

        let factual = try factualOutput.getOutput()
        let expectedIndex = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        guard case .didRemoveComponentAt(let factualIndex) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedIndex, factualIndex)
        mockMemoComponentCoredataReposotory.verify()
    }

    func test_downloadAudioTracks_successfullly() throws {
        typealias FixtureType = DownloadAudioTracksSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let (page, audioComponentID, audioComponentDatasource) =
            fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: page)

        sut.setAudioTrackDataSource(id: audioComponentID, datasource: audioComponentDatasource)

        mockAudioDownloader.actions = .init(expected: [.downloadAudioTask])
        mockAudioFileManager.actions = .init(
            expected: [.extractAudioFileURLs]
                + mockAudioFileManager.repeatingActions(
                    actions: [
                        .readAudioMetadata,
                        .moveItem,
                        .writeAudioMetadata,
                    ], count: 3)
        )
        mockMemoComponentCoredataReposotory.actions = .init(expected: [.updateComponentContentChanges])

        let downloadTaskResultURL = URL(fileURLWithPath: "Documents/downloaded_music_temp.zip")
        mockAudioDownloader.downloadTaskResult = .success(downloadTaskResultURL)

        mockAudioFileManager.extractAudioFileURLsResult = [
            URL(fileURLWithPath: "Documents/downloaded_music_temp/c audio.mp3"),
            URL(fileURLWithPath: "Documents/downloaded_music_temp/f audio.mp3"),
            URL(fileURLWithPath: "Documents/downloaded_music_temp/g audio.mp3"),
        ]
        mockAudioFileManager.readAudioMetadataResult = [
            AudioTrackMetadata(title: "c audio", artist: "artist", thumbnail: Data()),
            AudioTrackMetadata(title: "f audio", artist: "artist", thumbnail: Data()),
            AudioTrackMetadata(title: "g audio", artist: "artist", thumbnail: Data()),
        ]

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, downloadCode) = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willDownloadMusicWithCode(componentId, downloadCode))
        wait(for: [expectation], timeout: 1)

        let factual = try factualOutput.getOutput()
        let (
            expectedComponentIndex,
            expectedAppededIndices
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        guard case let .didAppendAudioTrackRows(factualComponentIndex, factualAppendedIndicies) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)
        XCTAssertEqual(expectedAppededIndices, factualAppendedIndicies)

        mockAudioDownloader.verify()
        mockAudioFileManager.verify()
        mockMemoComponentCoredataReposotory.verify()
    }

    func test_downloadAudiofileWithCode_failure_WhenInvalidCode() throws {
        typealias FixtureType = DownloadAudiofileWithCodeFailureWhenInvalidCodeTestFixture
        let fixture = fixtureProvider.getFixture()

        let (page, audioComponentID, audioComponentDatasource) =
            fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: page)

        sut.setAudioTrackDataSource(id: audioComponentID, datasource: audioComponentDatasource)

        mockAudioDownloader.actions = .init(expected: [.downloadAudioTask])
        mockAudioDownloader.downloadTaskResult = .failure(AudioDownloadError.invalidCode)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, downloadCode) = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willDownloadMusicWithCode(componentId, downloadCode))
        wait(for: [expectation], timeout: 1)

        let factual = try factualOutput.getOutput()
        let (expectedComponentIndex) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        guard case let .didPresentInvalidDownloadCode(factualComponentIndex) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)

        mockAudioDownloader.verify()
        mockAudioFileManager.verify()
        mockMemoComponentCoredataReposotory.verify()
    }

    func test_importAudioFromLocalFileSystem_successfullly() throws {
        typealias FixtureType = ImportAudioFromLocalFileSystemSuccessfulllyTestFixture
        let fixture = fixtureProvider.getFixture()

        let (page, audioComponentID, audioComponentDatasource) =
            fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: page)

        sut.setAudioTrackDataSource(id: audioComponentID, datasource: audioComponentDatasource)

        mockAudioFileManager.actions = .init(
            expected: mockAudioFileManager.repeatingActions(
                actions: [
                    .copyFilesToAppDirectory,
                    .readAudioMetadata,
                    .writeAudioMetadata,
                ], count: 3)
        )
        mockMemoComponentCoredataReposotory.actions = .init(expected: [.updateComponentContentChanges])

        mockAudioFileManager.copyFilesToAppDirectoryResult = [
            URL(fileURLWithPath: "Documents/SimpleArchiveMusics/c audio.mp3"),
            URL(fileURLWithPath: "Documents/SimpleArchiveMusics/f audio.mp3"),
            URL(fileURLWithPath: "Documents/SimpleArchiveMusics/g audio.mp3"),
        ]
        mockAudioFileManager.readAudioMetadataResult = [
            AudioTrackMetadata(title: "c audio", artist: "artist", thumbnail: Data()),
            AudioTrackMetadata(title: "f audio", artist: "artist", thumbnail: Data()),
            AudioTrackMetadata(title: "g audio", artist: "artist", thumbnail: Data()),
        ]

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, importedURLs) = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willImportAudioFileFromFileSystem(componentId, importedURLs))
        wait(for: [expectation], timeout: 1)

        let (
            expectedComponentIndex,
            expectedAppededIndices
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        let factual = try factualOutput.getOutput()
        guard case let .didAppendAudioTrackRows(factualComponentIndex, factualAppendedIndicies) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)
        XCTAssertEqual(expectedAppededIndices, factualAppendedIndicies)

        mockAudioFileManager.verify()
        mockMemoComponentCoredataReposotory.verify()
    }

    func test_playAudioTrack_successfullly() throws {
        typealias FixtureType = PlayAudioTrackSuccessfulllyTestFixture
        let fixture = fixtureProvider.getFixture()

        let (
            givenPageModel,
            audioComponentID,
            archiveDirectoryAudioPath,
            audioDuration,
            readAudioPCMDataResult,
            audioComponentDataSource
        ) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: givenPageModel)

        sut.setAudioTrackDataSource(id: audioComponentID, datasource: audioComponentDataSource)

        mockAudioFileManager.actions = .init(expected: [.createAudioFileURL, .readAudioPCMData])
        mockAudioFileManager.createAudioFileURLResult = [archiveDirectoryAudioPath]
        mockAudioFileManager.readAudioPCMDataResult = readAudioPCMDataResult

        mockAudioTrackController.actions = .init(expected: [.setAudioURL, .play, .totalTime])
        mockAudioTrackController.totalTimeResult = audioDuration

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, trackIndex) = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willPlayAudioTrack(componentId, trackIndex))
        wait(for: [expectation], timeout: 1)

        let (
            expectedPreviousComponentIndex,
            expectedComponentIndex,
            expectedTrackIndex,
            expectedDuration,
            expectedMetadata,
            expectedNowPlayingURL,
            expectedWaveformDataCount
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        let factual = try factualOutput.getOutput()
        guard
            case let .didPlayAudioTrack(
                factualPreviousComponentIndex,
                factualComponentIndex,
                factualTrackIndex,
                factualDuration,
                factualMetadata,
                factualWaveformData) = factual
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedPreviousComponentIndex, factualPreviousComponentIndex)
        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)
        XCTAssertEqual(expectedTrackIndex, factualTrackIndex)
        XCTAssertEqual(expectedDuration, factualDuration)
        XCTAssertEqual(expectedMetadata, factualMetadata)

        let factualWaveformDataCount = factualWaveformData?.waveformData.reduce(0) { $0 + $1.count }
        XCTAssertEqual(expectedWaveformDataCount, factualWaveformDataCount)
        
        let isScaled = factualWaveformData?.waveformData
            .map { waveformData in
                waveformData.allSatisfy { data in 0.0...1.0 ~= data }
            }
            .allSatisfy { $0 }
        XCTAssertTrue(isScaled!)

        let nowPlayingAudioComponentDataSource = try XCTUnwrap(sut.audioComponentDataSources[audioComponentID])

        XCTAssertEqual(true, nowPlayingAudioComponentDataSource.isPlaying)
        XCTAssertEqual(expectedTrackIndex, nowPlayingAudioComponentDataSource.nowPlayingAudioIndex)
        XCTAssertEqual(expectedNowPlayingURL, nowPlayingAudioComponentDataSource.nowPlayingURL)

        mockAudioFileManager.verify()
        mockAudioTrackController.verify()
    }

    // 이미 재생중인 오디오 컴포넌트가 있을 때 다른 오디오컴포넌트 재생했을 때
    func test_playAudioTrack_successfullly_whenTrackIsAlreadyPlaying() throws {
        typealias FixtureType = PlayAudioTrackSuccessfulllyWhenTrackIsAlreadyPlayingTestFixture
        let fixture = fixtureProvider.getFixture()

        let (
            page,
            previousPlayingComponentID,
            audioDuration,
            previousPlayingComponentDatasource,
            audioComponentID,
            audioComponentDatasource,
            archiveDirectoryAudioPath,
            readAudioPCMDataResult,
        ) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: page)

        sut.setNowPlayingAudioComponentID(previousPlayingComponentID)
        sut.setAudioTrackDataSource(id: previousPlayingComponentID, datasource: previousPlayingComponentDatasource)
        sut.setAudioTrackDataSource(id: audioComponentID, datasource: audioComponentDatasource)

        mockAudioFileManager.actions = .init(expected: [.createAudioFileURL, .readAudioPCMData])
        mockAudioFileManager.createAudioFileURLResult = [archiveDirectoryAudioPath]
        mockAudioFileManager.readAudioPCMDataResult = readAudioPCMDataResult

        mockAudioTrackController.actions = .init(expected: [.setAudioURL, .play, .totalTime])
        mockAudioTrackController.totalTimeResult = audioDuration

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, trackIndex) = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willPlayAudioTrack(componentId, trackIndex))
        wait(for: [expectation], timeout: 1)

        let (
            expectedPreviousComponentIndex,
            expectedComponentIndex,
            expectedTrackIndex,
            expectedDuration,
            expectedMetadata,
            expectedNowPlayingURL,
            expectedNowPlayingAudioComponentID,
            expectedWaveformDataCount
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        let factual = try factualOutput.getOutput()
        guard
            case let .didPlayAudioTrack(
                factualPreviousComponentIndex,
                factualComponentIndex,
                factualTrackIndex,
                factualDuration,
                factualMetadata,
                factualWaveformData) = factual
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedPreviousComponentIndex, factualPreviousComponentIndex)
        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)
        XCTAssertEqual(expectedTrackIndex, factualTrackIndex)
        XCTAssertEqual(expectedDuration, factualDuration)
        XCTAssertEqual(expectedMetadata, factualMetadata)
        
        let factualWaveformDataCount = factualWaveformData?.waveformData.reduce(0) { $0 + $1.count }
        XCTAssertEqual(expectedWaveformDataCount, factualWaveformDataCount)
        
        let isScaled = factualWaveformData?.waveformData
            .map { waveformData in
                waveformData.allSatisfy { data in 0.0...1.0 ~= data }
            }
            .allSatisfy { $0 }
        XCTAssertTrue(isScaled!)

        XCTAssertEqual(expectedNowPlayingAudioComponentID, sut.nowPlayingAudioComponentID)

        let nowPlayingAudioComponentDataSource = try XCTUnwrap(sut.audioComponentDataSources[audioComponentID])

        XCTAssertEqual(true, nowPlayingAudioComponentDataSource.isPlaying)
        XCTAssertEqual(expectedTrackIndex, nowPlayingAudioComponentDataSource.nowPlayingAudioIndex)
        XCTAssertEqual(expectedNowPlayingURL, nowPlayingAudioComponentDataSource.nowPlayingURL)

        let previousAudioComponentDataSource = try XCTUnwrap(sut.audioComponentDataSources[previousPlayingComponentID])

        XCTAssertNil(previousAudioComponentDataSource.isPlaying)
        XCTAssertNil(previousAudioComponentDataSource.nowPlayingURL)
        XCTAssertNil(previousAudioComponentDataSource.audioVisualizerData)
        XCTAssertNil(previousAudioComponentDataSource.nowPlayingAudioIndex)

        mockAudioFileManager.verify()
        mockAudioTrackController.verify()
    }

    // 곡이 여러개 있고 중간에 재생중인 곡삭제했을 때
    func test_removeAudioTrack_whenRemovingCurrentlyPlayingAudio() throws {
        typealias FixtureType = RemoveAudioTrackWhenRemovingCurrentlyPlayingAudioTestFixture
        let fixture = fixtureProvider.getFixture()

        let (
            givenPage,
            nowPlayingComponentID,
            audioComponentDatasource,
            audioFileURL,
            audioPCMData,
            nextPlayAudioDuration,
            isPlayingResult
        ) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: givenPage)

        sut.setNowPlayingAudioComponentID(nowPlayingComponentID)
        sut.setAudioTrackDataSource(id: nowPlayingComponentID, datasource: audioComponentDatasource)

        mockAudioFileManager.actions = .init(expected: [
            .removeAudio, .createAudioFileURL, .readAudioPCMData,
        ])
        mockAudioFileManager.createAudioFileURLResult = [audioFileURL]
        mockAudioFileManager.readAudioPCMDataResult = audioPCMData

        mockAudioTrackController.actions = .init(expected: [.isPlaying, .setAudioURL, .play, .totalTime])
        mockAudioTrackController.isPlayingResult = isPlayingResult
        mockAudioTrackController.totalTimeResult = nextPlayAudioDuration

        mockMemoComponentCoredataReposotory.actions = .init(expected: [.updateComponentContentChanges])

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, trackIndex) = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willRemoveAudioTrack(componentId, trackIndex))
        wait(for: [expectation], timeout: 1)

        let (
            expectedComponentIndex,
            expectedTrackIndex,
            expectedNextPlayingAudioTrackIndex,
            expectedNextPlayAudioDuration,
            expectedNextPlayAudioMetadata,
            expectedNowPlayingURL,
            expectedWaveformDataCount
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        let factual = try factualOutput.getOutput()
        guard
            case let .didRemoveAudioTrackAndPlayNextAudio(
                factualComponentIndex,
                factualTrackIndex,
                factualNextPlayingAudioTrackIndex,
                factualAudioTotalDuration,
                factualAudioMetadata,
                factualWaveformData) = factual
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)
        XCTAssertEqual(expectedTrackIndex, factualTrackIndex)
        XCTAssertEqual(expectedNextPlayingAudioTrackIndex, factualNextPlayingAudioTrackIndex)
        XCTAssertEqual(expectedNextPlayAudioDuration, factualAudioTotalDuration)
        XCTAssertEqual(expectedNextPlayAudioMetadata, factualAudioMetadata)
        
        let factualWaveformDataCount = factualWaveformData?.waveformData.reduce(0) { $0 + $1.count }
        XCTAssertEqual(expectedWaveformDataCount, factualWaveformDataCount)

        let nowPlayingAudioComponentDataSource = try XCTUnwrap(sut.audioComponentDataSources[nowPlayingComponentID])

        XCTAssertEqual(expectedNowPlayingURL, nowPlayingAudioComponentDataSource.nowPlayingURL)
        XCTAssertEqual(expectedNextPlayingAudioTrackIndex, nowPlayingAudioComponentDataSource.nowPlayingAudioIndex)

        mockAudioFileManager.verify()
        mockAudioTrackController.verify()
        mockMemoComponentCoredataReposotory.verify()
    }

    // 곡이 여러개 있고 pause 상태인 곡삭제했을 때
    func test_removeAudioTrack_whenRemovingAudioIsPause() throws {
        typealias FixtureType = RemoveAudioTrackWhenRemovingAudioIsPauseTestFixture
        let fixture = fixtureProvider.getFixture()

        let (
            givenPage,
            nowPlayComponentID,
            audioComponentDatasource
        ) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: givenPage)

        sut.setNowPlayingAudioComponentID(nowPlayComponentID)
        sut.setAudioTrackDataSource(id: nowPlayComponentID, datasource: audioComponentDatasource)

        mockAudioFileManager.actions = .init(expected: [.removeAudio])

        mockAudioTrackController.actions = .init(expected: [.isPlaying, .reset])
        mockAudioTrackController.isPlayingResult = false

        mockMemoComponentCoredataReposotory.actions = .init(expected: [.updateComponentContentChanges])

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, trackIndex) = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willRemoveAudioTrack(componentId, trackIndex))
        wait(for: [expectation], timeout: 1)

        let (
            expectedComponentIndex,
            expectedTrackIndex
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        let factual = try factualOutput.getOutput()
        guard
            case let .didRemoveAudioTrackAndStopPlaying(
                factualComponentIndex,
                factualTrackIndex) = factual
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)
        XCTAssertEqual(expectedTrackIndex, factualTrackIndex)

        let nowPlayingAudioComponentDataSource = try XCTUnwrap(sut.audioComponentDataSources[nowPlayComponentID])

        XCTAssertNil(sut.nowPlayingAudioComponentID)
        XCTAssertNil(nowPlayingAudioComponentDataSource.nowPlayingAudioIndex)
        XCTAssertNil(nowPlayingAudioComponentDataSource.nowPlayingURL)
        XCTAssertNil(nowPlayingAudioComponentDataSource.isPlaying)
        XCTAssertNil(nowPlayingAudioComponentDataSource.audioVisualizerData)
        XCTAssertNil(nowPlayingAudioComponentDataSource.getProgress)

        mockAudioFileManager.verify()
        mockAudioTrackController.verify()
        mockMemoComponentCoredataReposotory.verify()
    }

    // 재생중인 하나뿐인 곡 삭제
    func test_removeAudioTrack_whenLastAudioIsPlaying() throws {
        typealias FixtureType = RemoveAudioTrackWhenLastAudioIsPlayingTestFixture
        let fixture = fixtureProvider.getFixture()

        let (
            givenPage,
            nowPlayingComponentID,
            audioComponentDatasource,
        ) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: givenPage)

        sut.setNowPlayingAudioComponentID(nowPlayingComponentID)
        sut.setAudioTrackDataSource(id: nowPlayingComponentID, datasource: audioComponentDatasource)

        mockAudioFileManager.actions = .init(expected: [.removeAudio])
        mockMemoComponentCoredataReposotory.actions = .init(expected: [.updateComponentContentChanges])
        mockAudioTrackController.actions = .init(expected: [.reset])

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, trackIndex) = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willRemoveAudioTrack(componentId, trackIndex))
        wait(for: [expectation], timeout: 1)

        let (
            expectedComponentIndex,
            expectedTrackIndex
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        let factual = try factualOutput.getOutput()
        guard
            case let .didRemoveAudioTrackAndStopPlaying(
                factualComponentIndex,
                factualTrackIndex) = factual
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)
        XCTAssertEqual(expectedTrackIndex, factualTrackIndex)

        let nowPlayingAudioComponentDataSource = try XCTUnwrap(sut.audioComponentDataSources[nowPlayingComponentID])

        XCTAssertNil(sut.nowPlayingAudioComponentID)
        XCTAssertNil(nowPlayingAudioComponentDataSource.nowPlayingAudioIndex)
        XCTAssertNil(nowPlayingAudioComponentDataSource.nowPlayingURL)
        XCTAssertNil(nowPlayingAudioComponentDataSource.isPlaying)
        XCTAssertNil(nowPlayingAudioComponentDataSource.audioVisualizerData)
        XCTAssertNil(nowPlayingAudioComponentDataSource.getProgress)

        mockAudioFileManager.verify()
        mockMemoComponentCoredataReposotory.verify()
        mockAudioTrackController.verify()
    }
    
    // 정렬 기준이 name이고 현재 재생중인 곡의 이름을 수정했을 때
    func test_ApplyAudioMetadataChanges_whenEditingCurrentlyPlayingTrack() throws {
        typealias FixtureType = ApplyAudioMetadataChangesWhenEditingCurrentlyPlayingTrackTestFixture
        let fixture = fixtureProvider.getFixture()

        let (page, audioComponentID, audioComponentDatasource) =
            fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            audioFileManager: mockAudioFileManager,
            audioTrackController: mockAudioTrackController,
            page: page)

        sut.setNowPlayingAudioComponentID(audioComponentID)
        sut.setAudioTrackDataSource(id: audioComponentID, datasource: audioComponentDatasource)

        mockMemoComponentCoredataReposotory.actions = .init(expected: [.updateComponentContentChanges])

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, metadata, trackIndex) = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willApplyAudioMetadataChanges(metadata, componentId, trackIndex))
        wait(for: [expectation], timeout: 1)

        let (
            expectedComponentIndex,
            expectedTrackIndex,
            expectedMetadata,
            expectedIsEditingCurrentlyPlayingAudio,
            expectedTrackIndexAfterApply,
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        let factual = try factualOutput.getOutput()
        guard
            case let .didApplyAudioMetadataChanges(
                factualComponentIndex,
                factualTrackIndex,
                factualMetadata,
                factualIsEditingCurrentlyPlayingAudio,
                factualTrackIndexAfterApply) = factual
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)
        XCTAssertEqual(expectedTrackIndex, factualTrackIndex)
        XCTAssertEqual(expectedMetadata, factualMetadata)
        XCTAssertEqual(expectedIsEditingCurrentlyPlayingAudio, factualIsEditingCurrentlyPlayingAudio)
        XCTAssertEqual(expectedTrackIndexAfterApply, factualTrackIndexAfterApply)

        mockMemoComponentCoredataReposotory.verify()
    }
}
