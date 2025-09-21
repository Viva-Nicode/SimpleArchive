import Combine
import UIKit

@MainActor class SingleTablePageViewModel: NSObject, ViewModelType {

    typealias Input = SingleTablePageInput
    typealias Output = SingleTablePageOutput

    private var output = PassthroughSubject<SingleTablePageOutput, Never>()
    private var subscriptions = Set<AnyCancellable>()

    private var coredataReposotory: MemoComponentRepositoryForSingleComponent
    private var tableComponent: TableComponent
    private var pageTitle: String

    init(
        coredataReposotory: MemoComponentRepositoryForSingleComponent,
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

                case .willPresentSnapshotView:
                    guard let repository = DIContainer.shared.resolve(ComponentSnapshotCoreDataRepository.self)
                    else { return }

                    let componentSnapshotViewModel = ComponentSnapshotViewModel(
                        componentSnapshotCoreDataRepository: repository,
                        snapshotRestorableComponent: tableComponent as (any SnapshotRestorable))

                    output.send(.didTappedSnapshotButton(componentSnapshotViewModel))

                case .willRestoreComponentWithSnapshot:
                    output.send(.didTappedCaptureButton(tableComponent.detail))

                case .willCaptureToComponent(let desc):
                    coredataReposotory.captureSnapshot(
                        snapshotRestorableComponent: tableComponent,
                        desc: desc)

                case .willRemoveTableComponentRow(let rowID):
                    let removedRowIndex = tableComponent.componentDetail.removeRow(rowID)
                    tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                    output.send(.didRemoveTableComponentRow(removedRowIndex))

                case .willEditTableComponentCellValue(let cellid, let newCellValue):
                    let indices = tableComponent.componentDetail.editCellValeu(cellid, newCellValue)
                    tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                    output.send(.didEditTableComponentCellValue(indices.0, indices.1, newCellValue))

                case .willAppendTableComponentColumn:
                    let newColumn = tableComponent.componentDetail.appendNewColumn(columnTitle: "column")
                    tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                    output.send(.didAppendTableComponentColumn(newColumn))

                case .willAppendTableComponentRow:
                    let newRow = tableComponent.componentDetail.appendNewRow()
                    tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                    output.send(.didAppendTableComponentRow(newRow))

                case .presentTableComponentColumnEditPopupView(let columnIndex):
                    output.send(
                        .didPresentTableComponentColumnEditPopupView(
                            tableComponent.componentDetail.columns, columnIndex))

                case .editTableComponentColumn(let editedColumns):
                    tableComponent.componentDetail.setColumn(editedColumns)
                    tableComponent.persistenceState = .unsaved(isMustToStoreSnapshot: true)
                    output.send(.didEditTableComponentColumn(editedColumns))
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
