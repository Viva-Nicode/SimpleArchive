import Combine
import UIKit

@MainActor class SingleTablePageViewModel: NSObject, ViewModelType {

    typealias Input = SingleTablePageInput
    typealias Output = SingleTablePageOutput

    private var output = PassthroughSubject<SingleTablePageOutput, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private var coredataReposotory: MemoSingleComponentRepositoryType
    private var tableComponent: TableComponent
    private var pageTitle: String

    init(
        coredataReposotory: MemoSingleComponentRepositoryType,
        tableComponent: TableComponent,
        pageTitle: String
    ) {
        self.coredataReposotory = coredataReposotory
        self.tableComponent = tableComponent
        self.pageTitle = pageTitle
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveComponentsChanges),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
    }

    deinit { print("deinit SingleTablePageViewModel") }

    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
        input.sink { [weak self] event in
            guard let self else { return }

            switch event {
                case .viewDidLoad:
                    output.send(
                        .viewDidLoad(
                            pageTitle,
                            tableComponent.creationDate,
                            tableComponent.detail,
                            tableComponent.id))

                case .viewWillDisappear:
                    saveComponentsChanges()

                case .willNavigateSnapshotView:
                    guard let repository = DIContainer.shared.resolve(ComponentSnapshotCoreDataRepository.self)
                    else { return }

                    let componentSnapshotViewModel = ComponentSnapshotViewModel(
                        componentSnapshotCoreDataRepository: repository,
                        snapshotRestorableComponent: tableComponent as (any SnapshotRestorable))

                    output.send(.didNavigateSnapshotView(componentSnapshotViewModel))

                case .willRestoreComponent:
                    output.send(.didRestoreComponent(tableComponent.detail))

                case .willCaptureComponent(let desc):
                    coredataReposotory.captureSnapshot(
                        snapshotRestorableComponent: tableComponent,
                        desc: desc)
                    output.send(.didCompleteComponentCapture)

                case .willRemoveRowToTable(let rowID):
                    let removedRowIndex = tableComponent.componentDetail.removeRow(rowID)
                    tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                    output.send(.didRemoveRowToTableView(removedRowIndex))

                case .willApplyTableCellChanges(let cellid, let newCellValue):
                    let indices = tableComponent.componentDetail.editCellValeu(cellid, newCellValue)
                    tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                    output.send(.didApplyTableCellValueChanges(indices.0, indices.1, newCellValue))

                case .willAppendColumnToTable:
                    let newColumn = tableComponent.componentDetail.appendNewColumn(columnTitle: "column")
                    tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                    output.send(.didAppendColumnToTableView(newColumn))

                case .willAppendRowToTable:
                    let newRow = tableComponent.componentDetail.appendNewRow()
                    tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                    output.send(.didAppendRowToTableView(newRow))

                case .willPresentTableColumnEditingPopupView(let columnIndex):
                    output.send(
                        .didPresentTableColumnEditPopupView(
                            tableComponent.componentDetail.columns, columnIndex))

                case .willApplyTableColumnChanges(let editedColumns):
                    tableComponent.componentDetail.setColumn(editedColumns)
                    tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                    output.send(.didApplyTableColumnChanges(editedColumns))
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    @objc private func saveComponentsChanges() {
        if let changedTextEditorComponent = tableComponent.currentIfUnsaved() {
            coredataReposotory.saveComponentsDetail(changedComponents: [changedTextEditorComponent])
        }
    }
}
