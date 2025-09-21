import UIKit

final class TableComponentCellLabel: UILabel {

    private(set) var cellValue: String

    init(cellValue: String) {
        self.cellValue = cellValue
        super.init(frame: .zero)
        setLabelText(cellValue)
        textAlignment = .left
        numberOfLines = 3
        isUserInteractionEnabled = true
    }

    func setLabelText(_ newCellValue: String) {
        self.cellValue = newCellValue
        textColor = cellValue.isEmpty ? .systemGray2 : .label
        text = cellValue.isEmpty ? "empty" : cellValue
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
