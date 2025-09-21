import Foundation

struct TableComponentCell: Codable {
    private(set) var id: UUID
    private(set) var value: String

    mutating func setValue(value: String) {
        self.value = value
    }
}
