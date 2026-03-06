import Combine
import UIKit

class TableComponentViewEventHandler: ComponentViewEventHandlerType {
    private var contentsView: TableComponentContentView
    private var restorePublisherSubscription: AnyCancellable?
    private var applyColumnChangesSubscription: AnyCancellable?

    init(contentsView: TableComponentContentView) {
        self.contentsView = contentsView
    }

    func UIupdateEventHandler(_ event: TableComponentViewModelEvent) {
        switch event {
            case .tableComponentEvent(let event):
                switch event {
                    case .didAppendRowToTableView(let newRow):
                        contentsView.appendEmptyRowToStackView(rowID: newRow.id)

                    case .didRemoveRowToTableView(let rowIndex):
                        contentsView.removeTableComponentRowView(idx: rowIndex)

                    case .didAppendColumnToTableView(let newColumn):
                        contentsView.appendEmptyColumnToStackView(column: newColumn)

                    case .didApplyTableCellValueChanges(let cellCoord, let cellValue):
                        contentsView.updateUILabelText(
                            rowIndex: cellCoord.rowIndex,
                            cellIndex: cellCoord.columnIndex,
                            with: cellValue)

                    case .didPresentTableColumnEditPopupView(let columns, let columnIndex):
                        let tableComponentColumnEditPopupView = TableComponentColumnEditPopupView(
                            columns: columns,
                            tappedColumnIndex: columnIndex)

                        applyColumnChangesSubscription = tableComponentColumnEditPopupView.confirmButtonPublisher
                            .sink { [weak self] colums in
                                guard let self else { return }
                                contentsView.actionDispatcher?.applyColumnChanges(editedColumns: colums)
                                applyColumnChangesSubscription = nil
                            }
                        tableComponentColumnEditPopupView.show()

                    case .didApplyTableColumnChanges(let columns):
                        contentsView.applyColumns(columns: columns)
                }

            case .snapshotEvent(let snapshotRestorableComponentEvent):
                switch snapshotRestorableComponentEvent {
                    case .didManualCapturePageComponent:
                        guard let host = contentsView.parentViewController as? ManualCaptureHost else { return }
                        host.completeManualCapture()

                    case .didNavigateComponentSnapshotView(let componentSnapshotViewModel):
                        guard let vc = contentsView.parentViewController else { return }
                        let snapshotView = ComponentSnapshotViewController(viewModel: componentSnapshotViewModel)

                        restorePublisherSubscription = snapshotView.hasRestorePublisher
                            .sink { [weak self] contents in
                                guard let self else { return }
                                if let loadableSuperView: ContentsReloadableView = contentsView.findSuperViewMatched() {
                                    loadableSuperView.reloadUsingRestoredContents(contents: contents)
                                }
                                restorePublisherSubscription = nil
                            }
                        vc.navigationController?.pushViewController(snapshotView, animated: true)
                }
        }
    }
}
