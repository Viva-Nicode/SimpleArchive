import Combine
import XCTest

@testable import SimpleArchive

@MainActor
final class MemoPageViewModelTests: XCTestCase, @preconcurrency StubProvidingTestCase {
    var sut: MemoPageViewModel!
    var input: PassthroughSubject<MemoPageViewModel.Input, Never>!
    var subscriptions: Set<AnyCancellable>!
    var mockMemoComponentCoredataReposotory: MockMemoComponentCoreDataRepository!
    var mockComponentFactory: MockComponentFactory!
    var mockAudioDownloader: MockAudioDownloader!
    var stubProvider = MemoPageViewModelTestStubProvider()

    override func setUpWithError() throws {
        mockMemoComponentCoredataReposotory = MockMemoComponentCoreDataRepository()
        mockComponentFactory = MockComponentFactory()
        mockAudioDownloader = MockAudioDownloader()
        input = PassthroughSubject<MemoPageViewModel.Input, Never>()
        subscriptions = []
    }

    override func tearDownWithError() throws {
        stubProvider.removeUsedStubData()
        mockMemoComponentCoredataReposotory = nil
        mockComponentFactory = nil
        subscriptions = nil
        mockAudioDownloader = nil
        input = nil
        sut = nil
    }

    func test_createNewComponent_successfully() throws {
        typealias StubType = CreateNewComponentSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let (stubPage, createdNewComponent) = stub.getStubData() as! StubType.GivenStubDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            page: stubPage)

        mockComponentFactory.actions = .init(expected: [.setCreator, .createComponent])
        mockMemoComponentCoredataReposotory.actions = .init(expected: [.createComponentEntity])
        mockComponentFactory.createComponentResult = createdNewComponent

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let testTargetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willCreateNewComponent(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let factual = try factualOutput.getOutput()
        let expectedComponentCount = stub.getStubData() as! StubType.ExpectedOutputType

        guard case let .didAppendComponentAt(factualComponentCount) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentCount, factualComponentCount)

        mockComponentFactory.verify()
        mockMemoComponentCoredataReposotory.verify()
    }

    func test_captureComponent_successfully() throws {
        typealias StubType = CaptureComponentSuccessfullyTestStub
        let stub = stubProvider.getStub()
        let stubPage = stub.getStubData() as! StubType.GivenStubDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            page: stubPage)

        mockMemoComponentCoredataReposotory.actions = .init(expected: [.captureSnapshot])

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (id, desc) = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willCaptureComponent(id, desc))
        wait(for: [expectation], timeout: 1)

        let factual = try factualOutput.getOutput()
        let expectedIndex = stub.getStubData() as! StubType.ExpectedOutputType

        guard case .didCompleteComponentCapture(let factualIndex) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedIndex, factualIndex)
        mockMemoComponentCoredataReposotory.verify()
    }

    func test_removeComponent_successfullly() throws {
        typealias StubType = RemoveComponentSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let stubPage = stub.getStubData() as! StubType.GivenStubDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            page: stubPage)

        mockMemoComponentCoredataReposotory.actions = .init(expected: [.removeComponent])

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let id = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willRemoveComponent(id))
        wait(for: [expectation], timeout: 1)

        let factual = try factualOutput.getOutput()
        let expectedIndex = stub.getStubData() as! StubType.ExpectedOutputType

        guard case .didRemoveComponentAt(let factualIndex) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedIndex, factualIndex)
        mockMemoComponentCoredataReposotory.verify()
    }

    func test_downloadAudioTracks_successfullly() throws {
        typealias StubType = DownloadAudioTracksSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let (stubPage, audioTracks) = stub.getStubData() as! StubType.GivenStubDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            page: stubPage)

        mockAudioDownloader.actions = .init(expected: [.downloadAudioTask])
        mockAudioDownloader.downloadTaskResult = .success(audioTracks)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, downloadCode) = stub.getStubData() as! StubType.TestTargetInputType

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
        ) = stub.getStubData() as! StubType.ExpectedOutputType

        guard case let .didAppendAudioTrackRows(factualComponentIndex, factualAppendedIndicies) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)
        XCTAssertEqual(expectedAppededIndices, factualAppendedIndicies)

        mockAudioDownloader.verify()
    }

    func test_downloadAudiofileWithCode_failure_WhenInvalidCode() throws {
        typealias StubType = DownloadAudiofileWithCodeFailureWhenInvalidCodeTestStub
        let stub = stubProvider.getStub()

        let stubPage = stub.getStubData() as! StubType.GivenStubDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            audioDownloader: mockAudioDownloader,
            page: stubPage)

        mockAudioDownloader.actions = .init(expected: [.downloadAudioTask])
        mockAudioDownloader.downloadTaskResult = .failure(AudioDownloadError.invalidCode)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<MemoPageViewModel.Output>()
        let (componentId, downloadCode) = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.willDownloadMusicWithCode(componentId, downloadCode))
        wait(for: [expectation], timeout: 1)

        let factual = try factualOutput.getOutput()
        let (expectedComponentIndex) = stub.getStubData() as! StubType.ExpectedOutputType

        guard case let .didPresentInvalidDownloadCode(factualComponentIndex) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentIndex, factualComponentIndex)
        mockAudioDownloader.verify()
    }
}
