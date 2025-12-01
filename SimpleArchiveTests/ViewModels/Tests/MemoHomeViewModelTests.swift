import Combine
import XCTest

@testable import SimpleArchive

@MainActor
final class MemoHomeViewModelTests: XCTestCase, @preconcurrency FixtureProvidingTestCase {

    var sut: MemoHomeViewModel!
    var subscriptions: Set<AnyCancellable>!
    var mockMemoDirectoryCoreDataRepository: MockMemoDirectoryCoreDataRepository!
    var mockMemoPageCoreDataRepository: MockMemoPageCoreDataRepository!
    var mockDirectoryCreator: MockDirectoryCreator!
    var mockPageCreator: MockPageCreator!
    var fixtureProvider = MemoHomeViewModelTestFixtureProvider()
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
        fixtureProvider.removeUsedFixtureData()
        mockMemoDirectoryCoreDataRepository = nil
        mockMemoPageCoreDataRepository = nil
        mockDirectoryCreator = nil
        mockPageCreator = nil
        subscriptions = nil
        input = nil
        sut = nil
    }

    func test_fetchMemoData_successfully() throws {
        typealias FixtureType = FetchMemoDataSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixture = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        mockMemoDirectoryCoreDataRepository.actions = .init(expected: [
            .fetchSystemDirectoryEntities
        ])
        mockMemoDirectoryCoreDataRepository.fetchSystemDirectoryEntitiesResult = .success(givenFixture)

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
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

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
        typealias FixtureType = MoveToPreviousDirectorySuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenDirectoryStack = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        sut.setDirectoryStack(with: givenDirectoryStack)

        let expectation = XCTestExpectation(description: #function)
        let factualOutput = FactualOutput<MemoHomeViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        let inputData = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        input.send(.willMovePreviousDirectoryPath(inputData))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (expectedRemovedDirectoryIndices, expectedNextDirectorySortCriteria, expectedFileCount) =
            fixture.getFixtureData() as! FixtureType.ExpectedOutputType

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
        typealias FixtureType = FixPageSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let (directoryStack, fixedDirectory) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        sut.setDirectoryStack(with: directoryStack)
        sut.setFixedFileDirectory(with: fixedDirectory)

        mockMemoPageCoreDataRepository.actions = .init(expected: [.fixPages])
        mockMemoPageCoreDataRepository.fixPagesResult = .success(())

        let expectation = XCTestExpectation(description: #function)
        let factualOutput = FactualOutput<MemoHomeViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        let inputData = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        input.send(.willAppendPageToFixedTable(inputData))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (
            expectedDirectoryIndex,
            expectedInsertRowIndices,
            expectedDeleteRowIndices
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

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
        typealias FixtureType = UnfixPageSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let subInput = PassthroughSubject<MemoHomeSubViewInput, Never>()
        let (directoryStack, fixedDirectory) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        sut.setDirectoryStack(with: directoryStack)
        sut.setFixedFileDirectory(with: fixedDirectory)

        mockMemoPageCoreDataRepository.actions = .init(expected: [.unfixPages])
        mockMemoPageCoreDataRepository.unfixPagesResult = .success(())

        let expectation = XCTestExpectation(description: #function)
        let factualOutput = FactualOutput<MemoHomeViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        sut.subscribe(input: subInput.eraseToAnyPublisher())

        let inputData = fixture.getFixtureData() as! FixtureType.TestTargetInputType
        subInput.send(.willAppendPageToHomeTable(inputData))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (
            expectedDirectoryIndex,
            expectedInsertRowIndices,
            expectedDeleteRowIndices
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

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
        typealias FixtureType = CreatedNewDirectorySuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let subInput = PassthroughSubject<MemoHomeSubViewInput, Never>()
        let (directoryStack, createdNewDirectory) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
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

        let newDirectoryName = fixture.getFixtureData() as! FixtureType.TestTargetInputType
        subInput.send(.willCreatedNewDirectory(newDirectoryName))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (
            expectedDirectoryStackIndex,
            expectedInsertIndex,
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

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
        typealias FixtureType = CreatedNewPageSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let subInput = PassthroughSubject<MemoHomeSubViewInput, Never>()
        let (directoryStack, createdNewPage) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
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

        let newPageName = fixture.getFixtureData() as! FixtureType.TestTargetInputType
        subInput.send(.willCreatedNewPage(newPageName, nil))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()

        let (
            expectedDirectoryStackIndex,
            expectedInsertIndex,
        ) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

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
