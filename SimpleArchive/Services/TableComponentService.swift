import Foundation

final class TableComponentService {

    func appendTableComponentRow(tableComponent: TableComponent) -> TableComponentRow {
        let newRow = tableComponent.componentContents.appendNewRow()
        tableComponent.setCaptureState(to: .needsCapture)
        tableComponent.actions.append(.appendRow(row: newRow))
        return newRow
    }

    func removeTableComponentRow(tableComponent: TableComponent, rowID: UUID) -> Int {
        let removedRowIndex = tableComponent.componentContents.removeRow(rowID)
        tableComponent.setCaptureState(to: .needsCapture)
        tableComponent.actions.append(.removeRow(rowID: rowID))
        return removedRowIndex
    }

    func appendTableComponentColumn(tableComponent: TableComponent) -> TableComponentColumn {
        let newColumn = tableComponent.componentContents.appendNewColumn(title: "column")
        tableComponent.setCaptureState(to: .needsCapture)
        tableComponent.actions.append(.appendColumn(column: newColumn))
        return newColumn
    }

    func applyTableCellValue(tableComponent: TableComponent, colID: UUID, rowID: UUID, newCellValue: String) -> (
        rowIndex: Int, columnIndex: Int
    ) {
        let indices = tableComponent
            .componentContents
            .editCellValeu(rowID: rowID, colID: colID, newValue: newCellValue)
        tableComponent.setCaptureState(to: .needsCapture)
        tableComponent.actions.append(.editCellValue(rowID: rowID, columnID: colID, value: newCellValue))
        return indices
    }

    func presentTableComponentColumnEditPopupView(tableComponent: TableComponent, columnID: UUID) -> Int {
        tableComponent.componentContents.columns.firstIndex(where: { $0.id == columnID })!
    }

    func applyTableColumnChanges(tableComponent: TableComponent, columns: [TableComponentColumn]) {
        tableComponent.componentContents.setColumn(columns: columns)
        tableComponent.setCaptureState(to: .needsCapture)
        tableComponent.actions.append(.editColumn(columns: columns))
    }
}
