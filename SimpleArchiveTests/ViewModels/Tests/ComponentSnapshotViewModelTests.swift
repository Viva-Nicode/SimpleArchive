import Combine
import XCTest

@testable import SimpleArchive

@MainActor
final class ComponentSnapshotViewModelTests: XCTestCase, @preconcurrency FixtureProvidingTestCase {

    var sut: ComponentSnapshotViewModel!
    var fixtureProvider = ComponentSnapshotViewModelTestFixtureProvider()
    var mockComponentSnapshotCoreDataRepository: MockComponentSnapshotCoreDataRepository!
    var subscriptions: Set<AnyCancellable>!
    var input: PassthroughSubject<ComponentSnapshotViewModel.Input, Never>!

    override func setUpWithError() throws {
        mockComponentSnapshotCoreDataRepository = MockComponentSnapshotCoreDataRepository()
        input = PassthroughSubject<ComponentSnapshotViewModel.Input, Never>()
        subscriptions = []
    }

    override func tearDownWithError() throws {
        fixtureProvider.removeUsedFixtureData()
        mockComponentSnapshotCoreDataRepository = nil
        sut = nil
        input = nil
        subscriptions = nil
    }

    func test_removeSnapshot_whenFirstSnapshotIsDeleted() throws {
        typealias FixtureType = RemoveSnapshotWhenFirstSnapshotIsDeletedTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: mockComponentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenFixtureData)
        
        mockComponentSnapshotCoreDataRepository.actions = .init(expected: [.removeSnapshot])

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
        
        mockComponentSnapshotCoreDataRepository.verify()
    }

    func test_removeSnapshot_whenMiddleSnapshotIsDeleted() throws {
        typealias FixtureType = RemoveSnapshotWhenMiddleSnapshotIsDeletedTestFixture
        let fixture = fixtureProvider.getFixture()

        let (givenFixtureData, initialViewedSnapshotID) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: givenFixtureData,
            componentSnapshotCoreDataRepository: mockComponentSnapshotCoreDataRepository,
            initialViewedSnapshotID: initialViewedSnapshotID)
        
        mockComponentSnapshotCoreDataRepository.actions = .init(expected: [.removeSnapshot])

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
        
        mockComponentSnapshotCoreDataRepository.verify()
    }

    func test_removeSnapshot_whenLastSnapshotIsDeleted() throws {
        typealias FixtureType = RemoveSnapshotWhenLastSnapshotIsDeletedTestFixture
        let fixture = fixtureProvider.getFixture()

        let (givenFixtureData, initialViewedSnapshotID) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: givenFixtureData,
            componentSnapshotCoreDataRepository: mockComponentSnapshotCoreDataRepository,
            initialViewedSnapshotID: initialViewedSnapshotID)
        
        mockComponentSnapshotCoreDataRepository.actions = .init(expected: [.removeSnapshot])

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
        
        mockComponentSnapshotCoreDataRepository.verify()
    }

    func test_removeSnapshot_whenOnlySnapshotIsDeleted() throws {
        typealias FixtureType = RemoveSnapshotWhenOnlySnapshotIsDeletedTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: mockComponentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenFixtureData)
        
        mockComponentSnapshotCoreDataRepository.actions = .init(expected: [.removeSnapshot])

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
        
        mockComponentSnapshotCoreDataRepository.verify()
    }

    func test_removeSnapshot_failureWhenSnapshotMismatch() throws {
        typealias FixtureType = RemoveSnapshotFailureWhenSnapshotMismatchTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: mockComponentSnapshotCoreDataRepository,
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
        
        mockComponentSnapshotCoreDataRepository.verify()
    }

    func test_removeSnapshot_failureWhenNotFoundSnapshot() throws {
        typealias FixtureType = RemoveSnapshotFailureWhenNotFoundSnapshotTestFixture
        let fixture = fixtureProvider.getFixture()

        let (testComponent, notExistID) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: testComponent,
            componentSnapshotCoreDataRepository: mockComponentSnapshotCoreDataRepository,
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
        
        mockComponentSnapshotCoreDataRepository.verify()
    }

    func test_restoreSnapshot_successfully() throws {
        typealias FixtureType = RestoreSnapshotSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: mockComponentSnapshotCoreDataRepository,
            snapshotRestorableComponent: givenFixtureData)
        
        mockComponentSnapshotCoreDataRepository.actions = .init(expected: [.updateComponentContentChanges])

        let expectation = XCTestExpectation(description: "")
        let factualOutput = FactualOutput<ComponentSnapshotViewModel.Output>()

        sut
            .subscribe(input: input.eraseToAnyPublisher())
            .sinkToFulfill(expectation, factualOutput)
            .store(in: &subscriptions)

        input.send(.restoreSnapshot)
        wait(for: [expectation], timeout: 1)

        let output = try factualOutput.getOutput()
        let (expectedContents, expectedCaptureState) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType
        
        guard case .didCompleteRestoreSnapshot = output else {
            XCTFail("Unexpected output")
            return
        }
        
        XCTAssertEqual((sut.snapshotRestorableComponent as! TextEditorComponent).componentContents, expectedContents)
        XCTAssertEqual(sut.snapshotRestorableComponent.captureState, expectedCaptureState)
        
        mockComponentSnapshotCoreDataRepository.verify()
    }

    func test_restoreSnapshot_failureWhenNotFoundSnapshot() throws {
        typealias FixtureType = RestoreSnapshotFailureWhenNotFoundSnapshotTestFixture
        let fixture = fixtureProvider.getFixture()

        let (givenFixtureData, notExistID) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut = ComponentSnapshotViewModel(
            snapshotRestorableComponent: givenFixtureData,
            componentSnapshotCoreDataRepository: mockComponentSnapshotCoreDataRepository,
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
        
        mockComponentSnapshotCoreDataRepository.verify()
    }
}
