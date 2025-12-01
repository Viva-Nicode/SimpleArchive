import Combine
import UIKit
import XCTest

@testable import SimpleArchive

final class DormantBoxCoreDataRepositoryTests: XCTestCase, FixtureProvidingTestCase {

    var sut: DormantBoxCoreDataRepositoryType!
    var fixtureProvider = DormantBoxCoreDataRepositoryTestFixtureProvider()
    var coreDataStack: CoreDataStack = CoreDataStack.manager
    var subscriptions: Set<AnyCancellable>!

    override func setUpWithError() throws {
        sut = DormantBoxCoreDataRepository(coredataStack: coreDataStack)
        subscriptions = []
    }

    override func tearDownWithError() throws {
        sut = nil
        fixtureProvider.removeUsedFixtureData()
        coreDataStack.cleanAllCoreDataEntitiesExceptSystemDirectories()
        subscriptions = nil
    }

    func test_fetchDormantBoxDirectory_successfully() throws {
        typealias FixtureType = FetchDormantBoxDirectorySuccessfullyTestFixture
        _ = fixtureProvider.getFixture()

        let expectation = XCTestExpectation(description: "")

        sut
            .fetchDormantBoxDirectory()
            .map { _ in () }
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)
    }

    func test_restoreFile_successfully() throws {
        typealias FixtureType = RestoreFileSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixtureData = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(
            storageItem: givenFixtureData,
            systemDirectory: .dormantBoxDirectory)

        let expectation = XCTestExpectation(description: "")

        sut
            .restoreFile(restoredFileID: givenFixtureData.id)
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let mainDirectoryID = SystemDirectories.mainDirectory.getId()!
        coreDataStack.fetch(MemoDirectoryEntity.findDirectoryEntityById(id: mainDirectoryID)) { $0 }
            .map { $0.first! }
            .sinkToResult { result in
                switch result {
                    case .success(let mainDirectoryEntity):
                        XCTAssertEqual(mainDirectoryEntity.pages.first!.id, givenFixtureData.id)

                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }
}
