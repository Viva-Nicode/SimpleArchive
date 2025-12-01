import Combine
import XCTest

@testable import SimpleArchive

@MainActor
final class ComponentSnapshotViewModelTests: XCTestCase, @preconcurrency FixtureProvidingTestCase {

    var sut: ComponentSnapshotViewModel!
    var fixtureProvider = ComponentSnapshotViewModelTestFixtureProvider()
    var componentSnapshotCoreDataRepository: MockComponentSnapshotCoreDataRepository!
    var subscriptions: Set<AnyCancellable>!
    var input: PassthroughSubject<ComponentSnapshotViewModel.Input, Never>!

    override func setUpWithError() throws {
        componentSnapshotCoreDataRepository = MockComponentSnapshotCoreDataRepository()
        input = PassthroughSubject<ComponentSnapshotViewModel.Input, Never>()
        subscriptions = []
    }

    override func tearDownWithError() throws {
        fixtureProvider.removeUsedFixtureData()
        componentSnapshotCoreDataRepository = nil
        sut = nil
        input = nil
        subscriptions = nil
    }

    func test_removeSnapshot_whenFirstSnapshotIsDeleted() throws {
        typealias FixtureType = RemoveSnapshotWhenFirstSnapshotIsDeletedTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenFixtureData)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.Output>()
        let testTargetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.removeSnapshot(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (expectedRemovedSnapshotIndex, expectedNextMetaData) =
            fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        guard case let .didCompleteRemoveSnapshot(factualMetadata, factualRemovedSnapshotIndex) = output else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(factualRemovedSnapshotIndex, expectedRemovedSnapshotIndex)
        XCTAssertEqual(factualMetadata, expectedNextMetaData)
    }

    func test_removeSnapshot_whenMiddleSnapshotIsDeleted() throws {
        typealias FixtureType = RemoveSnapshotWhenMiddleSnapshotIsDeletedTestFixture
        let fixture = fixtureProvider.getFixture()

        let (givenFixtureData, initialViewedSnapshotID) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: givenFixtureData,
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            initialViewedSnapshotID: initialViewedSnapshotID)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.Output>()
        let testTargetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut.subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.removeSnapshot(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (expectedRemovedSnapshotIndex, expectedNextMetaData) =
            fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        guard case let .didCompleteRemoveSnapshot(metadata, removedSnapshotIndex) = output else {
            XCTFail("Unexpected output")
            return
        }
        XCTAssertEqual(removedSnapshotIndex, expectedRemovedSnapshotIndex)
        XCTAssertEqual(metadata, expectedNextMetaData)
    }

    func test_removeSnapshot_whenLastSnapshotIsDeleted() throws {
        typealias FixtureType = RemoveSnapshotWhenLastSnapshotIsDeletedTestFixture
        let fixture = fixtureProvider.getFixture()

        let (givenFixtureData, initialViewedSnapshotID) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: givenFixtureData,
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            initialViewedSnapshotID: initialViewedSnapshotID)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.Output>()
        let testTargetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.removeSnapshot(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (expectedRemovedSnapshotIndex, expectedNextMetaData) =
            fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        guard case let .didCompleteRemoveSnapshot(metadata, removedSnapshotIndex) = output else {
            XCTFail("Unexpected output")
            return
        }
        XCTAssertEqual(removedSnapshotIndex, expectedRemovedSnapshotIndex)
        XCTAssertEqual(metadata, expectedNextMetaData)
    }

    func test_removeSnapshot_whenOnlySnapshotIsDeleted() throws {
        typealias FixtureType = RemoveSnapshotWhenOnlySnapshotIsDeletedTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenFixtureData)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.Output>()
        let testTargetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.removeSnapshot(testTargetInput))
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let expectedRemovedSnapshotIndex = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        guard case let .didCompleteRemoveSnapshot(metadata, removedSnapshotIndex) = output else {
            XCTFail("Unexpected output")
            return
        }

        XCTAssertEqual(removedSnapshotIndex, expectedRemovedSnapshotIndex)
        XCTAssertNil(metadata)
    }

    func test_removeSnapshot_failureWhenSnapshotMismatch() throws {
        typealias FixtureType = RemoveSnapshotFailureWhenSnapshotMismatchTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenFixtureData)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.ErrorOutput>()
        let testTargetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

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
        typealias FixtureType = RemoveSnapshotFailureWhenNotFoundSnapshotTestFixture
        let fixture = fixtureProvider.getFixture()

        let (testComponent, notExistID) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: testComponent,
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            initialViewedSnapshotID: notExistID)

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.ErrorOutput>()
        let testTargetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

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
        typealias FixtureType = RestoreSnapshotSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: componentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenFixtureData)

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

        XCTAssertEqual(givenFixtureData.detail, "Snapshot 1 detail")
        XCTAssertEqual(givenFixtureData.persistenceState, .unsaved(isMustToStoreSnapshot: false))
        // 이거 왜 기븐을 테스트하냐
    }

    func test_restoreSnapshot_failureWhenNotFoundSnapshot() throws {
        typealias FixtureType = RestoreSnapshotFailureWhenNotFoundSnapshotTestFixture
        let fixture = fixtureProvider.getFixture()

        let (givenFixtureData, notExistID) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: givenFixtureData,
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
