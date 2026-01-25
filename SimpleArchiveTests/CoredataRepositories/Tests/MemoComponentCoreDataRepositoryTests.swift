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
        coreDataStack.printAllEntities()
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

    // 행하나 추가된 테이블 컴포넌트에 열을 하나추가하고 코어데이터에 저장했을때 올바르게 저장이 되었는가
    func test_updateTableComponentContentChanges_withAppendColumn_successfully() throws {
        typealias FixtureType = UpdateTableComponentContentChangesWithAppendColumnSuccessfullyTestFixture
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

        let (expectedRows, expectedColumns, cellCount) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType
        let fetchRequest = TableComponentEntity.findTableComponentEntityById(id: changedComponent.id)

        coreDataStack
            .fetch(fetchRequest) { $0 }
            .tryMap { try XCTUnwrap($0.first, "\(#function) : can not found entity") }
            .sinkToResult { result in
                switch result {
                    case .success(let factual):
                        let rowEntities = factual.rows.array as! [TableComponentRowEntity]
                        let columnEntities = factual.columns.array as! [TableComponentColumnEntity]
                        var cellSet = Set<TableComponentCellEntity>()
                        rowEntities.map { $0.cells }.forEach { cellSet.formUnion($0) }
                        columnEntities.map { $0.cells }.forEach { cellSet.formUnion($0) }

                        XCTAssertEqual(rowEntities.count, expectedRows.count)
                        XCTAssertEqual(columnEntities.count, expectedColumns.count)
                        XCTAssertEqual(cellSet.count, cellCount)

                        for (columnEntity, columnModel) in zip(columnEntities, expectedColumns) {
                            for (rowEntity, rowModel) in zip(rowEntities, expectedRows) {
                                XCTAssertEqual(rowEntity.id, rowModel.id)
                                XCTAssertEqual(rowEntity.createdAt, rowModel.createdAt)
                                XCTAssertEqual(rowEntity.modifiedAt, rowModel.modifiedAt)

                                XCTAssertTrue(
                                    cellSet.contains {
                                        $0.column.id == columnModel.id && $0.row.id == rowModel.id
                                    }
                                )
                            }

                            XCTAssertEqual(columnEntity.id, columnModel.id)
                            XCTAssertEqual(columnEntity.title, columnModel.title)
                        }

                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }

    // 정렬 기준이 title이고 채워진 오디오 컴포넌트에 audio들이 추가되었을 때 올바르게 코어데이터에 저장되는가
    func test_updateAudioComponentContentChanges_withAppendAudios_successfully() throws {
        typealias FixtureType = UpdateAudioComponentContentChangesWithAppendAudiosSuccessfullyTestFixture
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

        let (expectedTrackCount, expected) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType
        let fetchRequest = AudioComponentEntity.findAudioComponentEntityById(id: changedComponent.id)

        coreDataStack
            .fetch(fetchRequest) { $0 }
            .tryMap { try XCTUnwrap($0.first, "\(#function) : can not found entity") }
            .sinkToResult { result in
                switch result {
                    case .success(let factual):
                        let audios = factual.audios.array as! [AudioComponentTrackEntity]
                        XCTAssertEqual(audios.count, expectedTrackCount)

                        for (expectedIndex, expectedID) in expected {
                            if let factualIndex = audios.firstIndex(where: { $0.id == expectedID }) {
                                XCTAssertEqual(factualIndex, expectedIndex)
                            } else {
                                XCTFail("\(#function) can not found audioEntity")
                            }
                        }

                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            }
            .store(in: &subscriptions)
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

    func test_captureSnapshot_withManual_successfully() throws {
        typealias FixtureType = CaptureSnapshotWithManualSuccessfullyTestFixture
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

        let (componentID, snapshotCount, snapshotContents, snapshotDescription) =
            fixture.getFixtureData() as! FixtureType.ExpectedOutputType
        let fetchRequest = TextEditorComponentEntity.findTextComponentEntityById(id: componentID)

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

    func test_captureSnapshot_withAutoMatic_successfully() throws {
        typealias FixtureType = CaptureSnapshotWithAutoMaticSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(
            storageItem: givenFixtureData,
            systemDirectory: .mainDirectory)

        let snapshotRestorableComponents = fixture.getFixtureData() as! FixtureType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .captureSnapshot(snapshotRestorableComponents: snapshotRestorableComponents)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let expectedOutput = fixture.getFixtureData() as! FixtureType.ExpectedOutputType
        let fetchRequests = MemoComponentEntity.fetchRequest()

        coreDataStack
            .fetch(fetchRequests) { $0 }
            .sinkToResult { result in
                switch result {
                    case .success(let factualEntities):
                        for componentEntity in factualEntities {
                            if let text = componentEntity as? TextEditorComponentEntity {
                                let most = text.snapshots.max { $0.makingDate < $1.makingDate }
                                XCTAssertEqual(text.snapshots.count, expectedOutput[text.id]?.snapshotCount)
                                XCTAssertEqual(most?.contents, expectedOutput[text.id]?.snapshotContents)

                            } else if let table = componentEntity as? TableComponentEntity {
                                let most = table.snapshots.max { $0.makingDate < $1.makingDate }
                                XCTAssertEqual(table.snapshots.count, expectedOutput[table.id]?.snapshotCount)
                                XCTAssertNotNil(most?.contents)
                            }
                        }

                    case .failure(let error):
                        XCTFail(error.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }
}
