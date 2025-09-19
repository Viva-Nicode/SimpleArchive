import Combine
import UIKit
import XCTest

@testable import SimpleArchive

final class DormantBoxCoreDataRepositoryTests: XCTestCase, StubProvidingTestCase {

    var sut: DormantBoxCoreDataRepositoryType!
    var stubProvider = DormantBoxCoreDataRepositoryTestStubProvider()
    var coreDataStack: CoreDataStack = CoreDataStack.manager
    var subscriptions: Set<AnyCancellable>!

    override func setUpWithError() throws {
        sut = DormantBoxCoreDataRepository(coredataStack: coreDataStack)
        subscriptions = []
    }

    override func tearDownWithError() throws {
        sut = nil
        stubProvider.removeUsedStubData()
        coreDataStack.cleanAllCoreDataEntitiesExceptSystemDirectories()
        subscriptions = nil
    }

    func test_fetchDormantBoxDirectory_successfully() throws {
        typealias StubType = FetchDormantBoxDirectorySuccessfullyTestStub
        _ = stubProvider.getStub()

        let expectation = XCTestExpectation(description: "")

        sut
            .fetchDormantBoxDirectory()
            .map { _ in () }
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
    }

    func test_restoreFile_successfully() throws {
        typealias StubType = RestoreFileSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenStubData = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStubData, systemDirectory: .dormantBoxDirectory)

        let expectation = XCTestExpectation(description: "")

        sut
            .restoreFile(restoredFileID: givenStubData.id)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let mainDirectoryID = SystemDirectories.mainDirectory.getId()!
        coreDataStack.fetch(MemoDirectoryEntity.findDirectoryEntityById(id: mainDirectoryID)) { $0 }
            .map { $0.first! }
            .sinkToResult { result in
                switch result {
                    case .success(let mainDirectoryEntity):
                        XCTAssertEqual(mainDirectoryEntity.pages.first!.id, givenStubData.id)

                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }
}
