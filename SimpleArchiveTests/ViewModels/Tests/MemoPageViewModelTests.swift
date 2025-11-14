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
    var stubProvider = MemoPageViewModelTestStubProvider()

    override func setUpWithError() throws {
        mockMemoComponentCoredataReposotory = MockMemoComponentCoreDataRepository()
        mockComponentFactory = MockComponentFactory()
        input = PassthroughSubject<MemoPageViewModel.Input, Never>()
        subscriptions = []
    }

    override func tearDownWithError() throws {
        stubProvider.removeUsedStubData()
        subscriptions = nil
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
        mockMemoComponentCoredataReposotory.verify()
        XCTAssertEqual(expectedIndex, factualIndex)
    }

    func test_removeComponent_successfullly() throws {

    }

    func test_removeAudioComponent_successfullly() throws {

    }

    func test_downloadAudiofileWithCode_successfullly() throws {

    }

    func test_downloadAudiofileWithCode_failure_WhenInvalidCode() throws {

    }
}
