import UIKit

final class TableComponentColumnLabel: UILabel {

    private(set) var columnID: UUID

    init(columnID: UUID) {
        self.columnID = columnID
        super.init(frame: .zero)
        textAlignment = .left
        numberOfLines = 3
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
