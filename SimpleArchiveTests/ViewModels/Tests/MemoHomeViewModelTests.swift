import Combine
import XCTest

@testable import SimpleArchive

@MainActor
final class MemoHomeViewModelTests: XCTestCase, @preconcurrency StubProvidingTestCase {

    var sut: MemoHomeViewModel!
    var subscriptions: Set<AnyCancellable>!
    var mockMemoDirectoryCoreDataRepository: MockMemoDirectoryCoreDataRepository!
    var mockMemoPageCoreDataRepository: MockMemoPageCoreDataRepository!
    var mockDirectoryCreator: MockDirectoryCreator!
    var mockPageCreator: MockPageCreator!
    var stubProvider = MemoHomeViewModelTestStubProvider()
    var input: PassthroughSubject<MemoHomeViewModel.Input, Never>!

    override func setUpWithError() throws {
        mockMemoDirectoryCoreDataRepository = MockMemoDirectoryCoreDataRepository()
        mockMemoPageCoreDataRepository = MockMemoPageCoreDataRepository()
        mockDirectoryCreator = MockDirectoryCreator()
        mockPageCreator = MockPageCreator()
        sut = MemoHomeViewModel(
            memoDirectoryCoredataReposotory: mockMemoDirectoryCoreDataRepository,
            memoPageCoredataReposotory: mockMemoPageCoreDataRepository,
            directoryCreator: mockDirectoryCreator,
            pageCreator: mockPageCreator
        )
        input = PassthroughSubject<MemoHomeViewModel.Input, Never>()
        subscriptions = []
    }

    override func tearDownWithError() throws {
        stubProvider.removeUsedStubData()
        mockMemoDirectoryCoreDataRepository = nil
        mockMemoPageCoreDataRepository = nil
        mockDirectoryCreator = nil
        mockPageCreator = nil
        subscriptions = nil
        input = nil
        sut = nil
    }

    func test_fetchMemoData_successfully() throws {
        typealias StubType = FetchMemoDataSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenStub = stub.getStubData() as! StubType.GivenStubDataType

        mockMemoDirectoryCoreDataRepository.actions = .init(expected: [
            .fetchSystemDirectoryEntities
        ])
        mockMemoDirectoryCoreDataRepository.fetchSystemDirectoryEntitiesResult = .success(givenStub)

        let expectation = XCTestExpectation(description: #function)
        let factualOutput = FactualOutput<MemoHomeViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.viewDidLoad)
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (
            factualMainDirectoryID,
            factualMainDirectorySortCriteria,
            factualMainDirectoryFileCount
        ) = stub.getStubData() as! StubType.ExpectedOutputType

        guard
            case .didFetchMemoData(
                let mainDirectoryID,
                let mainDirectorySortCriteria,
                _,
                let fileCount
            ) = output
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(mainDirectoryID, factualMainDirectoryID)
        XCTAssertEqual(mainDirectorySortCriteria, factualMainDirectorySortCriteria)
        XCTAssertEqual(fileCount, factualMainDirectoryFileCount)
        mockMemoDirectoryCoreDataRepository.verify()
    }

    func test_moveToPreviousDirectory_successfully() throws {
        typealias StubType = MoveToPreviousDirectorySuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenDirectoryStack = stub.getStubData() as! StubType.GivenStubDataType
        sut.setDirectoryStack(with: givenDirectoryStack)

        let expectation = XCTestExpectation(description: #function)
        let factualOutput = FactualOutput<MemoHomeViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        let inputData = stub.getStubData() as! StubType.TestTargetInputType

        input.send(.willMovePreviousDirectoryPath(inputData))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (expectedRemovedDirectoryIndices, expectedNextDirectorySortCriteria, expectedFileCount) =
            stub.getStubData() as! StubType.ExpectedOutputType

        guard
            case .didMovePreviousDirectoryPath(
                let removedDirectoryIndices,
                let nextDirectorySortCriteria,
                let fileCount) = output
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedRemovedDirectoryIndices, removedDirectoryIndices)
        XCTAssertEqual(expectedNextDirectorySortCriteria, nextDirectorySortCriteria)
        XCTAssertEqual(expectedFileCount, fileCount)
    }

    func test_fixPage_successfully() throws {
        typealias StubType = FixPageSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let (directoryStack, fixedDirectory) = stub.getStubData() as! StubType.GivenStubDataType
        sut.setDirectoryStack(with: directoryStack)
        sut.setFixedFileDirectory(with: fixedDirectory)

        mockMemoPageCoreDataRepository.actions = .init(expected: [
            .fixPages
        ])
        mockMemoPageCoreDataRepository.fixPagesResult = .success(())

        let expectation = XCTestExpectation(description: #function)
        let factualOutput = FactualOutput<MemoHomeViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        let inputData = stub.getStubData() as! StubType.TestTargetInputType

        input.send(.willAppendPageToFixedTable(inputData))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (
            expectedDirectoryIndex,
            expectedInsertRowIndices,
            expectedDeleteRowIndices
        ) = stub.getStubData() as! StubType.ExpectedOutputType

        guard
            case .didAppendPageToFixedTable(
                let directoryIndex,
                let insertRowIndices,
                let deleteRowIndices) = output
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(directoryIndex, expectedDirectoryIndex)
        XCTAssertEqual(insertRowIndices, expectedInsertRowIndices)
        XCTAssertEqual(deleteRowIndices, expectedDeleteRowIndices)

        mockMemoPageCoreDataRepository.verify()
    }

    func test_unfixPage_successfully() throws {
        typealias StubType = UnfixPageSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let subInput = PassthroughSubject<MemoHomeSubViewInput, Never>()
        let (directoryStack, fixedDirectory) = stub.getStubData() as! StubType.GivenStubDataType
        sut.setDirectoryStack(with: directoryStack)
        sut.setFixedFileDirectory(with: fixedDirectory)

        mockMemoPageCoreDataRepository.actions = .init(expected: [
            .unfixPages
        ])
        mockMemoPageCoreDataRepository.unfixPagesResult = .success(())

        let expectation = XCTestExpectation(description: #function)
        let factualOutput = FactualOutput<MemoHomeViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        sut.subscribe(input: subInput.eraseToAnyPublisher())

        let inputData = stub.getStubData() as! StubType.TestTargetInputType
        subInput.send(.willAppendPageToHomeTable(inputData))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (
            expectedDirectoryIndex,
            expectedInsertRowIndices,
            expectedDeleteRowIndices
        ) = stub.getStubData() as! StubType.ExpectedOutputType

        guard
            case .didAppendPageToHomeTable(
                let directoryIndex,
                let insertRowIndices,
                let deleteRowIndices) = output
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(directoryIndex, expectedDirectoryIndex)
        XCTAssertEqual(insertRowIndices, expectedInsertRowIndices)
        XCTAssertEqual(deleteRowIndices, expectedDeleteRowIndices)
        mockMemoPageCoreDataRepository.verify()
    }

    func test_createdNewDirectory_successfully() throws {
        typealias StubType = CreatedNewDirectorySuccessfullyTestStub
        let stub = stubProvider.getStub()

        let subInput = PassthroughSubject<MemoHomeSubViewInput, Never>()
        let (directoryStack, createdNewDirectory) = stub.getStubData() as! StubType.GivenStubDataType
        sut.setDirectoryStack(with: directoryStack)

        mockMemoDirectoryCoreDataRepository.actions = .init(expected: [.createStorageItem])
        mockDirectoryCreator.actions = .init(expected: [.createFile])
        mockMemoDirectoryCoreDataRepository.createStorageItemResult = .success(())
        mockDirectoryCreator.createFileResult = createdNewDirectory

        let expectation = XCTestExpectation(description: #function)
        let factualOutput = FactualOutput<MemoHomeViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        sut.subscribe(input: subInput.eraseToAnyPublisher())

        let newDirectoryName = stub.getStubData() as! StubType.TestTargetInputType
        subInput.send(.willCreatedNewDirectory(newDirectoryName))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (
            expectedDirectoryStackIndex,
            expectedInsertIndex,
        ) = stub.getStubData() as! StubType.ExpectedOutputType

        guard
            case .didInsertRowToHomeTable(
                let directoryStackIndex,
                let insertIndex
            ) = output
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedDirectoryStackIndex, directoryStackIndex)
        XCTAssertEqual(expectedInsertIndex, insertIndex)

        mockMemoDirectoryCoreDataRepository.verify()
        mockDirectoryCreator.verify()
    }

    func test_createdNewPage_successfully() throws {
        typealias StubType = CreatedNewPageSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let subInput = PassthroughSubject<MemoHomeSubViewInput, Never>()
        let (directoryStack, createdNewPage) = stub.getStubData() as! StubType.GivenStubDataType
        sut.setDirectoryStack(with: directoryStack)

        mockMemoDirectoryCoreDataRepository.actions = .init(expected: [.createStorageItem])
        mockPageCreator.actions = .init(expected: [.setFirstComponentType, .createFile])
        mockMemoDirectoryCoreDataRepository.createStorageItemResult = .success(())
        mockPageCreator.createFileResult = createdNewPage

        let expectation = XCTestExpectation(description: #function)
        let factualOutput = FactualOutput<MemoHomeViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        sut.subscribe(input: subInput.eraseToAnyPublisher())

        let newPageName = stub.getStubData() as! StubType.TestTargetInputType
        subInput.send(.willCreatedNewPage(newPageName, nil))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()

        let (
            expectedDirectoryStackIndex,
            expectedInsertIndex,
        ) = stub.getStubData() as! StubType.ExpectedOutputType

        guard
            case .didInsertRowToHomeTable(
                let directoryStackIndex,
                let insertIndex
            ) = output
        else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(expectedDirectoryStackIndex, directoryStackIndex)
        XCTAssertEqual(expectedInsertIndex, insertIndex)

        mockMemoDirectoryCoreDataRepository.verify()
        mockPageCreator.verify()
    }
}
