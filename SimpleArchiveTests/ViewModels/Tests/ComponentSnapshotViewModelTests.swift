import Combine
import XCTest

@testable import SimpleArchive

@MainActor
final class ComponentSnapshotViewModelTests: XCTestCase, @preconcurrency StubProvidingTestCase {

    var sut: ComponentSnapshotViewModel!
    var stubProvider = ComponentSnapshotViewModelTestStubProvider()
    var componentSnapshotCoreDataRepository: MockComponentSnapshotCoreDataRepository!
    var subscriptions: Set<AnyCancellable>!
    var input: PassthroughSubject<ComponentSnapshotViewModel.Input, Never>!

    override func setUpWithError() throws {
        componentSnapshotCoreDataRepository = MockComponentSnapshotCoreDataRepository()
        input = PassthroughSubject<ComponentSnapshotViewModel.Input, Never>()
        subscriptions = []
    }

    override func tearDownWithError() throws {
        stubProvider.removeUsedStubData()
        componentSnapshotCoreDataRepository = nil
        sut = nil
        input = nil
        subscriptions = nil
    }

    func test_removeSnapshot_whenFirstSnapshotIsDeleted() throws {
        typealias StubType = RemoveSnapshotWhenFirstSnapshotIsDeletedTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenStubData)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.Output>()
        let testTargetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.removeSnapshot(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (expectedRemovedSnapshotIndex, expectedNextMetaData) = stub.getStubData() as! StubType.ExpectedOutputType

        guard case let .didCompleteRemoveSnapshot(factualMetadata, factualRemovedSnapshotIndex) = output else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(factualRemovedSnapshotIndex, expectedRemovedSnapshotIndex)
        XCTAssertEqual(factualMetadata, expectedNextMetaData)
    }

    func test_removeSnapshot_whenMiddleSnapshotIsDeleted() throws {
        typealias StubType = RemoveSnapshotWhenMiddleSnapshotIsDeletedTestStub
        let stub = stubProvider.getStub()

        let (givenStubData, initialViewedSnapshotID) = stub.getStubData() as! StubType.GivenStubDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: givenStubData,
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            initialViewedSnapshotID: initialViewedSnapshotID)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.Output>()
        let testTargetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut.subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.removeSnapshot(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (expectedRemovedSnapshotIndex, expectedNextMetaData) = stub.getStubData() as! StubType.ExpectedOutputType

        guard case let .didCompleteRemoveSnapshot(metadata, removedSnapshotIndex) = output else {
            XCTFail("Unexpected output")
            return
        }
        XCTAssertEqual(removedSnapshotIndex, expectedRemovedSnapshotIndex)
        XCTAssertEqual(metadata, expectedNextMetaData)
    }

    func test_removeSnapshot_whenLastSnapshotIsDeleted() throws {
        typealias StubType = RemoveSnapshotWhenLastSnapshotIsDeletedTestStub
        let stub = stubProvider.getStub()

        let (givenStubData, initialViewedSnapshotID) = stub.getStubData() as! StubType.GivenStubDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: givenStubData,
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            initialViewedSnapshotID: initialViewedSnapshotID)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.Output>()
        let testTargetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.removeSnapshot(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (expectedRemovedSnapshotIndex, expectedNextMetaData) = stub.getStubData() as! StubType.ExpectedOutputType

        guard case let .didCompleteRemoveSnapshot(metadata, removedSnapshotIndex) = output else {
            XCTFail("Unexpected output")
            return
        }
        XCTAssertEqual(removedSnapshotIndex, expectedRemovedSnapshotIndex)
        XCTAssertEqual(metadata, expectedNextMetaData)
    }

    func test_removeSnapshot_whenOnlySnapshotIsDeleted() throws {
        typealias StubType = RemoveSnapshotWhenOnlySnapshotIsDeletedTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenStubData)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.Output>()
        let testTargetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.removeSnapshot(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let expectedRemovedSnapshotIndex = stub.getStubData() as! StubType.ExpectedOutputType

        guard case let .didCompleteRemoveSnapshot(metadata, removedSnapshotIndex) = output else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(removedSnapshotIndex, expectedRemovedSnapshotIndex)
        XCTAssertNil(metadata)
    }

    func test_removeSnapshot_failureWhenSnapshotMismatch() throws {
        typealias StubType = RemoveSnapshotFailureWhenSnapshotMismatchTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenStubData)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.ErrorOutput>()
        let testTargetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sink { _ in }
            .store(in: &subscriptions)

        sut
            .errorSubscribe()
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.removeSnapshot(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()

        guard case .componentIDMismatchError = output else {
            XCTFail("Unexpected output")
            return
        }
    }

    func test_removeSnapshot_failureWhenNotFoundSnapshot() throws {
        typealias StubType = RemoveSnapshotFailureWhenNotFoundSnapshotTestStub
        let stub = stubProvider.getStub()

        let (testComponent, notExistID) = stub.getStubData() as! StubType.GivenStubDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: testComponent,
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            initialViewedSnapshotID: notExistID)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.ErrorOutput>()
        let testTargetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sink { _ in }
            .store(in: &subscriptions)

        sut
            .errorSubscribe()
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.removeSnapshot(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()

        guard case .canNotFoundSnapshot = output else {
            XCTFail("Unexpected output")
            return
        }
    }

    func test_restoreSnapshot_successfully() throws {
        typealias StubType = RestoreSnapshotSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenStubData)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.restoreSnapshot)
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()

        guard case .didCompleteRestoreSnapshot = output else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(givenStubData.detail, "Snapshot 1 detail")
        XCTAssertEqual(givenStubData.persistenceState, .unsaved(isMustToStoreSnapshot: false))
    }

    func test_restoreSnapshot_failureWhenNotFoundSnapshot() throws {
        typealias StubType = RestoreSnapshotFailureWhenNotFoundSnapshotStubTest
        let stub = stubProvider.getStub()

        let (givenStubData, notExistID) = stub.getStubData() as! StubType.GivenStubDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: givenStubData,
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            initialViewedSnapshotID: notExistID)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.ErrorOutput>()

        sut.subscribe(input: input.eraseToAnyPublisher())
            .sink { _ in }
            .store(in: &subscriptions)

        sut.errorSubscribe()
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.restoreSnapshot)
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()

        guard case .canNotFoundSnapshot = output else {
            XCTFail("Unexpected output")
            return
        }
    }
}
