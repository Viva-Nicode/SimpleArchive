import Combine
import Foundation

final class TableComponentViewModel: PageComponentViewModelType {
    var eventOutput = PassthroughSubject<TableComponentViewModelEvent, Never>()
    var subscriptions = Set<AnyCancellable>()

    private var interactor: TableComponentInteractor
    private var title: String
    private var createdDate: Date
    private var contents: TableComponentContents

    init(tableComponentInteractor: TableComponentInteractor) {
        self.interactor = tableComponentInteractor
        self.title = tableComponentInteractor.pageComponent.title
        self.createdDate = tableComponentInteractor.pageComponent.creationDate
        self.contents = tableComponentInteractor.pageComponent.componentContents
    }

    deinit { myLog(String(describing: Swift.type(of: self)), "\(title)", c: .purple) }

    func bindToView(input: AnyPublisher<TableComponentViewModelAction, Never>)
        -> AnyPublisher<TableComponentViewModelEvent, Never>
    {
        input.sink { [weak self] action in
            guard let self else { return }
            switch action {
                case .tableComponentAction(let tableAction):
                    switch tableAction {
                        case .willAppendColumnToTable:
                            let newColumn = interactor.appendTableComponentColumn()
                            eventOutput.send(.tableComponentEvent(.didAppendColumnToTableView(newColumn: newColumn)))

                        case .willAppendRowToTable:
                            let newRow = interactor.appendTableComponentRow()
                            eventOutput.send(.tableComponentEvent(.didAppendRowToTableView(newRow: newRow)))

                        case .willApplyTableCellChanges(let columnID, let rowID, let cellValue):
                            let tableCoordinate =
                                interactor
                                .applyTableCellValue(
                                    colID: columnID,
                                    rowID: rowID,
                                    newCellValue: cellValue)
                            eventOutput.send(
                                .tableComponentEvent(
                                    .didApplyTableCellValueChanges(
                                        cellCoord: tableCoordinate,
                                        cellValue: cellValue
                                    )
                                )
                            )

                        case .willRemoveRowToTable(let rowID):
                            let rowIndex = interactor.removeTableComponentRow(rowID: rowID)
                            eventOutput.send(.tableComponentEvent(.didRemoveRowToTableView(rowIndex: rowIndex)))

                        case .willApplyTableColumnChanges(let columns):
                            interactor.applyTableColumnChanges(columns: columns)
                            eventOutput.send(.tableComponentEvent(.didApplyTableColumnChanges(columns: columns)))

                        case .willPresentTableColumnEditingPopupView(let columnID):
                            let columnIndex =
                                interactor
                                .presentTableComponentColumnEditPopupView(columnID: columnID)
                            eventOutput.send(
                                .tableComponentEvent(
                                    .didPresentTableColumnEditPopupView(
                                        columns: interactor.pageComponent.componentContents.columns,
                                        columnIndex: columnIndex
                                    )
                                )
                            )
                    }

                case .snapshotAction(let snapshotCommonAction):
                    switch snapshotCommonAction {
                        case .willManualCapturePageComponent(let description):
                            interactor.saveTrackedSnapshotManual(description: description)
                            eventOutput.send(.snapshotEvent(.didManualCapturePageComponent))

                        case .willNavigateComponentSnapshotView:
                            let container = DIContainer.shared
                            container.setArgument(
                                ComponentSnapshotViewModel.self,
                                interactor.pageComponent as any SnapshotRestorablePageComponent)
							container.setArgument(
								ComponentSnapshotViewModel.self,
								interactor.trackingSnapshot as any ComponentSnapshotType)
                            let componentSnapshotViewModel = container.resolve(ComponentSnapshotViewModel.self)

							componentSnapshotViewModel.updateTrackingSnapshotSignal
								.sink { [weak self] _ in
									guard let self else { return }
									interactor.trackingSnapshot = TableComponentSnapshot(
										contents: interactor.pageComponent.componentContents,
										description: "",
										saveMode: .automatic,
										modificationHistory: [])
								}
								.store(in: &subscriptions)
                            eventOutput.send(
                                .snapshotEvent(.didNavigateComponentSnapshotView(componentSnapshotViewModel)))
                    }
            }
        }
        .store(in: &subscriptions)

        return eventOutput.eraseToAnyPublisher()
    }
}

extension TableComponentViewModel {
    enum Action {
        case willAppendColumnToTable
        case willAppendRowToTable
        case willApplyTableCellChanges(columnID: UUID, rowID: UUID, cellValue: String)
        case willRemoveRowToTable(rowID: UUID)
        case willApplyTableColumnChanges(columns: [TableComponentColumn])
        case willPresentTableColumnEditingPopupView(columnID: UUID)
    }

    enum Event {
        case didAppendRowToTableView(newRow: TableComponentRow)
        case didRemoveRowToTableView(rowIndex: Int)
        case didAppendColumnToTableView(newColumn: TableComponentColumn)
        case didApplyTableCellValueChanges(cellCoord: TableComponent.Coordinate, cellValue: String)
        case didPresentTableColumnEditPopupView(columns: [TableComponentColumn], columnIndex: Int)
        case didApplyTableColumnChanges(columns: [TableComponentColumn])
    }
}

enum TableComponentViewModelAction {
    case tableComponentAction(TableComponentViewModel.Action)
    case snapshotAction(SnapshotRestorableComponentAction)
}

enum TableComponentViewModelEvent {
    case tableComponentEvent(TableComponentViewModel.Event)
    case snapshotEvent(SnapshotRestorableComponentEvent)
}
