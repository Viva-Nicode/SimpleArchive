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
        subject.send(.appendTableComponentColumn(componentID))
    }

    func appendRow(componentID: UUID) {
        subject.send(.appendTableComponentRow(componentID))
    }

    func editCellValue(componentID: UUID, cellID: UUID, newValue: String) {
        subject.send(.editTableComponentCellValue(componentID, cellID, newValue))
    }

    func removeRow(componentID: UUID, rowID: UUID) {
        subject.send(.removeTableComponentRow(componentID, rowID))
    }

    func presentColumnEditPopup(componentID: UUID, columnIndex: Int) {
        subject.send(.presentTableComponentColumnEditPopupView(componentID, columnIndex))
    }
}

final class SinglePageTableComponentActionDispatcher: TableComponentActionDispatcher {
    private let subject: PassthroughSubject<SingleTablePageInput, Never>

    init(subject: PassthroughSubject<SingleTablePageInput, Never>) {
        self.subject = subject
    }

    func appendColumn(componentID: UUID) {
        subject.send(.willAppendTableComponentColumn)
    }

    func appendRow(componentID: UUID) {
        subject.send(.willAppendTableComponentRow)
    }

    func editCellValue(componentID: UUID, cellID: UUID, newValue: String) {
        subject.send(.willEditTableComponentCellValue(cellID, newValue))
    }

    func removeRow(componentID: UUID, rowID: UUID) {
        subject.send(.willRemoveTableComponentRow(rowID))
    }

    func presentColumnEditPopup(componentID: UUID, columnIndex: Int) {
        subject.send(.presentTableComponentColumnEditPopupView(columnIndex))
    }
}
