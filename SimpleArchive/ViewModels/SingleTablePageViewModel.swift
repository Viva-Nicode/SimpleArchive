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

    private let captureDispatchSemaphore = DispatchSemaphore(value: 1)

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
            selector: #selector(captureComponentsChanges),
            name: UIScene.didEnterBackgroundNotification,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(captureComponentsChanges),
            name: UIScene.didDisconnectNotification,
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
                            tableComponent.id
                        )
                    )

                case .viewWillDisappear:
                    captureComponentsChangesOnDisappear()

                case .willNavigateSnapshotView:
                    guard let repository = DIContainer.shared.resolve(ComponentSnapshotCoreDataRepository.self)
                    else { return }

                    let componentSnapshotViewModel = ComponentSnapshotViewModel(
                        componentSnapshotCoreDataRepository: repository,
                        snapshotRestorableComponent: tableComponent)

                    output.send(.didNavigateSnapshotView(componentSnapshotViewModel))

                case .willRestoreComponent:
                    output.send(.didRestoreComponent(tableComponent.detail))

                case .willCaptureComponent(let desc):
                    coredataReposotory.captureSnapshot(
                        snapshotRestorableComponent: tableComponent,
                        saveMode: .manual,
                        snapShotDescription: desc)

                    output.send(.didCompleteComponentCapture)

                case .willRemoveRowToTable(let rowID):
                    let removedRowIndex = tableComponent.componentDetail.removeRow(rowID)
                    tableComponent.setCaptureState(to: .needsCapture)
                    coredataReposotory.saveComponentsDetail(modifiedComponent: tableComponent)
                    output.send(.didRemoveRowToTableView(removedRowIndex))

                case .willApplyTableCellChanges(let cellid, let newCellValue):
                    let indices = tableComponent.componentDetail.editCellValeu(cellid, newCellValue)
                    tableComponent.setCaptureState(to: .needsCapture)
                    coredataReposotory.saveComponentsDetail(modifiedComponent: tableComponent)
                    output.send(.didApplyTableCellValueChanges(indices.0, indices.1, newCellValue))

                case .willAppendColumnToTable:
                    let newColumn = tableComponent.componentDetail.appendNewColumn(columnTitle: "column")
                    tableComponent.setCaptureState(to: .needsCapture)
                    coredataReposotory.saveComponentsDetail(modifiedComponent: tableComponent)
                    output.send(.didAppendColumnToTableView(newColumn))

                case .willAppendRowToTable:
                    let newRow = tableComponent.componentDetail.appendNewRow()
                    tableComponent.setCaptureState(to: .needsCapture)
                    coredataReposotory.saveComponentsDetail(modifiedComponent: tableComponent)
                    output.send(.didAppendRowToTableView(newRow))

                case .willPresentTableColumnEditingPopupView(let columnIndex):
                    output.send(
                        .didPresentTableColumnEditPopupView(
                            tableComponent.componentDetail.columns, columnIndex))

                case .willApplyTableColumnChanges(let editedColumns):
                    tableComponent.componentDetail.setColumn(editedColumns)
                    tableComponent.setCaptureState(to: .needsCapture)
                    coredataReposotory.saveComponentsDetail(modifiedComponent: tableComponent)
                    output.send(.didApplyTableColumnChanges(editedColumns))
            }
        }
        .store(in: &subscriptions)

        return output.eraseToAnyPublisher()
    }

    private func captureComponentsChangesOnDisappear() {
        if let changedTableComponent = tableComponent.currentIfUnsaved() {
            coredataReposotory.captureSnapshot(snapshotRestorableComponents: [changedTableComponent])
        }
    }

    @objc private func captureComponentsChanges() {

        var taskID: UIBackgroundTaskIdentifier = .invalid

        taskID = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(taskID)
            taskID = .invalid
        }

        captureDispatchSemaphore.wait()

        if let changedTableComponent = tableComponent.currentIfUnsaved() {
            coredataReposotory.captureSnapshot(snapshotRestorableComponents: [changedTableComponent])
                .sinkToResult { result in
                    switch result {
                        case .success:
                            print("capture successfully")
                        case .failure(let failure):
                            print("capture fail reason : \(failure.localizedDescription)")
                    }
                    UIApplication.shared.endBackgroundTask(taskID)
                    self.captureDispatchSemaphore.signal()
                }
                .store(in: &subscriptions)
        } else {
            print("no components to capture")
            UIApplication.shared.endBackgroundTask(taskID)
            captureDispatchSemaphore.signal()
        }
    }
}
