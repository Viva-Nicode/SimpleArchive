import Combine
import UIKit
import XCTest

@testable import SimpleArchive

final class MemoDirectoryCoreDataRepositoryTests: XCTestCase, FixtureProvidingTestCase {
    var fixtureProvider = MemoDirectoryCoreDataRepositoryTestFixtureProvider()
    var sut: MemoDirectoryCoreDataRepositoryType!
    var coreDataStack: CoreDataStack = CoreDataStack.manager
    var subscriptions: Set<AnyCancellable>!

    override func setUpWithError() throws {
        sut = MemoDirectoryCoreDataRepository(coredataStack: coreDataStack)
        subscriptions = []
    }

    override func tearDownWithError() throws {
        sut = nil
        fixtureProvider.removeUsedFixtureData()
        coreDataStack.cleanAllCoreDataEntitiesExceptSystemDirectories()
        subscriptions = nil
    }

    func test_fetchSystemDirectoryEntities_onFirstAppLaunch() throws {
        typealias FixtureType = FetchSystemDirectoryEntitiesOnFirstAppLaunchTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        SystemDirectories.mainDirectory.removeId()
        SystemDirectories.fixedFileDirectory.removeId()
        coreDataStack.cleanAllCoreDataEntities()

        sut
            .fetchSystemDirectoryEntities(fileCreator: givenFixtureData)
            .sinkToResult { result in
                switch result {
                    case .success(let systemDirectoryEntities):
                        XCTAssertNotNil(systemDirectoryEntities[.mainDirectory])
                        XCTAssertNotNil(systemDirectoryEntities[.fixedFileDirectory])
                        XCTAssertNotNil(SystemDirectories.mainDirectory.getId())
                        XCTAssertNotNil(SystemDirectories.fixedFileDirectory.getId())

                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }

    func test_fetchSystemDirectoryEntities_successfully() throws {
        typealias FixtureType = FetchSystemDirectoryEntitiesSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType

        sut
            .fetchSystemDirectoryEntities(fileCreator: givenFixtureData)
            .sinkToResult { result in
                switch result {
                    case .success(let systemDirectoryEntities):
                        XCTAssertNotNil(systemDirectoryEntities[.mainDirectory])
                        XCTAssertNotNil(systemDirectoryEntities[.fixedFileDirectory])

                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }

    func test_createStorageItem_withDirectory() throws {
        typealias FixtureType = CreateStorageItemWithDirectoryTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(
            storageItem: givenFixtureData,
            systemDirectory: .mainDirectory)

        let expectation = XCTestExpectation(description: "")
        let targetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .createStorageItem(storageItem: targetInput)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
    }

    func test_createStorageItem_withPage() throws {
        typealias FixtureType = CreateStorageItemWithPageTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(
            storageItem: givenFixtureData,
            systemDirectory: .mainDirectory)

        let expectation = XCTestExpectation(description: "")
        let targetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut
            .createStorageItem(storageItem: targetInput)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
    }

    func test_moveFileToDormantBox_withDirectory() throws {
        typealias FixtureType = MoveFileToDormantBoxWithDirectoryTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(
            storageItem: givenFixtureData,
            systemDirectory: .mainDirectory)

        let expectation = XCTestExpectation(description: "")
        let targetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut.moveFileToDormantBox(fileID: targetInput)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let (directoryCount, pageCount) = fixture.getFixtureData() as! FixtureType.ExpectedOutputType
        let fetchReuqest = MemoDirectoryEntity.findDirectoryEntityById(
            id: SystemDirectories.dormantBoxDirectory.getId()!)

        coreDataStack
            .fetch(fetchReuqest) { $0 }
            .tryMap { try XCTUnwrap($0.first, "\(#function) : can not found entity") }
            .sinkToResult { result in
                switch result {
                    case .success(let dormantBoxEntity):
                        XCTAssertEqual(dormantBoxEntity.childDirectories.count, directoryCount)
                        XCTAssertEqual(dormantBoxEntity.pages.count, pageCount)

                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }

    func test_moveFileToDormantBox_withPage() throws {
        typealias FixtureType = MoveFileToDormantBoxWithPageTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(
            storageItem: givenFixtureData,
            systemDirectory: .mainDirectory)

        let expectation = XCTestExpectation(description: "")
        let targetInput = fixture.getFixtureData() as! FixtureType.TestTargetInputType

        sut.moveFileToDormantBox(fileID: targetInput)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let fetchReuqest = MemoDirectoryEntity.findDirectoryEntityById(
            id: SystemDirectories.dormantBoxDirectory.getId()!)

        coreDataStack
            .fetch(fetchReuqest) { $0 }
            .tryMap { try XCTUnwrap($0.first, "\(#function) : can not found entity") }
            .sinkToResult { result in
                switch result {
                    case .success(let dormantBoxEntity):
                        XCTAssertEqual(dormantBoxEntity.pages.count, 1)
                        let areAllComponentsSmall = dormantBoxEntity.pages.first!.components
                            .allSatisfy { $0.isMinimumHeight == false }
                        XCTAssertTrue(areAllComponentsSmall)

                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }
}
