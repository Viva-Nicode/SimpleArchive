import Combine
import UIKit
import XCTest

@testable import SimpleArchive

final class MemoDirectoryCoreDataRepositoryTests: XCTestCase, StubProvidingTestCase {
    var stubProvider = MemoDirectoryCoreDataRepositoryTestStubProvider()
    var sut: MemoDirectoryCoreDataRepositoryType!
    var coreDataStack: CoreDataStack = CoreDataStack.manager
    var subscriptions: Set<AnyCancellable>!

    override func setUpWithError() throws {
        sut = MemoDirectoryCoreDataRepository(coredataStack: coreDataStack)
        subscriptions = []
    }

    override func tearDownWithError() throws {
        sut = nil
        stubProvider.removeUsedStubData()
        coreDataStack.cleanAllCoreDataEntitiesExceptSystemDirectories()
        subscriptions = nil
    }

    func test_fetchSystemDirectoryEntities_onFirstAppLaunch() throws {
        typealias StubType = FetchSystemDirectoryEntitiesOnFirstAppLaunchTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType

        SystemDirectories.mainDirectory.removeId()
        SystemDirectories.fixedFileDirectory.removeId()
        coreDataStack.cleanAllCoreDataEntities()

        sut
            .fetchSystemDirectoryEntities(fileCreator: givenStubData)
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
        typealias StubType = FetchSystemDirectoryEntitiesSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType

        sut
            .fetchSystemDirectoryEntities(fileCreator: givenStubData)
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
        typealias StubType = CreateStorageItemWithDirectoryTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStubData, systemDirectory: .mainDirectory)

        let expectation = XCTestExpectation(description: "")
        let targetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .createStorageItem(storageItem: targetInput)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
    }

    func test_createStorageItem_withPage() throws {
        typealias StubType = CreateStorageItemWithPageTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStubData, systemDirectory: .mainDirectory)

        let expectation = XCTestExpectation(description: "")
        let targetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut
            .createStorageItem(storageItem: targetInput)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
    }

    func test_moveFileToDormantBox_withDirectory() throws {
        typealias StubType = MoveFileToDormantBoxWithDirectoryTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStubData, systemDirectory: .mainDirectory)

        let expectation = XCTestExpectation(description: "")
        let targetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut.moveFileToDormantBox(fileID: targetInput)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let (directoryCount, pageCount) = stub.getStubData() as! StubType.ExpectedOutputType
        let fetchReuqest = MemoDirectoryEntity.findDirectoryEntityById(
            id: SystemDirectories.dormantBoxDirectory.getId()!)

        coreDataStack
            .fetch(fetchReuqest) { $0 }
            .map { $0.first! }
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
        typealias StubType = MoveFileToDormantBoxWithPageTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStubData, systemDirectory: .mainDirectory)

        let expectation = XCTestExpectation(description: "")
        let targetInput = stub.getStubData() as! StubType.TestTargetInputType

        sut.moveFileToDormantBox(fileID: targetInput)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let fetchReuqest = MemoDirectoryEntity.findDirectoryEntityById(
            id: SystemDirectories.dormantBoxDirectory.getId()!)

        coreDataStack
            .fetch(fetchReuqest) { $0 }
            .map { $0.first! }
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
