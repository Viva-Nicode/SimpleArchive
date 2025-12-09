import UIKit

class TableComponentCellLabel: UILabel {

    private(set) var cellValue: String

    init(cellValue: String) {
        self.cellValue = cellValue
        super.init(frame: .zero)
        setLabelText(cellValue)
        textAlignment = .left
        numberOfLines = 3
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLabelText(_ newCellValue: String) {
        self.cellValue = newCellValue
        textColor = cellValue.isEmpty ? .systemGray2 : .label
        text = cellValue.isEmpty ? "empty" : cellValue
    }
}

class TableComponentColumnLabel: TableComponentCellLabel {
    private(set) var columnID: UUID

    init(columnID: UUID, cellValue: String) {
        self.columnID = columnID
        super.init(cellValue: cellValue)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
