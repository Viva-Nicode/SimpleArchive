import Foundation

struct TableComponentRow: Codable, Identifiable {

    var id: UUID
    var cells: [TableComponentCell]
    private(set) var createdDate: Date
    private(set) var modifyDate: Date

    init(columns: [TableComponentColumn]) {
        self.id = UUID()
        self.createdDate = Date()
        self.modifyDate = Date()
        self.cells = columns.map { _ in TableComponentCell(id: UUID(), value: "") }
    }

    mutating func appendCell() -> TableComponentCell {
        let newCell = TableComponentCell(id: UUID(), value: "")
        self.cells.append(newCell)
        return newCell
    }
}
