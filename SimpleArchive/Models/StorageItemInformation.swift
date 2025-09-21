import Foundation

protocol StorageItemInformationType {
    var id: UUID { get set }
    var name: String { get set }
    var filePath: String { get set }
    var created: Date { get set }
}

struct DirectoryInformation: StorageItemInformationType {
    var id: UUID
    var name: String
    var filePath: String
    var created: Date

    var containedDirectoryCount: Int
    var containedPageCount: Int
}

struct PageInformation: StorageItemInformationType {
    var id: UUID
    var name: String
    var filePath: String
    var created: Date

    var containedComponentCount: Int
}
