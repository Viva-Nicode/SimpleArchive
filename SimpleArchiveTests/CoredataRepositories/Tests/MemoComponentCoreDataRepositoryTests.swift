import Combine
import UIKit
import XCTest

@testable import SimpleArchive

final class MemoComponentCoreDataRepositoryTests: XCTestCase, FixtureProvidingTestCase {
    var fixtureProvider = MemoComponentCoreDataRepositoryTestFixtureProvider()
    var sut: MemoComponentCoreDataRepositoryType!
    var coreDataStack: CoreDataStack = CoreDataStack.manager
    var subscriptions: Set<AnyCancellable>!

    override func setUpWithError() throws {
        sut = MemoComponentCoreDataRepository(coredataStack: coreDataStack)
        subscriptions = []
    }

    override func tearDownWithError() throws {
        sut = nil
        fixtureProvider.removeUsedFixtureData()
        coreDataStack.cleanAllCoreDataEntitiesExceptSystemDirectories()
        subscriptions = nil
    }

    func test_createComponent_successfully() throws {
        typealias FixtureType = CreateComponentSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(
            storageItem: givenFixtureData,
            systemDirectory: .mainDirectory)

        let (pageId, component) = fixture.getFixtureData() as! FixtureType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .createComponentEntity(parentPageID: pageId, component: component)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
    }

    func test_updateTextEditorComponentContentChanges_successfully() throws {
        typealias FixtureType = UpdateTextEditorComponentContentChangesSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(
            storageItem: givenFixtureData,
            systemDirectory: .mainDirectory)

        let changedComponent = fixture.getFixtureData() as! FixtureType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .updateComponentContentChanges(modifiedComponent: changedComponent)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let expectedContents = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        let fetchRequest = TextEditorComponentEntity.findTextComponentEntityById(id: changedComponent.id)

        coreDataStack
            .fetch(fetchRequest) { $0 }
            .tryMap { try XCTUnwrap($0.first, "\(#function) : can not found entity") }
            .sinkToResult { result in
                switch result {
                    case .success(let factual):
                        XCTAssertEqual(factual.contents, expectedContents)

                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }

    
    func test_updateTableComponentContentChanges_successfully() throws {
        
//        TableComponentEntity.findTableComponentEntityById(id: )
    }

    func test_updateAudioComponentContentChanges_successfully() throws {
        
    }

    func test_updateComponentChanges_successfully() throws {
        typealias FixtureType = UpdateComponentChangesSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(
            storageItem: givenFixtureData,
            systemDirectory: .mainDirectory)

        let componentChanges = fixture.getFixtureData() as! FixtureType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .updateComponentChanges(componentChanges: componentChanges)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
        let expectedTitle = fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        let fetchRequest = TextEditorComponentEntity.findTextComponentEntityById(
            id: componentChanges.componentIdChanged)

        coreDataStack
            .fetch(fetchRequest) { $0 }
            .tryMap { try XCTUnwrap($0.first, "\(#function) : can not found entity") }
            .sinkToResult { result in
                switch result {
                    case .success(let factual):
                        XCTAssertEqual(factual.title, expectedTitle)

                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }

    func test_captureSnapshot_successfully() throws {
        typealias FixtureType = CaptureSnapshotSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(
            storageItem: givenFixtureData,
            systemDirectory: .mainDirectory)

        let (snapshotRestorableComponent, description) = fixture.getFixtureData() as! FixtureType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .captureSnapshot(snapshotRestorableComponent: snapshotRestorableComponent, snapShotDescription: description)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let fetchRequest =
            TextEditorComponentEntity
            .findTextComponentEntityById(id: snapshotRestorableComponent.id)
        let (snapshotCount, snapshotContents, snapshotDescription) =
            fixture.getFixtureData() as! FixtureType.ExpectedOutputType

        coreDataStack
            .fetch(fetchRequest) { $0 }
            .tryMap { try XCTUnwrap($0.first, "\(#function) : can not found entity") }
            .sinkToResult { result in
                switch result {
                    case .success(let factual):
                        let mostRecentSnapshot = factual.snapshots.max { $0.makingDate < $1.makingDate }!

                        XCTAssertEqual(factual.snapshots.count, snapshotCount)
                        XCTAssertEqual(mostRecentSnapshot.contents, snapshotContents)
                        XCTAssertEqual(mostRecentSnapshot.snapShotDescription, snapshotDescription)

                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }
}
