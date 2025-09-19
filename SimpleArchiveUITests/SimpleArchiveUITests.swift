import UIKit
import XCTest

@testable import SimpleArchive

@MainActor
final class SimpleArchiveUITests: XCTestCase {

    let simpleArchive: XCUIApplication = {
        let app = XCUIApplication(bundleIdentifier: "org.azurelight.SimpleArchive")
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchArguments += ["IS_UI_TESTING"]
        return app
    }()

    override func setUpWithError() throws {
        simpleArchive.launch()
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {

    }

    @MainActor
    func test_createNewPage_andThen_removePage() throws {

        let newPageAddButton = simpleArchive.buttons["newPageButton"]
        newPageAddButton.tap()

        let newPageNameTextField = simpleArchive.textFields["newPageNameTextField"]
        XCTAssertTrue(newPageNameTextField.waitForExistence(timeout: 1))
        newPageNameTextField.tap()

        newPageNameTextField.typeText("test Page")
        simpleArchive.buttons["newPageConfirmButton"].tap()

        let collectionView = simpleArchive.collectionViews["memoHomeCollectionView"]
        let firstCollectionCell = collectionView.cells.element(boundBy: 0)
        let nestedTableView = firstCollectionCell.tables["memoHomeTableView"]

        let firstRow = nestedTableView.cells.element(boundBy: 0)
        XCTAssertTrue(firstRow.exists, "첫 번째 테이블 셀을 찾을 수 없음")

        firstRow.swipeLeft()
        let removeButton = firstRow.buttons["removeFile"]
        XCTAssertTrue(removeButton.exists, "remove 버튼을 찾을 수 없음")
        removeButton.tap()
    }

    func test_createNewDirectory_andThen_removeDirectory() throws {
        
    }
}
