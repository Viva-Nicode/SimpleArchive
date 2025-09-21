import Combine
import UIKit

@MainActor class MemoPageViewModel: NSObject, ViewModelType {

    typealias Input = MemoPageViewInput
    typealias Output = MemoPageViewOutput

    private var output = PassthroughSubject<Output, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private(set) var memoPage: MemoPageModel!
    private(set) var isReadOnly: Bool = false

    private var memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType
    private var componentFactory: any ComponentFactoryType

    init(
        componentFactory: any ComponentFactoryType,
        memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType,
        page: MemoPageModel,
        isReadOnly: Bool = false
    ) {
        self.componentFactory = componentFactory
        self.memoComponentCoredataReposotory = memoComponentCoredataReposotory
        self.memoPage = page
        self.isReadOnly = isReadOnly

        super.init()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveComponentsChanges),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
    }

    deinit { print("MemoPageViewModel deinit") }

    @discardableResult
    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad:
                    output.send(.viewDidLoad(memoPage.name, isReadOnly))

                case .createNewComponent(let componentType):
                    createNewComponent(with: componentType)

                case .removeComponent(let componentID):
                    removeComponent(componentID: componentID)

                case .changeComponentName(let id, let newName):
                    changeComponentName(componentID: id, newName: newName)

                case .minimizeComponent(let componentID):
                    minimizeComponent(componentID: componentID)

                case .maximizeComponent(let componentID):
                    maximizeComponent(componentID: componentID)

                case .changeComponentOrder(let sourceIndex, let destinationIndex):
                    changeComponentOrder(sourceIndex: sourceIndex, destinationIndex: destinationIndex)

                case .viewWillDisappear:
                    saveComponentsChanges()

                case .tappedCaptureButton(let componentID, let description):
                    captureComponent(componentID: componentID, description: description)

                case .tappedSnapshotButton(let componentID):
                    moveToComponentSnapshotView(componentID: componentID)

                case .appendTableComponentRow(let componentID):
                    appendTableComponentRow(componentID)

                case .removeTableComponentRow(let componentID, let rowID):
                    removeTableComponentRow(componentID, rowID)

                case .appendTableComponentColumn(let componentID):
                    appendTableComponentColumn(componentID)

                case .editTableComponentCellValue(let componentID, let cellID, let newCellValue):
                    changeTableComponentCellValue(componentID, cellID, newCellValue)

                case .presentTableComponentColumnEditPopupView(let componentID, let tappedColumnIndex):
                    if let pageComponent = memoPage[componentID],
                        let tableComponent = pageComponent.item as? TableComponent
                    {
                        output.send(
                            .didPresentTableComponentColumnEditPopupView(
                                tableComponent.componentDetail.columns, tappedColumnIndex, componentID))
                    }
                
                case .editTableComponentColumn(let componentID, let columns):
                    if let pageComponent = memoPage[componentID],
                        let tableComponent = pageComponent.item as? TableComponent
                    {
                        tableComponent.componentDetail.setColumn(columns)
                        tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                        output.send(.didEditTableComponentColumn(pageComponent.index, columns))
                    }
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func appendTableComponentRow(_ tableComponentID: UUID) {
        if let pageComponent = memoPage[tableComponentID],
            let tableComponent = pageComponent.item as? TableComponent
        {
            let newRow = tableComponent.componentDetail.appendNewRow()
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didAppendTableComponentRow(pageComponent.index, newRow))
        }
    }

    private func removeTableComponentRow(_ tableComponentID: UUID, _ rowID: UUID) {
        if let pageComponent = memoPage[tableComponentID],
            let tableComponent = pageComponent.item as? TableComponent
        {
            let removedRowIndex = tableComponent.componentDetail.removeRow(rowID)
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didRemoveTableComponentRow(pageComponent.index, removedRowIndex))
        }
    }

    private func appendTableComponentColumn(_ tableComponentID: UUID) {
        if let pageComponent = memoPage[tableComponentID],
            let tableComponent = pageComponent.item as? TableComponent
        {
            let newColumn = tableComponent.componentDetail.appendNewColumn(columnTitle: "column")

            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didAppendTableComponentColumn(pageComponent.index, newColumn))
        }
    }

    private func changeTableComponentCellValue(_ tableComponentID: UUID, _ cellID: UUID, _ newCellValue: String) {
        if let pageComponent = memoPage[tableComponentID],
            let tableComponent = pageComponent.item as? TableComponent
        {
            let indices = tableComponent.componentDetail.editCellValeu(cellID, newCellValue)
            tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
            output.send(.didEditTableComponentCellValue(pageComponent.index, indices.0, indices.1, newCellValue))
        }
    }

    private func createNewComponent(with: ComponentType) {
        componentFactory.setCreator(creator: with.getComponentCreator())
        let newComponent = componentFactory.createComponent()

        memoPage.appendChildComponent(component: newComponent)
        memoComponentCoredataReposotory.createComponentEntity(
            parentPageID: memoPage.id, component: newComponent)
        output.send(.insertNewComponentAtLastIndex(memoPage.compnentSize - 1))
    }

    private func removeComponent(componentID: UUID) {
        if let removedComponent = memoPage.removeChildComponentById(componentID) {
            memoComponentCoredataReposotory.removeComponent(
                parentPageID: memoPage.id,
                componentID: removedComponent.item.id)
            output.send(.removeComponentAtIndex(removedComponent.index))
        }
    }

    private func maximizeComponent(componentID: UUID) {
        if let pageComponent = memoPage[componentID] {
            output.send(.maximizeComponent(pageComponent.item , pageComponent.index))
        }
    }

    private func changeComponentName(componentID: UUID, newName: String) {
        if let pageComponent = memoPage[componentID] {
            pageComponent.item.title = newName
            let pageComponentChangeObject = PageComponentChangeObject(
                componentIdChanged: componentID,
                title: newName)
            memoComponentCoredataReposotory.updateComponentChanges(componentChanges: pageComponentChangeObject)
        }
    }

    private func minimizeComponent(componentID: UUID) {
        if let pageComponent = memoPage[componentID] {
            pageComponent.item.isMinimumHeight.toggle()
            let pageComponentChangeObject = PageComponentChangeObject(
                componentIdChanged: componentID,
                isMinimumHeight: pageComponent.item.isMinimumHeight)
            memoComponentCoredataReposotory.updateComponentChanges(componentChanges: pageComponentChangeObject)
            output.send(.didMinimizeComponentHeight(pageComponent.index))
        }
    }

    private func changeComponentOrder(sourceIndex: Int, destinationIndex: Int) {
        let id = memoPage.changeComponentRenderingOrder(src: sourceIndex, des: destinationIndex)
        let pageComponentChangeObject = PageComponentChangeObject(
            componentIdChanged: id,
            componentIdListRenderingOrdered: memoPage.getComponents.map { $0.id })
        memoComponentCoredataReposotory.updateComponentChanges(componentChanges: pageComponentChangeObject)
    }

    private func captureComponent(componentID: UUID, description: String) {
        if let pageComponent = memoPage[componentID]?.item,
            let snapshotRestorableComponent = pageComponent as? any SnapshotRestorable
        {
            memoComponentCoredataReposotory.captureSnapshot(
                snapshotRestorableComponent: snapshotRestorableComponent,
                desc: description)
        }
    }

    func moveToComponentSnapshotView(componentID: UUID) {
        guard
            let repository = DIContainer.shared.resolve(ComponentSnapshotCoreDataRepository.self),
            let component = memoPage[componentID],
            let textEditorComponent = component.item as? any SnapshotRestorable
        else { return }

        let componentSnapshotViewModel = ComponentSnapshotViewModel(
            componentSnapshotCoreDataRepository: repository,
            snapshotRestorableComponent: textEditorComponent)

        output.send(.didTappedSnapshotButton(componentSnapshotViewModel, component.index))
    }

    @objc private func saveComponentsChanges() {
        let components = memoPage.getComponents.compactMap { $0.currentIfUnsaved() }
        memoComponentCoredataReposotory.saveComponentsDetail(changedComponents: components)
    }
}
