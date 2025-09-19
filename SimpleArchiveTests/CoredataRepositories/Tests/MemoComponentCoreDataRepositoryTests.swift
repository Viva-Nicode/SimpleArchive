import Combine
import UIKit
import XCTest

@testable import SimpleArchive

final class MemoComponentCoreDataRepositoryTests: XCTestCase, StubProvidingTestCase {
    var stubProvider = MemoComponentCoreDataRepositoryTestStubProvider()
    var sut: MemoComponentCoreDataRepositoryType!
    var coreDataStack: CoreDataStack = CoreDataStack.manager
    var subscriptions: Set<AnyCancellable>!

    override func setUpWithError() throws {
        sut = MemoComponentCoreDataRepository(coredataStack: coreDataStack)
        subscriptions = []
    }

    override func tearDownWithError() throws {
        sut = nil
        stubProvider.removeUsedStubData()
        coreDataStack.cleanAllCoreDataEntitiesExceptSystemDirectories()
        subscriptions = nil
    }

    func test_createComponent_successfully() throws {
        typealias StubType = CreateComponentSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStubData, systemDirectory: .mainDirectory)

        let (pageId, component) = stub.getStubData() as! StubType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .createComponentEntity(parentPageID: pageId, component: component)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
    }

    func test_saveComponentDetail_successfully() throws {
        typealias StubType = SaveComponentDetailSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStubData, systemDirectory: .mainDirectory)

        let changedComponents = stub.getStubData() as! StubType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .saveComponentsDetail(changedComponents: changedComponents)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let expectedOutput = stub.getStubData() as! StubType.ExpectedOutputType

        for (changedComponent, (persistentState, snapshotCount, detail)) in zip(changedComponents, expectedOutput) {
            let fetchRequest = TextEditorComponentEntity.findTextComponentEntityById(id: changedComponent.id)

            coreDataStack
                .fetch(fetchRequest) { $0 }
                .map { $0.first! }
                .sinkToResult { result in
                    switch result {
                        case .success(let factual):
                            XCTAssertEqual(factual.detail, detail)
                            XCTAssertEqual(factual.snapshots.count, snapshotCount)
                            XCTAssertEqual(changedComponent.persistenceState, persistentState)

                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                    }
                }
                .store(in: &subscriptions)
        }
    }

    func test_saveComponentDetail_withRestoredComponents_successfully() throws {
        typealias StubType = SaveComponentDetailWithRestoredComponentsSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStubData, systemDirectory: .mainDirectory)

        let changedComponents = stub.getStubData() as! StubType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .saveComponentsDetail(changedComponents: changedComponents)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let expectedOutput = stub.getStubData() as! StubType.ExpectedOutputType

        for (changedComponent, (persistentState, snapshotCount, detail))
            in zip(changedComponents, expectedOutput)
        {
            let fetchRequest = TextEditorComponentEntity.findTextComponentEntityById(id: changedComponent.id)

            coreDataStack
                .fetch(fetchRequest) { $0 }
                .map { $0.first! }
                .sinkToResult { result in
                    switch result {
                        case .success(let factual):
                            XCTAssertEqual(factual.detail, detail)
                            XCTAssertEqual(factual.snapshots.count, snapshotCount)
                            XCTAssertEqual(changedComponent.persistenceState, persistentState)

                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                    }
                }
                .store(in: &subscriptions)
        }
    }

    func test_updateComponentChanges_successfully() throws {
        typealias StubType = UpdateComponentChangesSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStubData, systemDirectory: .mainDirectory)

        let componentChanges = stub.getStubData() as! StubType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .updateComponentChanges(componentChanges: componentChanges)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
        let (expectedTitle, expectedIsMinimum) = stub.getStubData() as! StubType.ExpectedOutputType

        let fetchRequest = TextEditorComponentEntity.findTextComponentEntityById(
            id: componentChanges.componentIdChanged)

        coreDataStack
            .fetch(fetchRequest) { $0 }
            .map { $0.first! }
            .sinkToResult { result in
                switch result {
                    case .success(let factual):
                        XCTAssertEqual(factual.title, expectedTitle)
                        XCTAssertEqual(factual.isMinimumHeight, expectedIsMinimum)

                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }

    func test_captureSnapshot_successfully() throws {
        typealias StubType = CaptureSnapshotSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStubData, systemDirectory: .mainDirectory)

        let (snapshotRestorableComponent, description) = stub.getStubData() as! StubType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .captureSnapshot(snapshotRestorableComponent: snapshotRestorableComponent, desc: description)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let fetchRequest = TextEditorComponentEntity.findTextComponentEntityById(
            id: snapshotRestorableComponent.id)
        let (snapshotCount, snapshotDetail, snapshotDescription) =
            stub.getStubData() as! StubType.ExpectedOutputType

        coreDataStack
            .fetch(fetchRequest) { $0 }
            .map { $0.first! }
            .sinkToResult { result in
                switch result {
                    case .success(let factual):
                        let mostRecentSnapshot = factual.snapshots.max { $0.makingDate < $1.makingDate }!

                        XCTAssertEqual(factual.snapshots.count, snapshotCount)
                        XCTAssertEqual(mostRecentSnapshot.detail, snapshotDetail)
                        XCTAssertEqual(mostRecentSnapshot.snapShotDescription, snapshotDescription)

                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }
}
