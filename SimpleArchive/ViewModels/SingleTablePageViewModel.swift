//import Combine
//import UIKit
//
//@MainActor class SingleTablePageViewModel: NSObject, ViewModelType {
//
//    typealias Input = SingleTablePageInput
//    typealias Output = SingleTablePageOutput
//
//    private var output = PassthroughSubject<SingleTablePageOutput, Never>()
//    private var subscriptions = Set<AnyCancellable>()
//
//    private var coredataReposotory: MemoComponentCoreDataRepositoryType
//    private var tableComponent: TableComponent
//    private var pageTitle: String
//
//    private let captureDispatchSemaphore = DispatchSemaphore(value: 1)
//
//    init(
//        coredataReposotory: MemoComponentCoreDataRepositoryType,
//        tableComponent: TableComponent,
//        pageTitle: String
//    ) {
//        self.coredataReposotory = coredataReposotory
//        self.tableComponent = tableComponent
//        self.pageTitle = pageTitle
//
//        super.init()
//
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(captureComponentsChanges),
//            name: UIScene.didEnterBackgroundNotification,
//            object: nil)
//
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(captureComponentsChanges),
//            name: UIScene.didDisconnectNotification,
//            object: nil)
//    }
//
//    deinit { myLog(String(describing: Swift.type(of: self)), c: .purple) }
//
//    func subscribe(input: AnyPublisher<Input, Never>) -> AnyPublisher<Output, Never> {
//        input.sink { [weak self] event in
//            guard let self else { return }
//
//            switch event {
//                case .viewDidLoad:
//                    output.send(
//                        .viewDidLoad(
//                            pageTitle,
//                            tableComponent.creationDate,
//                            tableComponent.componentContents,
//                            tableComponent.id
//                        )
//                    )
//
//                case .viewWillDisappear:
//                    captureComponentsChangesOnDisappear()
//
////                case .willNavigateSnapshotView:
////                    DIContainer.shared.setArgument(ComponentSnapshotViewModel.self, tableComponent)
////                    let componentSnapshotViewModel = DIContainer.shared.resolve(ComponentSnapshotViewModel.self)
////                    output.send(.didNavigateSnapshotView(componentSnapshotViewModel))
//
////                case .willRestoreComponent:
////                    output.send(.didRestoreComponent(tableComponent.componentContents))
//
////                case .willCaptureComponent(_):
//                    //                    coredataReposotory.captureSnapshot(
//                    //                        snapshotRestorableComponent: tableComponent,
//                    //                        snapShotDescription: desc)
//
//                    //                    output.send(.didCompleteComponentCapture)
////                    break
//
//                case .willAppendRowToTable:
//                    let newRow = tableComponent.componentContents.appendNewRow()
//					tableComponent.captureState = .needsCapture
//                    tableComponent.actions.append(.appendRow(row: newRow))
//                    coredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
//                    output.send(.didAppendRowToTableView(newRow))
//
//                case .willRemoveRowToTable(let rowID):
//                    let removedRowIndex = tableComponent.componentContents.removeRow(rowID)
//					tableComponent.captureState = .needsCapture
//                    tableComponent.actions.append(.removeRow(rowID: rowID))
//                    coredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
//                    output.send(.didRemoveRowToTableView(removedRowIndex))
//
//                case .willAppendColumnToTable:
//                    let newColumn = tableComponent.componentContents.appendNewColumn(title: "column")
//					tableComponent.captureState = .needsCapture
//                    tableComponent.actions.append(.appendColumn(column: newColumn))
//                    coredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
//                    output.send(.didAppendColumnToTableView(newColumn))
//
//                case .willApplyTableCellChanges(let colID, let rowID, let newCellValue):
//                    let indices = tableComponent
//                        .componentContents
//                        .editCellValeu(rowID: rowID, colID: colID, newValue: newCellValue)
//					tableComponent.captureState = .needsCapture
//                    tableComponent.actions.append(
//                        .editCellValue(rowID: rowID, columnID: colID, value: newCellValue))
//                    coredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
//                    output.send(.didApplyTableCellValueChanges(indices.rowIndex, indices.columnIndex, newCellValue))
//
//                case .willPresentTableColumnEditingPopupView(let columnID):
//                    let columnIndex = tableComponent.componentContents.columns.firstIndex(where: { $0.id == columnID })!
//                    output.send(
//                        .didPresentTableColumnEditPopupView(
//                            tableComponent.componentContents.columns, columnIndex))
//
//                case .willApplyTableColumnChanges(let editedColumns):
//                    tableComponent.componentContents.setColumn(columns: editedColumns)
//					tableComponent.captureState = .needsCapture
//                    tableComponent.actions.append(.editColumn(columns: editedColumns))
//                    coredataReposotory.updateComponentContentChanges(modifiedComponent: tableComponent)
//                    output.send(.didApplyTableColumnChanges(editedColumns))
//            }
//        }
//        .store(in: &subscriptions)
//
//        return output.eraseToAnyPublisher()
//    }
//
//    private func captureComponentsChangesOnDisappear() {
//        //        if let changedTableComponent = tableComponent.currentIfUnsaved() {
//        //            coredataReposotory.captureSnapshot(snapshotRestorableComponents: [changedTableComponent])
//        //        }
//    }
//
//    @objc private func captureComponentsChanges() {
//
//        var taskID: UIBackgroundTaskIdentifier = .invalid
//
//        taskID = UIApplication.shared.beginBackgroundTask {
//            UIApplication.shared.endBackgroundTask(taskID)
//            taskID = .invalid
//        }
//
//        captureDispatchSemaphore.wait()
//
//        //        if let changedTableComponent = tableComponent.currentIfUnsaved() {
//        //            coredataReposotory.captureSnapshot(snapshotRestorableComponents: [changedTableComponent])
//        //                .sinkToResult { result in
//        //                    switch result {
//        //                        case .success:
//        //                            print("capture successfully")
//        //                        case .failure(let failure):
//        //                            print("capture fail reason : \(failure.localizedDescription)")
//        //                    }
//        //                    UIApplication.shared.endBackgroundTask(taskID)
//        //                    self.captureDispatchSemaphore.signal()
//        //                }
//        //                .store(in: &subscriptions)
//        //        } else {
//        //            print("no components to capture")
//        //            UIApplication.shared.endBackgroundTask(taskID)
//        //            captureDispatchSemaphore.signal()
//        //        }
//    }
//}
