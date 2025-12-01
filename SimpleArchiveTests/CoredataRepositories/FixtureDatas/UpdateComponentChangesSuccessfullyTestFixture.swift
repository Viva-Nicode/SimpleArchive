import Foundation

@testable import SimpleArchive

final class UpdateComponentChangesSuccessfullyTestFixture: TestFixtureType {
    typealias GivenFixtureDataType = MemoDirectoryModel
    typealias TestTargetInputType = PageComponentChangeObject
    typealias ExpectedOutputType = (String, Bool)

    let testTargetName = "test_updateComponentChanges_successfully()"

    private var provideState: TestDataProvideState = .givenFixtureData
    private var testTextEditorComponent: TextEditorComponent!

    func getFixtureData() -> Any {
        switch provideState {
            case .givenFixtureData:
                provideState = .testTargetInput
                return provideGivenFixture()

            case .testTargetInput:
                provideState = .testVerifyOutput
                return provideTestTargetInput()

            case .testVerifyOutput:
                provideState = .allDataConsumed
                return ("after change title", true)

            default:
                return ()
        }
    }

    private func provideGivenFixture() -> GivenFixtureDataType {
        let testDirectory = MemoDirectoryModel(name: "Test Directory")
        let testPage = MemoPageModel(name: "Test Page", parentDirectory: testDirectory)

        let testTextEditorComponent_1 = TextEditorComponent()

        testTextEditorComponent_1.detail = "t1 first Detail"
        testTextEditorComponent_1.makeSnapshot(desc: "t1 first Desc", saveMode: .automatic)
        testTextEditorComponent_1.detail = "t1 second Detail"
        testTextEditorComponent_1.makeSnapshot(desc: "t1 second Desc", saveMode: .automatic)

        testTextEditorComponent = TextEditorComponent(isMinimumHeight: false, title: "before change title")

        testTextEditorComponent.detail = "t2 first Detail"
        testTextEditorComponent.makeSnapshot(desc: "t2 first Desc", saveMode: .automatic)
        testTextEditorComponent.detail = "t2 second Detail"
        testTextEditorComponent.makeSnapshot(desc: "t2 second Desc", saveMode: .automatic)

        testPage.appendChildComponent(component: testTextEditorComponent_1)
        testPage.appendChildComponent(component: testTextEditorComponent)

        return testDirectory
    }

    private func provideTestTargetInput() -> TestTargetInputType {
        testTextEditorComponent.title = "after change title"
        testTextEditorComponent.isMinimumHeight = true

        return PageComponentChangeObject(
            componentIdChanged: testTextEditorComponent.id,
            title: "after change title",
            isMinimumHeight: true
        )
    }
}
