import Combine
import UIKit
import XCTest

@testable import SimpleArchive

final class MemoPageCoreDataRepositoryTests: XCTestCase, StubProvidingTestCase {
    var sut: MemoPageCoreDataRepositoryType!
    var stubProvider = MemoPageCoreDataRepositoryTestStubProvider()
    var coreDataStack: CoreDataStack = CoreDataStack.manager
    var subscriptions: Set<AnyCancellable>!

    override func setUpWithError() throws {
        sut = MemoPageCoreDataRepository(coredataStack: coreDataStack)
        subscriptions = []
    }

    override func tearDownWithError() throws {
        sut = nil
        stubProvider.removeUsedStubData()
        coreDataStack.cleanAllCoreDataEntitiesExceptSystemDirectories()
        subscriptions = nil
    }

    func test_fixPages_successfully() throws {
        typealias StubType = FixPagesSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let givenStub = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: givenStub, systemDirectory: .mainDirectory)

        let pageId = stub.getStubData() as! StubType.TestTargetInputType
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
        typealias StubType = UnfixPagesSuccessfullyTestStub
        let stub = stubProvider.getStub()

        let (testDirectory, testPage) = stub.getStubData() as! StubType.GivenStubDataType
        try coreDataStack.prepareCoreDataEntities(storageItem: testDirectory, systemDirectory: .mainDirectory)
        try coreDataStack.prepareCoreDataEntities(storageItem: testPage, systemDirectory: .fixedFileDirectory)

        let (testDirectoryID, pageId) = stub.getStubData() as! StubType.TestTargetInputType
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
