import Combine
import UIKit
import XCTest

@testable import SimpleArchive

final class MemoPageCoreDataRepositoryTests: XCTestCase, FixtureProvidingTestCase {
    var sut: MemoPageCoreDataRepositoryType!
    var fixtureProvider = MemoPageCoreDataRepositoryTestFixtureProvider()
    var coreDataStack: CoreDataStack = CoreDataStack.manager
    var subscriptions: Set<AnyCancellable>!

    override func setUpWithError() throws {
        sut = MemoPageCoreDataRepository(coredataStack: coreDataStack)
        subscriptions = []
    }

    override func tearDownWithError() throws {
        sut = nil
        fixtureProvider.removeUsedFixtureData()
        coreDataStack.cleanAllCoreDataEntitiesExceptSystemDirectories()
        subscriptions = nil
    }

    func test_fixPages_successfully() throws {
        typealias FixtureType = FixPagesSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let givenFixture = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenFixture, systemDirectory: .mainDirectory)

        let pageId = fixture.getFixtureData() as! FixtureType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .fixPages(pageIds: [pageId])
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        let fixedDirectoryID = SystemDirectories.fixedFileDirectory.getId()!

        coreDataStack.fetch(MemoDirectoryEntity.findDirectoryEntityById(id: fixedDirectoryID)) { $0 }
            .map { $0.first! }
            .sinkToResult { result in
                switch result {
                    case .success(let fixedDirectoryEntity):
                        XCTAssertEqual(fixedDirectoryEntity.pages.first!.id, pageId)

                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }

    func test_unfixPages_successfully() throws {
        typealias FixtureType = UnfixPagesSuccessfullyTestFixture
        let fixture = fixtureProvider.getFixture()

        let (testDirectory, testPage) = fixture.getFixtureData() as! FixtureType.GivenFixtureDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: testDirectory, systemDirectory: .mainDirectory)
        try coreDataStack.prepareCoreDataEntities(storageItem: testPage, systemDirectory: .fixedFileDirectory)

        let (testDirectoryID, pageId) = fixture.getFixtureData() as! FixtureType.TestTargetInputType
        let expectation = XCTestExpectation(description: "")

        sut
            .unfixPages(parentDirectoryId: testDirectoryID, pageIds: [pageId])
            .sinkToFulfill(expectation)
            .store(in: &subscriptions)

        wait(for: [expectation], timeout: 1)

        coreDataStack.fetch(MemoDirectoryEntity.findDirectoryEntityById(id: testDirectoryID)) { $0 }
            .map { $0.first! }
            .sinkToResult { result in
                switch result {
                    case .success(let targetDirectory):
                        XCTAssertEqual(targetDirectory.pages.first!.id, pageId)

                    case .failure(let failure):
                        XCTFail(failure.localizedDescription)
                }
            }
            .store(in: &subscriptions)
    }
}
