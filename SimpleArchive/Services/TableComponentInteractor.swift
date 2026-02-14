import Foundation

final class TableComponentInteractor {
    let pageComponent: TableComponent

    private var memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType
    var trackingSnapshot: TableComponentSnapshot

    init(
        tableComponent: TableComponent,
        memoComponentCoredataReposotory: MemoComponentCoreDataRepositoryType,
    ) {
        self.pageComponent = tableComponent
        self.memoComponentCoredataReposotory = memoComponentCoredataReposotory
        self.trackingSnapshot = TableComponentSnapshot(
            contents: pageComponent.componentContents,
            description: "",
            saveMode: .automatic,
            modificationHistory: [])
    }

    func appendTableComponentRow() -> TableComponentRow {
        let newRow = pageComponent.componentContents.appendNewRow()
        let action: TableComponentAction = .appendRow(row: newRow)

        pageComponent.actions.append(action)
        syncToSnapshot(action)

        return newRow
    }

    func removeTableComponentRow(rowID: UUID) -> Int {
        let removedRowIndex = pageComponent.componentContents.removeRow(rowID)
        let action: TableComponentAction = .removeRow(rowID: rowID)

        pageComponent.actions.append(action)
        syncToSnapshot(action)

        return removedRowIndex
    }

    func appendTableComponentColumn() -> TableComponentColumn {
        let newColumn = pageComponent.componentContents.appendNewColumn(title: "column")
        let action: TableComponentAction = .appendColumn(column: newColumn)

        pageComponent.actions.append(action)
        syncToSnapshot(action)

        return newColumn
    }

    func applyTableCellValue(colID: UUID, rowID: UUID, newCellValue: String) -> TableComponent.Coordinate {
        let indices = pageComponent
            .componentContents
            .editCellValeu(rowID: rowID, colID: colID, newValue: newCellValue)
        let action: TableComponentAction = .editCellValue(rowID: rowID, columnID: colID, value: newCellValue)

        pageComponent.actions.append(action)
        syncToSnapshot(action)

        return indices
    }

    func applyTableColumnChanges(columns: [TableComponentColumn]) {
        pageComponent.componentContents.setColumn(columns: columns)
        let action: TableComponentAction = .editColumn(columns: columns)

        pageComponent.actions.append(action)
        syncToSnapshot(action)
    }

    func presentTableComponentColumnEditPopupView(columnID: UUID) -> Int {
        pageComponent.componentContents.columns.firstIndex(where: { $0.id == columnID })!
    }

    func saveTrackedSnapshotManual(description: String) {
        trackingSnapshot.description = description
        trackingSnapshot.saveMode = .manual
        trackingSnapshot.makingDate = Date()

        memoComponentCoredataReposotory.updateComponentSnapshotInfo(
            componentID: pageComponent.id,
			snapshot: trackingSnapshot)

		pageComponent.insertTrackingSnapshot(trackingSnapshot: trackingSnapshot)
        
		trackingSnapshot = TableComponentSnapshot(
			contents: pageComponent.componentContents,
			description: "",
			saveMode: .automatic,
			modificationHistory: [])
    }

    private func syncToSnapshot(_ action: TableComponentAction) {
        trackingSnapshot.snapshotContents = pageComponent.componentContents
        trackingSnapshot.modificationHistory.append(action)

        memoComponentCoredataReposotory.updateComponentContentChanges(
            modifiedComponent: pageComponent,
            snapshot: trackingSnapshot)
    }
}
