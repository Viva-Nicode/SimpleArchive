import Foundation

protocol PageComponentInteractorType {
    associatedtype PageComponentType: PageComponent

    var pageComponent: PageComponentType { get }
    var memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType { get }
    var componentSnapshotCoreDataRepository: ComponentSnapshotCoreDataRepositoryType { get }

    var pageComponentContents: PageComponentType.ContentType { get }

    func renamePageComponent(title: String)
    func toggleFoldingPageComponent() -> Bool
    func maximizePageComponent() -> Bool
    func removePageComponent()
}

extension PageComponentInteractorType {
    var pageComponentContents: PageComponentType.ContentType {
        pageComponent.componentContents
    }

    func renamePageComponent(title: String) {
        pageComponent.title = title
        memoComponentCoredataReposotory.updateComponentName(componentID: pageComponent.id, newName: title)
    }

    func toggleFoldingPageComponent() -> Bool {
        pageComponent.isMinimumHeight.toggle()
        memoComponentCoredataReposotory.updateComponentFolding(
            componentID: pageComponent.id,
            isFolding: pageComponent.isMinimumHeight)
        return pageComponent.isMinimumHeight
    }

    func maximizePageComponent() -> Bool {
        let isMaximizable = !pageComponent.isMinimumHeight
        if pageComponent.isMinimumHeight {
            pageComponent.isMinimumHeight.toggle()
            memoComponentCoredataReposotory.updateComponentFolding(
                componentID: pageComponent.id,
                isFolding: pageComponent.isMinimumHeight)
        }
        return isMaximizable
    }

    func removePageComponent() {
        memoComponentCoredataReposotory.removeComponentEntity(componentID: pageComponent.id)
    }
}

protocol CaptureableComponentInteractorType: PageComponentInteractorType {
    func captureSnapshotManual(description: String)
    func captureSnapshotAutomatic()
}

extension CaptureableComponentInteractorType {
    func captureSnapshotManual(description: String) {
        if let captureablePageComponent = pageComponent as? (any SnapshotRestorablePageComponent) {
            let snapshot = captureablePageComponent.makeSnapshot(desc: description, saveMode: .manual)
            componentSnapshotCoreDataRepository.createComponentSnapshot(
                snapshots: [(captureablePageComponent.id, snapshot)])
            captureablePageComponent.setCaptureState(to: .captured)
        }
    }

    func captureSnapshotAutomatic() {
        if let captureablePageComponent = pageComponent as? (any SnapshotRestorablePageComponent) {
            if captureablePageComponent.captureState == .needsCapture {
                let snapshot = captureablePageComponent.makeSnapshot(desc: "", saveMode: .automatic)
                componentSnapshotCoreDataRepository.createComponentSnapshot(
                    snapshots: [(captureablePageComponent.id, snapshot)])
                captureablePageComponent.setCaptureState(to: .captured)
                DebugHelper.myLog("\(captureablePageComponent.title) : capture complete")
            } else {
                DebugHelper.myLog("\(captureablePageComponent.title) : do not needed capture")
            }
        }
    }
}
