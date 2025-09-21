import UIKit

final class TableComponentRowView: UIStackView {
    
    private(set) var rowID:UUID

    init(rowID:UUID) {
        self.rowID = rowID
        super.init(frame: .zero)
        commonInit()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func commonInit() {
        axis = .horizontal
        spacing = 8
        alignment = .top
        distribution = .fill
        isLayoutMarginsRelativeArrangement = true
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10)
    }

    @inlinable subscript(index: Int) -> TableComponentCellLabel {
        arrangedSubviews[index] as! TableComponentCellLabel
    }

    func addArrangedSubLabel(with label: TableComponentCellLabel) {
        super.addArrangedSubview(label)
    }

    var cellValues: [String] {
        arrangedSubviews.map { ($0 as! TableComponentCellLabel).cellValue }
    }

    override func addArrangedSubview(_ view: UIView) {
        fatalError("Do not use this. Use addArrangedSubLabel instead.")
    }
}
