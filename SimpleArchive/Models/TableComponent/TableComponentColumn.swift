import Foundation
import UIKit

struct TableComponentColumn: Codable, Identifiable {

    var id: UUID
    private(set) var columnTitle: String

    init(
        id: UUID = UUID(),
        columnTitle: String,
    ) {
        self.id = id
        self.columnTitle = columnTitle
    }

    mutating func setColumnTitle(_ columnTitle: String) {
        self.columnTitle = columnTitle
    }
}
