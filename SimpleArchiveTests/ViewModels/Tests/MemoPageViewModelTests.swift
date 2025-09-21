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

        let (testPage, createdNewComponent) = stub.getStubData() as! StubType.GivenStubDataType

        sut = MemoPageViewModel(
            componentFactory: mockComponentFactory,
            memoComponentCoredataReposotory: mockMemoComponentCoredataReposotory,
            page: testPage)

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

        input.send(.createNewComponent(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let factual = try factualOutput.getOutput()
        let expectedComponentCount = stub.getStubData() as! StubType.ExpectedOutputType

        guard case let .insertNewComponentAtLastIndex(factualComponentCount) = factual else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedComponentCount, factualComponentCount)

        mockComponentFactory.verify()
        mockMemoComponentCoredataReposotory.verify()
    }

    func test_captureComponent_successfully() throws {
        typealias StubType = CaptureComponentSuccessfullyTestStub
        _ = stubProvider.getStub()

        /*
         테스트 시나리오(케이스들)의 수가 너무 적다.
         좀 더 다양한 전제로, 입력값들로 상황을 만들어서 테스트를 해야하는데
         
         버전별 테스트 라던가.
         실패한 경우 예외처리에 관한 테스트 라던가.
        
         이 테스트 함수 작성하다가 말았음.
         아웃풋이 없고, 함수들이 너무 단순해서 의미있는 테스트가 아닌것같아 일단은 여기서 중지됨.
        
         */

    }
}
