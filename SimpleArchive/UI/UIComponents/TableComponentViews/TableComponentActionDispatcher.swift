import Combine
import Foundation

protocol TableComponentActionDispatcherType: PageComponentActionDispatcherType
where EHT == TableComponentViewEventHandler, VMT == TableComponentViewModel {}

final class TableComponentActionDispatcher: TableComponentActionDispatcherType {
    typealias Input = TableComponentViewModelAction
    typealias Output = TableComponentViewModelEvent

    private let dispatcher = PassthroughSubject<Input, Never>()
    private var subscriptions = Set<AnyCancellable>()
    private var viewModel: TableComponentViewModel?

    func bindToViewModel(
        viewModel: TableComponentViewModel,
        UIEventHandler: TableComponentViewEventHandler
    ) {
        self.viewModel = viewModel
        self.viewModel?
            .bindToView(input: dispatcher.eraseToAnyPublisher())
            .sink { UIEventHandler.UIupdateEventHandler($0) }
            .store(in: &subscriptions)
    }

    func appendNewRow() {
        dispatcher.send(.tableComponentAction(.willAppendRowToTable))
    }

    func appendNewColumn() {
        dispatcher.send(.tableComponentAction(.willAppendColumnToTable))
    }

    func applyColumnChanges(editedColumns: [TableComponentColumn]) {
        dispatcher.send(.tableComponentAction(.willApplyTableColumnChanges(columns: editedColumns)))
    }

    func applyCellValueChange(colID: UUID, rowID: UUID, cellValue: String) {
        dispatcher.send(
            .tableComponentAction(.willApplyTableCellChanges(columnID: colID, rowID: rowID, cellValue: cellValue)))
    }

    func removeRow(rowID: UUID) {
        dispatcher.send(.tableComponentAction(.willRemoveRowToTable(rowID: rowID)))
    }

    func presentColumnEditPopup(columnID: UUID) {
        dispatcher.send(.tableComponentAction(.willPresentTableColumnEditingPopupView(columnID: columnID)))
    }

    func captureComponentManual(description: String) {
        dispatcher.send(.snapshotAction(.willManualCapturePageComponent(description: description)))
    }

    func navigateComponentSnapshotView() {
        dispatcher.send(.snapshotAction(.willNavigateComponentSnapshotView))
    }

    func clearSubscriptions() {
        subscriptions.removeAll()
        viewModel?.clearSubscriptions()
        viewModel = nil
    }
}
