import Combine
import Foundation

protocol TableComponentActionDispatcher {
    func appendColumn(componentID: UUID)
    func appendRow(componentID: UUID)
    func editCellValue(componentID: UUID, columnID: UUID, rowID: UUID, newValue: String)
    func removeRow(componentID: UUID, rowID: UUID)
    func presentColumnEditPopup(componentID: UUID, columnID: UUID)
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

    func editCellValue(componentID: UUID, columnID: UUID, rowID: UUID, newValue: String) {
        subject.send(.willApplyTableCellChanges(componentID, columnID, rowID, newValue))
    }

    func removeRow(componentID: UUID, rowID: UUID) {
        subject.send(.willRemoveRowToTable(componentID, rowID))
    }

    func presentColumnEditPopup(componentID: UUID, columnID: UUID) {
        subject.send(.willPresentTableColumnEditingPopupView(componentID, columnID))
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

    func editCellValue(componentID: UUID, columnID: UUID, rowID: UUID, newValue: String) {
        subject.send(.willApplyTableCellChanges(columnID, rowID, newValue))
    }

    func removeRow(componentID: UUID, rowID: UUID) {
        subject.send(.willRemoveRowToTable(rowID))
    }

    func presentColumnEditPopup(componentID: UUID, columnID: UUID) {
        subject.send(.willPresentTableColumnEditingPopupView(columnID))
    }
}
