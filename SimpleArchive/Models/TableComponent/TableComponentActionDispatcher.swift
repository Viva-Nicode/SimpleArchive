import Combine
import Foundation

protocol TableComponentActionDispatcher {
    func appendColumn(componentID: UUID)
    func appendRow(componentID: UUID)
    func editCellValue(componentID: UUID, cellID: UUID, newValue: String)
    func removeRow(componentID: UUID, rowID: UUID)
    func presentColumnEditPopup(componentID: UUID, columnIndex: Int)
}

final class MemoPageTableComponentActionDispatcher: TableComponentActionDispatcher {
    private let subject: PassthroughSubject<MemoPageViewInput, Never>

    init(subject: PassthroughSubject<MemoPageViewInput, Never>) {
        self.subject = subject
    }

    func appendColumn(componentID: UUID) {
        subject.send(.willAppendColumnToTable(componentID))
    }

    func appendRow(componentID: UUID) {
        subject.send(.willAppendRowToTable(componentID))
    }

    func editCellValue(componentID: UUID, cellID: UUID, newValue: String) {
        subject.send(.willApplyTableCellChanges(componentID, cellID, newValue))
    }

    func removeRow(componentID: UUID, rowID: UUID) {
        subject.send(.willRemoveRowToTable(componentID, rowID))
    }

    func presentColumnEditPopup(componentID: UUID, columnIndex: Int) {
        subject.send(.willPresentTableColumnEditingPopupView(componentID, columnIndex))
    }
}

final class SinglePageTableComponentActionDispatcher: TableComponentActionDispatcher {
    private let subject: PassthroughSubject<SingleTablePageInput, Never>

    init(subject: PassthroughSubject<SingleTablePageInput, Never>) {
        self.subject = subject
    }

    func appendColumn(componentID: UUID) {
        subject.send(.willAppendColumnToTable)
    }

    func appendRow(componentID: UUID) {
        subject.send(.willAppendRowToTable)
    }

    func editCellValue(componentID: UUID, cellID: UUID, newValue: String) {
        subject.send(.willApplyTableCellChanges(cellID, newValue))
    }

    func removeRow(componentID: UUID, rowID: UUID) {
        subject.send(.willRemoveRowToTable(rowID))
    }

    func presentColumnEditPopup(componentID: UUID, columnIndex: Int) {
        subject.send(.willPresentTableColumnEditingPopupView(columnIndex))
    }
}
